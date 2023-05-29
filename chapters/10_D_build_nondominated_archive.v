// BUILD NONDOMINATED ARCHIVE
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################


reg                 [5: 0]                              updater_stage;

localparam          [5: 0]                              updater_stage_disactive         = 0;
localparam          [5: 0]                              updater_stage_controller        = 1;
localparam          [5: 0]                              updater_stage_worker            = 2;


reg                 [laggers_len - 1 : 0]               lagger_D5_1;
reg                 [laggers_len - 1 : 0]               lagger_D5_2;

reg                 [q_full - 1 : 0]                    block_counter_D5;
reg                 [q_full - 1 : 0]                    sub_block_counter_D5;



reg                 [laggers_len - 1 : 0]               lagger_D7;
reg                 [q_full - 1 : 0]                    counter_D7;

// ss_sum Sorter by Counts
reg                 [address_len - 1 : 0]               ss_sum_sorter_counter;
reg                 [address_len - 1 : 0]               ss_sum_sorter_read_lag_counter;
reg                 [address_len - 1 : 0]               ss_sum_sorter_write_lag_counter;

reg                 [q_full - 1 : 0]                    ss_sum_sorter_var_idx_1;
reg                 [q_full - 1 : 0]                    ss_sum_sorter_var_idx_2;

reg                 [q_full - 1 : 0]                    ss_sum_sorter_var_ss_sum_1;
reg                 [q_full - 1 : 0]                    ss_sum_sorter_var_ss_sum_2;

reg                                                     ss_sum_sorter_bump_flag;
reg                 [ 31 : 0 ]                          ss_sum_sorter_total_counter;

reg                                                     ss_sum_sorter_stage;
localparam                                              ss_sum_sorter_stage_looping                 = 0;
localparam                                              ss_sum_sorter_stage_swapping                = 1;



reg                 [crop_count * crop_count - 1 : 0]   nondominated_blocks;
reg                 [crop_count * crop_count - 1 : 0]   nondominated_blocks_zero_mask;
reg                 [crop_count * crop_count - 1 : 0]   most_significant_block_idxs;



reg                 [q_full - 1 : 0]                    candidate_block_ss_sum;
reg                 [q_full - 1 : 0]                    candidate_block_var_sum;
reg                 [1 : 0]                             dominion_status_results;

reg                 [q_full - 1 : 0]                    none_dominated_blocks_count;

reg                 [q_full - 1 : 0]                    total_blocks_needed;
reg                 [q_full - 1 : 0]                    dominated_blocks_needed;




// Counting the Blocks
// D5
always @(negedge clk) begin

    if (updater_stage == updater_stage_controller) begin

            lagger_D5_1 = lagger_D5_1 + 1;

            if (lagger_D5_1 == 2)  begin
                ss_sum_ram_read_addr = block_counter_D5;
                var_sum_ram_read_addr = block_counter_D5;

            end else if (lagger_D5_1 == 5) begin
                candidate_block_ss_sum  =  ss_sum_ram_read_data;
                candidate_block_var_sum = var_sum_ram_read_data;

            end else if (lagger_D5_1 == 6) begin
                    
                
                // $display("%b", candidate_block_ss_sum);

                if (block_counter_D5 < 64) begin


                    sub_block_counter_D5 = 0;

                    updater_stage = updater_stage_worker;

                    lagger_D5_1 = 0;

                end else begin
                    $display("D5: fnished calculating nondominated_blocks bus");
                    $display("D5: nondominated_blocks: %b", nondominated_blocks);
                    $display("D5: going ahead to sort vv_sum_ram...");
                    
                    updater_stage = updater_stage_disactive;
                    build_arg_sort_of_ss_sum_ram_flag = 1;

                end

                lagger_D5_1 = 0;
            end 
        end
end



// Doing work on each Block to figure out the non-dominated blocks
//D5
always @(negedge clk) begin
    if (updater_stage == updater_stage_worker) begin

        lagger_D5_2 = lagger_D5_2 + 1;

        // if(lagger_D5_2 == 2) begin
        //     $display("dealing with candidate at block_counter_D5: %d", block_counter_D5);

        if(lagger_D5_2 == 3) begin
            // pick next block to compare with the candidate

            ss_sum_ram_read_addr    = sub_block_counter_D5;
            var_sum_ram_read_addr   = sub_block_counter_D5;

        end else if(lagger_D5_2 == 4) begin
            dominion_status_results = nt_aeb.dominion_status(
                candidate_block_ss_sum,
                candidate_block_var_sum,
                ss_sum_ram_read_data,
                var_sum_ram_read_data
            ) ;

            // $display("(%b,%b) (%b,%b)", 
            // candidate_block_ss_sum,
            // candidate_block_var_sum,
            // ss_sum_ram_read_data,
            // var_sum_ram_read_data
            // );

        end else if(lagger_D5_2 == 5) begin
            // $display("candidate block:%d\tblock:%d\tdominion_status_results:%d",
            // block_counter_D5,
            // sub_block_counter_D5,
            // dominion_status_results);


            if (dominion_status_results == 2) begin

                // $display("%b", nondominated_blocks);

                nondominated_blocks_zero_mask = ((2 << (crop_count * crop_count + 1)) - 1) - (1 << block_counter_D5);
                
                // $display("%d, %b", block_counter_D5, nondominated_blocks_zero_mask);

                nondominated_blocks = nondominated_blocks & nondominated_blocks_zero_mask;

                // $display("%b", nondominated_blocks);
                // $display("-------------------");
                none_dominated_blocks_count = none_dominated_blocks_count - 1;
                updater_stage = updater_stage_controller;
                block_counter_D5 = block_counter_D5 + 1;
                // 0000000001001000001000000000000000000000000100000000000000000000
            end

        end else if(lagger_D5_2 == 6) begin


            if (sub_block_counter_D5 < (crop_count * crop_count - 1)) begin
                sub_block_counter_D5 = sub_block_counter_D5 + 1;

            end else begin
                updater_stage = updater_stage_controller;
                block_counter_D5 = block_counter_D5 + 1;


            end

            lagger_D5_2 = 0;

        end
    end
end



// sorting the var_sum array to get the arg sort of the
// D6
always @(negedge clk) begin
    
    if (build_arg_sort_of_ss_sum_ram_flag == 1) begin

        ss_sum_sorter_total_counter = ss_sum_sorter_total_counter + 1;

        if (ss_sum_sorter_stage == ss_sum_sorter_stage_looping) begin
            ss_sum_sorter_read_lag_counter  = ss_sum_sorter_read_lag_counter + 1;

            // $display("ss_sum_sorter_read_lag_counter: %d", ss_sum_sorter_read_lag_counter);

            if (ss_sum_sorter_read_lag_counter == 1) begin
                ss_sum_ram_read_addr            = ss_sum_sorter_counter;
                ss_sum_arg_sort_ram_read_addr   = ss_sum_sorter_counter;

            end else if (ss_sum_sorter_read_lag_counter == 2) begin
                ss_sum_sorter_var_ss_sum_1      = ss_sum_ram_read_data;
                ss_sum_sorter_var_idx_1         = ss_sum_arg_sort_ram_read_data;

            end else if (ss_sum_sorter_read_lag_counter == 3) begin
                ss_sum_ram_read_addr            = ss_sum_sorter_counter + 1;    
                ss_sum_arg_sort_ram_read_addr   = ss_sum_sorter_counter + 1;

            end else if (ss_sum_sorter_read_lag_counter == 4) begin
                ss_sum_sorter_var_ss_sum_2      = ss_sum_ram_read_data;
                ss_sum_sorter_var_idx_2         = ss_sum_arg_sort_ram_read_data;

            end else if (ss_sum_sorter_read_lag_counter == 5) begin

                // $display("counter:  [%d, %d], f1: %b     f2: %b", 
                // ss_sum_sorter_counter,
                // ss_sum_sorter_counter + 1,
                // ss_sum_sorter_var_idx_1,
                // ss_sum_sorter_var_idx_2);


                if (ss_sum_sorter_var_ss_sum_1 < ss_sum_sorter_var_ss_sum_2) begin
                    // $display("bump");
                    ss_sum_sorter_bump_flag = 1;
                    ss_sum_sorter_stage = ss_sum_sorter_stage_swapping;
                end 

                ss_sum_sorter_read_lag_counter = 0;

                if (ss_sum_sorter_counter < (crop_count * crop_count - 2)) begin
                    ss_sum_sorter_counter = ss_sum_sorter_counter + 1;

                end else begin

                    ss_sum_sorter_counter = 0;

                    if (ss_sum_sorter_bump_flag == 0) begin
                        build_arg_sort_of_ss_sum_ram_flag = 0;

                        $display("D6: ss_sum sorting done in %d clocks", ss_sum_sorter_total_counter);

                        ss_sum_sorter_stage = ss_sum_sorter_stage_looping;
                        ss_sum_sorter_total_counter = 0;
                        ss_sum_sorter_counter = 0;
                        ss_sum_sorter_read_lag_counter = 0;
                        ss_sum_sorter_write_lag_counter = 0;
                        ss_sum_sorter_var_idx_1 = 0;
                        ss_sum_sorter_var_idx_2 = 0;


                        // print_arg_sort_of_ss_sum_ram_flag = 1;

                        /*
                            starting to get the needed most significant blocks
                        */
                        total_blocks_needed             = top_blocks_count;

                        if (total_blocks_needed > none_dominated_blocks_count) begin
                            dominated_blocks_needed = total_blocks_needed - none_dominated_blocks_count;
                        end else begin
                            dominated_blocks_needed = none_dominated_blocks_count - total_blocks_needed;
                        end

                        $display("D6: total_blocks_needed: %d, dominated_blocks_needed: %d",
                         total_blocks_needed, 
                         dominated_blocks_needed);

                        $display("D6: going ahead with get_most_significant_block_idxs_flag ..");
                        get_most_significant_block_idxs_flag = 1;




                    end

                    ss_sum_sorter_bump_flag = 0;

                end

            end

        end else if (ss_sum_sorter_stage== ss_sum_sorter_stage_swapping) begin

            ss_sum_sorter_write_lag_counter = ss_sum_sorter_write_lag_counter + 1;

            if (ss_sum_sorter_write_lag_counter == 1) begin
                if (ss_sum_sorter_counter == 0) begin
                    ss_sum_arg_sort_ram_write_addr  = crop_count * crop_count - 2;
                    ss_sum_ram_write_addr           = crop_count * crop_count - 2;
                end else begin
                    ss_sum_arg_sort_ram_write_addr  = ss_sum_sorter_counter - 1;
                    ss_sum_ram_write_addr           = ss_sum_sorter_counter - 1;

                end

            end else if (ss_sum_sorter_write_lag_counter == 2) begin
                ss_sum_ram_write_data              = ss_sum_sorter_var_ss_sum_2;                
                ss_sum_arg_sort_ram_write_data     = ss_sum_sorter_var_idx_2;                


            end else if (ss_sum_sorter_write_lag_counter == 3) begin
                ss_sum_ram_write_enable             =  1;
                ss_sum_arg_sort_ram_write_enable    = 1;

            end else if (ss_sum_sorter_write_lag_counter == 4) begin
                ss_sum_ram_write_enable             = 0;
                ss_sum_arg_sort_ram_write_enable    = 0;

            end else if (ss_sum_sorter_write_lag_counter == 5) begin
                if (ss_sum_sorter_counter == 0) begin
                    ss_sum_arg_sort_ram_write_addr      = crop_count * crop_count - 1;
                    ss_sum_ram_write_addr               = crop_count * crop_count - 1;

                end else begin
                    ss_sum_arg_sort_ram_write_addr      = ss_sum_sorter_counter;
                    ss_sum_ram_write_addr               = ss_sum_sorter_counter;

                end

            end else if (ss_sum_sorter_write_lag_counter == 6) begin
                ss_sum_ram_write_data              = ss_sum_sorter_var_ss_sum_1;                
                ss_sum_arg_sort_ram_write_data     = ss_sum_sorter_var_idx_1;



            end else if (ss_sum_sorter_write_lag_counter == 7) begin
                ss_sum_ram_write_enable             =  1;
                ss_sum_arg_sort_ram_write_enable    = 1;


            end else if (ss_sum_sorter_write_lag_counter == 8) begin
                ss_sum_ram_write_enable             = 0;
                ss_sum_arg_sort_ram_write_enable    = 0;


            end else if (ss_sum_sorter_write_lag_counter == 9) begin
                ss_sum_sorter_write_lag_counter = 0;
                ss_sum_sorter_stage = ss_sum_sorter_stage_looping;
            end

        end
    end

end


/*
    ALG 2)
    dominated_needed = max(0 , top_blocks_count - non_dominated_block_counts)
    total_needed = top_blocks_count
    
    for i:
        if (total_needed > 0):
            if (non dominated):
                pick i
                total_needed -= 1;
                
            else (dominated)
                if (dominated_needed > 0)
                    pick i
                    dominated_needed -= 1
                    
        if total_needed == 0:
            break
            

*/
//D7
always @(negedge clk) begin
    if(get_most_significant_block_idxs_flag == 1) begin

        lagger_D7 = lagger_D7 + 1;

        if (lagger_D7 == 1) begin
            ss_sum_arg_sort_ram_read_addr       = counter_D7;
            ss_sum_ram_read_addr                = counter_D7;
            
        end else if (lagger_D7 == 2) begin
            // 
            if (total_blocks_needed > 0) begin
                

                if (nondominated_blocks[ss_sum_arg_sort_ram_read_data] == 1'b1) begin
                    
                    // $display("i=%d,  $b , %b , check: %d >? %d",
                    // counter_D7,
                    // nondominated_blocks & (64'd1 << counter_D7),
                    // 64'd1 << (counter_D7 - 1),
                    // nondominated_blocks & (64'd1 << counter_D7),
                    // 64'd1 << (counter_D7 - 1),
                    // );

                    most_significant_block_idxs = most_significant_block_idxs | (64'd1 << ss_sum_arg_sort_ram_read_data);

                    total_blocks_needed = total_blocks_needed - 1;

                end else begin
                    
                    if (dominated_blocks_needed > 0) begin
                        
                        most_significant_block_idxs = most_significant_block_idxs | (64'd1 << ss_sum_arg_sort_ram_read_data);

                        dominated_blocks_needed = dominated_blocks_needed - 1;
                        total_blocks_needed = total_blocks_needed - 1;

                    end

                end 

            end


        end else if (lagger_D7 == 3) begin
            // $display("counter_D7: %d, (%b < %b), read_data:%d", counter_D7, counter_D7, 24'd255, hue_hist_full_frame_mem_read_data);

            if ((counter_D7 == ((crop_count * crop_count) - 1)) || (total_blocks_needed == 0)) begin

                counter_D7 = 0;
                get_most_significant_block_idxs_flag = 0;

                $display("D7:most_significant_block_idxs: %b", most_significant_block_idxs);
                // most_significant_block_idxs = 64'b1111111111111111111110100111000000110000000100000011000000000000; // regular
                // most_significant_block_idxs =    64'b0000000000000000000000000000000000000000000100000010000000000000; // 13 and 20
                // most_significant_block_idxs =    64'b0000000000000000000000000000000000000000000000000011000000000000; // 12 and 13
                // most_significant_block_idxs =    64'b0000000000000000000000000000000000000000000000000010100000000000; // 11 and 13
                // most_significant_block_idxs =    64'b0000000000000000000000000000000000000000000000000000100000000000; // 11

                most_significant_block_idxs_populated_milestone = 1;
                // build_frame_ram_with_hue_included_mask_flag = 1; run in series

                
            end else begin
            
                counter_D7 = counter_D7 + 1;
            
            end

            lagger_D7 = 0;

        end 

    end 
end





reg                 [q_full - 1 : 0]                    pixel_counter_D6            = 0;
reg                 [q_full - 1 : 0]                    pixel_reader_lag_counter_D6    = 0;

// print_arg_sort_of_ss_sum_ram_flag
always @(negedge clk) begin
    if (print_arg_sort_of_ss_sum_ram_flag == 1) begin
        pixel_reader_lag_counter_D6 = pixel_reader_lag_counter_D6 + 1;

        if (pixel_reader_lag_counter_D6 == 1) begin
            ss_sum_arg_sort_ram_read_addr       = pixel_counter_D6;
            ss_sum_ram_read_addr                = pixel_counter_D6;
            
        end else if (pixel_reader_lag_counter_D6 == 2) begin
            // $fdisplay(output_file_hue_hist_blocks, hue_hist_blocks_mem_read_data);  // row integer values of the histogram
            // $fdisplay(output_file_hue_hist_blocks, SF * hue_hist_blocks_mem_read_data);  // for float value of um - just for plotting and comparing with python
            // $fdisplayb(output_file_hue_hist_blocks, hue_hist_blocks_mem_read_data);  // to dump actual binary value of um
            $display("%d: %f", ss_sum_arg_sort_ram_read_data, SF * ss_sum_ram_read_data);

        end else if (pixel_reader_lag_counter_D6 == 3) begin
            // $display("pixel_counter_D6: %d, (%b < %b), read_data:%d", pixel_counter_D6, pixel_counter_D6, 24'd255, hue_hist_full_frame_mem_read_data);

            if (pixel_counter_D6 < (crop_count * crop_count) - 1) begin
                // $display("pixel_counter_D6 + 1");

                pixel_counter_D6 = pixel_counter_D6 + 1;

            end else begin
                pixel_counter_D6 = 0;
                print_arg_sort_of_ss_sum_ram_flag = 0;
                // $fclose(output_file_hue_hist_blocks);  
            end

            pixel_reader_lag_counter_D6 = 0;

        end 
    end
end
