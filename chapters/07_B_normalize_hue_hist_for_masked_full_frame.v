reg                 [q_full - 1 : 0]                    counter_B0;
reg                 [laggers_len - 1 : 0]               lagger_B0;
reg                 [laggers_len - 1 : 0]               hue_B0;
reg                 [laggers_len - 1 : 0]               hue_B3;


// Hue Histogram Sorter by Counts
reg                 [address_len - 1 : 0]               hue_hist_sorter_counter                     ;
reg                 [address_len - 1 : 0]               hue_hist_sorter_read_lag_counter            ;
reg                 [address_len - 1 : 0]               hue_hist_sorter_write_lag_counter           ;

reg                 [q_full - 1 : 0]                    hue_hist_sorter_temp_var_count_1           ;
reg                 [q_full - 1 : 0]                    hue_hist_sorter_temp_var_count_2           ;
reg                 [q_full - 1 : 0 ]                   hue_hist_sorter_temp_var_hue_value_1       ;
reg                 [q_full - 1 : 0]                    hue_hist_sorter_temp_var_hue_value_2       ;


// Hue Histogram Sorter by Counts Stages
reg                                                     hue_hist_sorter_stage                       ;
localparam                                              hue_hist_sorter_stage_looping               = 0;
localparam                                              hue_hist_sorter_stage_swapping              = 1;

reg                                                     hue_hist_sorter_bump_flag                   ;
reg                 [ 31 : 0 ]                          hue_hist_sorter_total_counter               ;

reg                                                     hue_hist_sorter_sort_hue;


reg                 [full_hue_range - 1 : 0]            excluded_hues;



reg                 [q_full - 1 : 0]                    counter_B2;
reg                 [laggers_len - 1 : 0]               lagger_B2;

reg                 [q_full - 1 : 0]                    hue_hist_full_frame_sum_B2                        ;   
reg                 [q_full - 1 : 0]                    sum_of_remaining_pixels_B3                        ;   
reg                 [q_full - 1 : 0]                    hue_hist_full_frame_norm_sum_B4                   ;   

reg                 [q_full - 1 : 0]                    counter_B3;
reg                 [laggers_len - 1 : 0]               lagger_B3;

reg                 [q_full - 1 : 0]                    counter_B4;
reg                 [laggers_len - 1 : 0]               lagger_B4;









// Division B4
reg                                                     division_B4_start=0;
wire                                                    division_B4_busy;
wire                                                    division_B4_valid;
wire                                                    division_B4_dbz;
wire                                                    division_B4_ovf;
reg                         [q_full - 1 : 0]            division_B4_x;
reg                         [q_full - 1 : 0]            division_B4_y;
wire                        [q_full - 1 : 0]            division_B4_q;
wire                        [q_full - 1 : 0]            division_B4_r;

division #(
    .width(q_full),
    .floating_bits(q_half)
    ) division_B4 (
        .clk(   clk),
        .start( division_B4_start),
        .busy(  division_B4_busy),
        .valid( division_B4_valid),
        .dbz(   division_B4_dbz),
        .ovf(   division_B4_ovf),
        .x(     division_B4_x),
        .y(     division_B4_y),
        .q(     division_B4_q),
        .r(     division_B4_r)
    );


always @(negedge division_B4_busy) begin
    normalize_hue_hist_for_masked_full_frame_flag = 1;


    if ((division_B4_valid == 0) || (division_B4_ovf == 1)) begin
        $display("!!! diviosn error at B4");

        $display("%d:\t%f \t/ \t%f \t= \t(%f)\t\t(V=%b) (DBZ=%b) (OVF=%b)",
        $time, division_B4_x*SF, division_B4_y*SF, division_B4_q*SF, 
        division_B4_valid, division_B4_dbz, division_B4_ovf);

        $display("%d:\t%b \t/ \t%b \t= \t(%b)\t\t(V=%b) (DBZ=%b) (OVF=%b)",
        $time, division_B4_x, division_B4_y, division_B4_q, 
        division_B4_valid, division_B4_dbz, division_B4_ovf);
    end

end










// B0
// calculate_hue_histogram_flag
always @(negedge clk) begin
    if (calculate_hue_histogram_flag == 1) begin
        
        lagger_B0 = lagger_B0 + 1;

        if (lagger_B0 == 1) begin
            source_frame_hsv_mem_read_addr = counter_B0;

        end else if (lagger_B0 == 2) begin
            hue_B0 = (source_frame_hsv_mem_read_data & full_h_mask) >> 16;
            $fdisplay(output_file_obtained_hue, hue_B0);

        end else if (lagger_B0 == 3) begin
            hue_hist_full_frame_mem_read_addr = hue_B0;
            // $display("lagger_B0:%d,hue_hist_full_frame_mem_read_addr: %b, %d", lagger_B0, hue_hist_full_frame_mem_read_addr, hue_hist_full_frame_mem_read_addr);

        end else if (lagger_B0 == 4) begin
            hue_hist_full_frame_mem_write_addr = hue_B0;
            hue_hist_full_frame_mem_read_enable = 0;
            // $display("lagger_B0:%d,hue_hist_full_frame_mem_write_addr: %b, %d", lagger_B0, hue_hist_full_frame_mem_write_addr, hue_hist_full_frame_mem_write_addr);

        end else if (lagger_B0 == 5) begin
            hue_hist_full_frame_mem_write_data = hue_hist_full_frame_mem_read_data + 1;
            // $display("lagger_B0:%d,hue_hist_full_frame_mem_write_data: %b, %d", lagger_B0, hue_hist_full_frame_mem_write_data, hue_hist_full_frame_mem_write_data);

        end else if (lagger_B0 == 6) begin
            hue_hist_full_frame_mem_write_enable = 1;

        end else if (lagger_B0 == 7) begin
            hue_hist_full_frame_mem_write_enable = 0;


        end else if (lagger_B0 == 8) begin
            hue_hist_full_frame_mem_read_enable = 1;

            if (counter_B0 < (width * height - 1)) begin
                counter_B0 = counter_B0 + 1;

            end else begin
                counter_B0 = 0;

                $display("B0: finished calculate_hue_histogram_flag");
                calculate_hue_histogram_flag = 0;

                $display("starting to dump_hue_hist_full_frame_mem_to_file_flag");  
                dump_hue_hist_full_frame_mem_to_file_flag = 1; // output_file_hue_hist_full_frame.txt

                $fclose(output_file_obtained_hue);

                hue_hist_sorter_sort_hue =0;

            end

            lagger_B0 = 0;

        end 

    end
end






// B1
// Full Frame Hue Histogram Sorter By Counts
always @(negedge clk) begin

    if (sort_hue_hist_flag == 1) begin

        hue_hist_sorter_total_counter = hue_hist_sorter_total_counter + 1;

        if (hue_hist_sorter_stage == hue_hist_sorter_stage_looping) begin
            hue_hist_sorter_read_lag_counter = hue_hist_sorter_read_lag_counter + 1;
            // $display("hue_hist_sorter_read_lag_counter: %d", hue_hist_sorter_read_lag_counter);

            if (hue_hist_sorter_read_lag_counter == 1) begin
                hue_hist_full_frame_mem_read_addr      = hue_hist_sorter_counter;
                hue_values_full_frame_mem_read_addr    = hue_hist_sorter_counter;

            end else if (hue_hist_sorter_read_lag_counter == 2) begin
                hue_hist_sorter_temp_var_count_1       = hue_hist_full_frame_mem_read_data;
                hue_hist_sorter_temp_var_hue_value_1    = hue_values_full_frame_mem_read_data;
                // $display("hue_hist_full_frame_mem_read_addr:%d, hue_hist_full_frame_mem_read_data: %d", hue_hist_full_frame_mem_read_addr, hue_hist_full_frame_mem_read_data);

            end else if (hue_hist_sorter_read_lag_counter == 3) begin
                hue_hist_full_frame_mem_read_addr      = hue_hist_sorter_counter + 1;    
                hue_values_full_frame_mem_read_addr    = hue_hist_sorter_counter + 1;    

            end else if (hue_hist_sorter_read_lag_counter == 4) begin
                hue_hist_sorter_temp_var_count_2       = hue_hist_full_frame_mem_read_data;
                hue_hist_sorter_temp_var_hue_value_2    = hue_values_full_frame_mem_read_data;

            end else if (hue_hist_sorter_read_lag_counter == 5) begin
                // $display("counter:  [%d, %d], f1: %f     f2: %f", hue_hist_sorter_counter,hue_hist_sorter_counter + 1,SF_32 * nt.f_bitstream_to_f_pair_item(hue_hist_sorter_temp_var_count_1, 0),SF_32 * nt.f_bitstream_to_f_pair_item(hue_hist_sorter_temp_var_count_2, 0));

                if (hue_hist_sorter_sort_hue == 0) begin
                    if (hue_hist_sorter_temp_var_count_1 < hue_hist_sorter_temp_var_count_2) begin
                        // $display("bump");
                        hue_hist_sorter_bump_flag = 1;
                        hue_hist_sorter_stage = hue_hist_sorter_stage_swapping;
                    end 
                end else if (hue_hist_sorter_sort_hue == 1) begin
                    if (hue_hist_sorter_temp_var_hue_value_1 > hue_hist_sorter_temp_var_hue_value_2) begin
                        // $display("bump");
                        hue_hist_sorter_bump_flag = 1;
                        hue_hist_sorter_stage = hue_hist_sorter_stage_swapping;
                    end 
                end

                hue_hist_sorter_read_lag_counter = 0;

                if (hue_hist_sorter_counter < (full_hue_range - 2)) begin
                    hue_hist_sorter_counter = hue_hist_sorter_counter + 1;

                end else begin

                    hue_hist_sorter_counter = 0;

                    if (hue_hist_sorter_bump_flag == 0) begin
                        sort_hue_hist_flag = 0;

                        $display("B1: hue hist sorting done in %d clocks\n", hue_hist_sorter_total_counter);

                        hue_hist_sorter_stage = hue_hist_sorter_stage_looping;
                        hue_hist_sorter_total_counter = 0;
                        hue_hist_sorter_counter = 0;
                        hue_hist_sorter_read_lag_counter = 0;
                        hue_hist_sorter_write_lag_counter = 0;
                        hue_hist_sorter_temp_var_count_1 = 0;
                        hue_hist_sorter_temp_var_count_2 = 0;
                        hue_hist_sorter_temp_var_hue_value_1 = 0;
                        hue_hist_sorter_temp_var_hue_value_2 = 0;



                        if (hue_hist_sorter_sort_hue == 0) begin
                            $display("B1: let's print the sorted by count...");
                            print_hue_hist_sorted_by_count_flag = 1;
                            // $display("B1: going ahead with find_excluded_hues_flag...");
                            // find_excluded_hues_flag = 1; // B2

                        end else begin
                            $display("B1: normalizing full frame...");

                            normalize_hue_hist_for_masked_full_frame_flag = 1; // B4



                        end

                    end

                    hue_hist_sorter_bump_flag = 0;

                end

            end

        end else if (hue_hist_sorter_stage== hue_hist_sorter_stage_swapping) begin

            hue_hist_sorter_write_lag_counter = hue_hist_sorter_write_lag_counter + 1;

            if (hue_hist_sorter_write_lag_counter == 1) begin
                if (hue_hist_sorter_counter == 0) begin
                    hue_hist_full_frame_mem_write_addr     = (full_hue_range - 2);
                    hue_values_full_frame_mem_write_addr   = (full_hue_range - 2);

                end else begin
                    hue_hist_full_frame_mem_write_addr = hue_hist_sorter_counter - 1;
                    hue_values_full_frame_mem_write_addr = hue_hist_sorter_counter - 1;
                end
                // $display("writing %f on %d", SF_32 * nt.f_bitstream_to_f_pair_item(hue_hist_sorter_temp_var_count_2, 0), hue_hist_full_frame_mem_write_addr);

            end else if (hue_hist_sorter_write_lag_counter == 2) begin
                hue_hist_full_frame_mem_write_data     = hue_hist_sorter_temp_var_count_2;                
                hue_values_full_frame_mem_write_data   = hue_hist_sorter_temp_var_hue_value_2;                

            end else if (hue_hist_sorter_write_lag_counter == 3) begin
                hue_hist_full_frame_mem_write_enable   = 1;
                hue_values_full_frame_mem_write_enable = 1;

            end else if (hue_hist_sorter_write_lag_counter == 4) begin
                hue_hist_full_frame_mem_write_enable   = 0;
                hue_values_full_frame_mem_write_enable = 0;

            end else if (hue_hist_sorter_write_lag_counter == 5) begin
                if (hue_hist_sorter_counter == 0) begin
                    hue_hist_full_frame_mem_write_addr     = full_hue_range - 1;
                    hue_values_full_frame_mem_write_addr   = full_hue_range - 1;
                end else begin
                    hue_hist_full_frame_mem_write_addr     = hue_hist_sorter_counter;
                    hue_values_full_frame_mem_write_addr   = hue_hist_sorter_counter;
                end

                // $display("writing %f on %d", SF_32 * nt.f_bitstream_to_f_pair_item(hue_hist_sorter_temp_var_count_1, 0), hue_hist_full_frame_mem_write_addr);

            end else if (hue_hist_sorter_write_lag_counter == 6) begin
                hue_hist_full_frame_mem_write_data     = hue_hist_sorter_temp_var_count_1;
                hue_values_full_frame_mem_write_data   = hue_hist_sorter_temp_var_hue_value_1;                


            end else if (hue_hist_sorter_write_lag_counter == 7) begin
                hue_hist_full_frame_mem_write_enable   = 1;
                hue_values_full_frame_mem_write_enable = 1;

            end else if (hue_hist_sorter_write_lag_counter == 8) begin
                hue_hist_full_frame_mem_write_enable   = 0;
                hue_values_full_frame_mem_write_enable = 0;

            end else if (hue_hist_sorter_write_lag_counter == 9) begin
                hue_hist_sorter_write_lag_counter = 0;
                hue_hist_sorter_stage = hue_hist_sorter_stage_looping;
            end

        end
    end

end


// B2
// find_excluded_hues_flag
always @(negedge clk) begin
    if (find_excluded_hues_flag == 1) begin
        lagger_B2 = lagger_B2 + 1;

        if (lagger_B2 == 1) begin
            hue_hist_full_frame_mem_read_addr      = counter_B2;
            hue_values_full_frame_mem_read_addr    = counter_B2;
            
        end else if (lagger_B2 == 2) begin
            hue_hist_full_frame_sum_B2 = hue_hist_full_frame_sum_B2 + hue_hist_full_frame_mem_read_data;

        end else if (lagger_B2 == 3) begin
            // $display("hue_hist_full_frame_sum_B2: %d, hue_bins_to_remove: %d", hue_hist_full_frame_sum_B2, hue_bins_to_remove);
            if (hue_hist_full_frame_sum_B2 < hue_bins_to_remove) begin
                excluded_hues[hue_values_full_frame_mem_read_data] = 1'b1;

                // $display("%d: excluding hue: %d, sum:%d < bins:%d",
                // counter_B2+1,
                //  hue_values_full_frame_mem_read_data,
                //  hue_hist_full_frame_sum_B2,
                //  hue_bins_to_remove
                 
                //  );

            end else begin
                // reset
                find_excluded_hues_flag = 0;

                $display("finished find_excluded_hues_flag... %d hues were excluded", counter_B2);
                $display("excluded_hues: %b", excluded_hues);

                build_hue_hist_for_masked_full_frame_flag = 1;
                excluded_hues_is_populated_milestone = 1;


                // excluded_hues = 180'b010110100100001000000000000001000000000000000100101101111111111111111111000000000000000000000000000000000000000000000000000000000000000000001111111111100111111111111111111111111111;

            end

            

        end else if (lagger_B2 == 4) begin


            if (counter_B2 < full_hue_range - 1) begin
                // $display("counter_B2 + 1");

                counter_B2 = counter_B2 + 1;

            end else begin
                // reset
                find_excluded_hues_flag = 0;


                $display("!!!!!!!!!!! finished find_excluded_hues_flag but all hues were excluded !!!!");
                $display("finished find_excluded_hues_flag... %d hues were excluded. hue_hist_full_frame_sum_B2=%d", counter_B2, hue_hist_full_frame_sum_B2);
                $display("excluded_hues: %b", excluded_hues);

                excluded_hues_is_populated_milestone = 1;
                build_hue_hist_for_masked_full_frame_flag = 1;



            end

            lagger_B2 = 0;

        end 
    end
end


// B3
// build_hue_hist_for_masked_full_frame_flag
always @(negedge clk) begin
    if (build_hue_hist_for_masked_full_frame_flag == 1) begin
        lagger_B3 = lagger_B3 + 1;

        if (lagger_B3 == 1) begin
            hue_values_full_frame_mem_read_addr = counter_B3;

        end else if (lagger_B3 == 2) begin
            hue_B3 =   hue_values_full_frame_mem_read_data;


            hue_hist_full_frame_mem_write_addr      = counter_B3; // 
            /*
                this address does not necasarily is for hue = counter_B3. 
                you need to find the address for that hue. that's because hue values are sorted
                you don't know where your required hue is now.
                so first read the contents

            */

            hue_hist_full_frame_mem_write_data      = 0;

            hue_hist_full_frame_mem_read_addr      = counter_B3; //  just for the sake of summation

        end else if (lagger_B3 == 3) begin

            if (excluded_hues[hue_B3] == 1'b1) begin
                hue_hist_full_frame_mem_write_enable = 1;

            end else begin
                sum_of_remaining_pixels_B3 = sum_of_remaining_pixels_B3 + hue_hist_full_frame_mem_read_data;
            end 

        end else if (lagger_B3 == 4) begin
            hue_hist_full_frame_mem_write_enable = 0;


        end else if (lagger_B3 == 5) begin

            if (counter_B3 < full_hue_range - 1) begin

                counter_B3 = counter_B3 + 1;

            end else begin
                counter_B3 = 0;
                build_hue_hist_for_masked_full_frame_flag = 0;
                $display("B3: finished masking the hue hist full frame... sum of remaining pixels: %d", sum_of_remaining_pixels_B3);
                $display("B3: starting to sort by hue..");

                hue_hist_sorter_sort_hue =1;
                sort_hue_hist_flag = 1;

                // $display("going for  build_hue_hist_blocks_flag...");
                // build_hue_hist_blocks_flag = 1;
            end


            lagger_B3 = 0;

        end 
    end
end



// B4
// normalize_hue_hist_for_masked_full_frame_flag
always @(negedge clk) begin
    if (normalize_hue_hist_for_masked_full_frame_flag == 1) begin
        division_B4_start = 0;
        
        lagger_B4 = lagger_B4 + 1;

        if (lagger_B4 == 1) begin
            hue_hist_full_frame_mem_read_addr      = counter_B4;
            hue_hist_full_frame_mem_write_addr     = counter_B4;

            
        end else if (lagger_B4 == 2) begin
            division_B4_x = hue_hist_full_frame_mem_read_data << q_half;
            division_B4_y = sum_of_remaining_pixels_B3 << q_half;


        end else if (lagger_B4 == 3) begin
            division_B4_start = 1;
            normalize_hue_hist_for_masked_full_frame_flag = 0;

        end else if (lagger_B4 == 5) begin
            division_B4_start = 0;
            // hue_hist_full_frame_mem_write_data = nt_aeb.mult(division_B4_q, nt_aeb.one_over_hundared);
            hue_hist_full_frame_mem_write_data = division_B4_q;
            hue_hist_full_frame_norm_sum_B4 = hue_hist_full_frame_norm_sum_B4 + hue_hist_full_frame_mem_write_data;

            // $display("%d normalized hue hist full frame: %f", counter_B4, SF * hue_hist_full_frame_mem_write_data);


        end else if (lagger_B4 == 6) begin
            hue_hist_full_frame_mem_write_enable = 1;

        end else if (lagger_B4 == 7) begin
            hue_hist_full_frame_mem_write_enable = 0;

        end else if (lagger_B4 == 8) begin

            if (counter_B4 < full_hue_range - 1) begin

                counter_B4 = counter_B4 + 1;

            end else begin
                counter_B4 = 0;
                normalize_hue_hist_for_masked_full_frame_flag = 0;
                $display("finished normalizing...");
                $display("sum of masked and normalized hue hists: %f (needs to be close to 1)", SF*hue_hist_full_frame_norm_sum_B4);

                $display("dumping ...");

                build_hue_hist_blocks_flag = 1;
            end


            lagger_B4 = 0;

        end 

    end
end




reg                 [q_full - 1 : 0]                    pixel_counter_B            = 0;
reg                 [q_full - 1 : 0]                    pixel_reader_lag_counter_B    = 0;
reg                 [q_full - 1 : 0]                    hue_hist_dumper_sum    = 0;

// dump_hue_hist_full_frame_mem_to_file_flag
always @(negedge clk) begin
    if (dump_hue_hist_full_frame_mem_to_file_flag == 1) begin
        pixel_reader_lag_counter_B = pixel_reader_lag_counter_B + 1;

        if (pixel_reader_lag_counter_B == 1) begin
            hue_hist_full_frame_mem_read_addr      = pixel_counter_B;
            hue_values_full_frame_mem_read_addr    = pixel_counter_B;

            
        end else if (pixel_reader_lag_counter_B == 2) begin
            hue_hist_dumper_sum = hue_hist_dumper_sum + hue_hist_full_frame_mem_read_data;
            $fdisplay(output_file_hue_hist_full_frame, hue_hist_full_frame_mem_read_data);     // Displays in binary  

            


        end else if (pixel_reader_lag_counter_B == 3) begin

            if (pixel_counter_B < full_hue_range - 1) begin
                pixel_counter_B = pixel_counter_B + 1;

            end else begin
                pixel_counter_B = 0;
                dump_hue_hist_full_frame_mem_to_file_flag = 0;
                $fclose(output_file_hue_hist_full_frame);  
                $display("finished dumping... total pixels in the hue hist: %d", hue_hist_dumper_sum);
                $display("dumped output_file_gray_hist_full_frame_masked.txt");


                sort_hue_hist_flag = 1;

            end


            pixel_reader_lag_counter_B = 0;

        end 
    end
end





// print sorted hue hist


reg                 [q_full - 1 : 0]                    print_counter_B10            = 0;
reg                 [q_full - 1 : 0]                    pixel_reader_lag_counter_B10    = 0;


// print_hue_hist_sorted_by_count_flag
always @(negedge clk) begin
    if (print_hue_hist_sorted_by_count_flag == 1) begin
        pixel_reader_lag_counter_B10 = pixel_reader_lag_counter_B10 + 1;

        if (pixel_reader_lag_counter_B10 == 1) begin
            hue_hist_full_frame_mem_read_addr      = print_counter_B10;
            hue_values_full_frame_mem_read_addr    = print_counter_B10;

            
        // end else if (pixel_reader_lag_counter_B10 == 2) begin
        //     $display("hue_value: %d , hue_count: %d ", 
        //         hue_values_full_frame_mem_read_data,
        //         hue_hist_full_frame_mem_read_data
        //     );
            


        end else if (pixel_reader_lag_counter_B10 == 3) begin

            if (print_counter_B10 < full_hue_range - 1) begin
                print_counter_B10 = print_counter_B10 + 1;

            end else begin
                print_counter_B10 = 0;
                print_hue_hist_sorted_by_count_flag = 0;

                $display("B1: going ahead with find_excluded_hues_flag...");
                find_excluded_hues_flag = 1; // B2



            end


            pixel_reader_lag_counter_B10 = 0;

        end 
    end
end

