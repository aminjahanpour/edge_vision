// Generate Union Mags
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################


reg                 [q_full - 1 : 0]                    counter_C0;
reg                 [laggers_len - 1 : 0]               lagger_C0;

reg                 [q_full - 1 : 0]                    counter_C1;
reg                 [q_full - 1 : 0]                    counter_C1_hue;
reg                 [laggers_len - 1 : 0]               lagger_C1;

reg                 [q_full - 1 : 0]                    block_counter_C0;

reg                 [q_full - 1 : 0]                    width_full_q_C0;

reg                 [q_full - 1 : 0]                    hue_C0;

reg                 [q_full - 1 : 0]                    hue_hist_blocks_sum_C;   
reg                 [q_full - 1 : 0]                    hue_hist_blocks_norm_sum_C;   

reg                 [q_full - 1 : 0]                    normalized_hue_of_blocks_C;
reg                 [q_full - 1 : 0]                    union_mag_C;
reg                 [q_full - 1 : 0]                    union_mag_sum_C;

// reg                 [q_full - 1 : 0]                    pixel_position_C0;
// reg                 [q_full - 1 : 0]                    pixel_global_row_C0;
// reg                 [q_full - 1 : 0]                    pixel_global_col_C0;
// reg                 [q_full - 1 : 0]                    pixel_block_row_idx_C0;
// reg                 [q_full - 1 : 0]                    pixel_block_col_idx_C0;


reg                 [q_full - 1 : 0]                    full_hue_range_full_q;



// C0
// build_hue_hist_blocks_flag
always @(negedge clk) begin
    if (build_hue_hist_blocks_flag == 1) begin

        lagger_C0 = lagger_C0 + 1;

        if (lagger_C0 == 1) begin
            source_frame_hsv_mem_read_addr = counter_C0;

            block_idx_mem_read_addr = counter_C0;

        end else if (lagger_C0 == 2) begin

            block_counter_C0 = block_idx_mem_read_data;

            hue_C0 = (source_frame_hsv_mem_read_data & full_h_mask) >> 16;



        end else if (lagger_C0 == 3) begin

            hue_hist_blocks_mem_read_addr = (block_counter_C0  * full_hue_range_full_q ) +  hue_C0;



            // if (block_counter_C0 == 17) begin
                
            //     $display("counter_C0: %d, block_counter_C0: %d, hue: %d,  addr: %d", 
            //     counter_C0,
            //     block_counter_C0,
            //     hue_C0,
            //     hue_hist_blocks_mem_read_addr);

            // end



        end else if (lagger_C0 == 4) begin
            hue_hist_blocks_mem_write_addr = hue_hist_blocks_mem_read_addr;
            hue_hist_blocks_mem_read_enable = 0;

            // $display("lagger_C0:%d,hue_hist_blocks_mem_write_addr: %b, %d", lagger_C0, hue_hist_blocks_mem_write_addr, hue_hist_blocks_mem_write_addr);

        end else if (lagger_C0 == 5) begin
            hue_hist_blocks_mem_write_data = hue_hist_blocks_mem_read_data + 1;
            // $display("lagger_C0:%d, hue_hist_blocks_mem_write_addr:%d, hue_hist_blocks_mem_write_data: %b, %d",
            //  lagger_C0, hue_hist_blocks_mem_write_addr, hue_hist_blocks_mem_write_data, hue_hist_blocks_mem_write_data);

        end else if (lagger_C0 == 6) begin
            hue_hist_blocks_mem_write_enable = 1;

        end else if (lagger_C0 == 7) begin
            hue_hist_blocks_mem_write_enable = 0;


        end else if (lagger_C0 == 8) begin
            hue_hist_blocks_mem_read_enable = 1;

            if (counter_C0 < (width * height - 1)) begin
                counter_C0 = counter_C0 + 1;

            end else begin
                counter_C0 = 0;
                build_hue_hist_blocks_flag = 0;
                // pixel_position_C0 = 0;
                // pixel_global_row_C0 = 0;
                // pixel_global_col_C0 = 0;
                // pixel_block_row_idx_C0 = 0;
                // pixel_block_col_idx_C0 = 0;
                // block_counter_C0 = 0;

                $display("C0: finished build_hue_hist_blocks");  


                // $display("starting to normalize blocks histogram");  

                // $display("starting to dump_hue_hist_blocks_mem_to_file_flag");  
                // dump_hue_hist_blocks_mem_to_file_flag = 1;

                
                $display("dump_hue_hist_blocks_mem_to_file_flag");  
                dump_hue_hist_blocks_mem_to_file_flag = 1;
                hue_hist_blocks_sum_C = 0;


            end


            lagger_C0 = 0;

        end 

    end
end




/*
find union mag
*/
// C1
// counter here is all_blocks_hue_counter
// build_union_mags_flag
always @(negedge clk) begin
    if (build_union_mags_flag == 1) begin

        lagger_C1 = lagger_C1 + 1;

        if (lagger_C1 == 1) begin
            hue_hist_blocks_mem_read_addr      = counter_C1;
            hue_hist_blocks_mem_write_addr     = counter_C1;

        end else if (lagger_C1 == 2) begin
            // do we have to devide by block_width * block_height?
            // have we not zeroed hue == 0?

            // normalized_hue_of_blocks_C = nt_aeb.mult_hp(hue_hist_blocks_mem_read_data, nt_aeb.one_over_block_pixels_count_hp);
            
            normalized_hue_of_blocks_C = nt_aeb.mult(hue_hist_blocks_mem_read_data << q_half, nt_aeb.one_over_block_pixels_count);
            
            

            // normalized_hue_of_blocks_C = nt_aeb.mult(hue_hist_blocks_mem_read_data << q_half, nt_aeb.one_over_1200);
            
            // if (counter_C1 == 907) begin
            //     $display("\n\n\nblocks_mem data: %b    normalized_hue_of_blocks_C:%b\n\n\n",
            //      hue_hist_blocks_mem_read_data,
            //      normalized_hue_of_blocks_C
            //      );

            //                      $display("\n\n\nblocks_mem data: %f    normalized_hue_of_blocks_C:%f\n\n\n",
            //      SF*hue_hist_blocks_mem_read_data,
            //      SF*normalized_hue_of_blocks_C
            //      );
            // end





        end else if (lagger_C1 == 3) begin
            hue_hist_full_frame_mem_read_addr = counter_C1_hue;

        end else if (lagger_C1 == 4) begin

            if (normalized_hue_of_blocks_C < hue_hist_full_frame_mem_read_data) begin
                union_mag_C = normalized_hue_of_blocks_C;
            end else begin
                union_mag_C = hue_hist_full_frame_mem_read_data;
            end

            // if (
            //     (counter_C1 >= (21 * full_hue_range))
            //     &&
            //     (counter_C1 < (22 * full_hue_range))

            // ) begin


            //     $display("\ncounter_C1: %d  counter_C1_hue: %d  --> hue_hist_blocks_mem_read_data: %f , normalized_hue_of_blocks_C %f", 
            
            //     counter_C1,
            //     counter_C1_hue,

            //     SF*(hue_hist_blocks_mem_read_data << q_half),
            //     SF*normalized_hue_of_blocks_C
            //     );
   

            //     // $display("hue_hist_blocks: %b * one_over_block_pixels_count: %b  = normalized_hue_of_blocks_C %b", 
            
            //     // (hue_hist_blocks_mem_read_data << q_half),
            //     // normalized_hue_of_blocks_C
            //     // );
   
            // end
            
            // if (
            //     (counter_C1 >= (21 * full_hue_range))
            //     &&
            //     (counter_C1 < (22 * full_hue_range))

            // ) begin


            //     $display("counter_C1: %d  counter_C1_hue: %d  full_frame: %f block: %f  union_mag_C: %f", 
            
            //     counter_C1,
            //     counter_C1_hue,

            //     SF*hue_hist_full_frame_mem_read_data,
            //     SF*normalized_hue_of_blocks_C,
            //     SF*union_mag_C
            //     );
   
            // end

        end else if (lagger_C1 == 5) begin

            // $display("counter_C1: %d, counter_C1_hue= %d", counter_C1, counter_C1_hue);
            union_mag_sum_C = union_mag_sum_C + union_mag_C;

            hue_hist_blocks_mem_write_data = union_mag_C;
            hue_hist_blocks_norm_sum_C = hue_hist_blocks_norm_sum_C + normalized_hue_of_blocks_C;

            // $display("hue_hist_blocks_mem_write_data: %f, hue_hist_blocks_norm_sum_C: %f",SF*hue_hist_blocks_mem_write_data, SF*hue_hist_blocks_norm_sum_C);
                
        end else if (lagger_C1 == 6) begin
            hue_hist_blocks_mem_write_enable = 1;

        end else if (lagger_C1 == 7) begin
            hue_hist_blocks_mem_write_enable = 0;

        end else if (lagger_C1 == 8) begin

            if (counter_C1 < (full_hue_range * crop_count * crop_count) - 1) begin

                counter_C1 = counter_C1 + 1;

                counter_C1_hue = counter_C1_hue + 1;

                if (counter_C1_hue == full_hue_range) begin
                    counter_C1_hue = 0;
                end



            end else begin
                counter_C1 = 0;
                build_union_mags_flag = 0;
                $display("C1: finished normalizing blocks and building union mags...");
                $display("C1: hue_hist_blocks_norm_sum_C: %f (needs to be close to 64.0)", SF * hue_hist_blocks_norm_sum_C);
                $display("C1: union_mag_sum_C: %f", SF*union_mag_sum_C);


                $display("start to dump_union_mags_to_file_flag");  
                dump_union_mags_to_file_flag = 1;


                counter_C1 = 0;
                counter_C1_hue = 0;

            end


            lagger_C1 = 0;

        end 

    end
end






reg                 [q_full - 1 : 0]                    pixel_counter_C0            = 0;
reg                 [q_full - 1 : 0]                    pixel_reader_lag_counter_C0    = 0;


// dump_hue_hist_blocks_mem_to_file_flag
always @(negedge clk) begin
    if (dump_hue_hist_blocks_mem_to_file_flag == 1) begin
        pixel_reader_lag_counter_C0 = pixel_reader_lag_counter_C0 + 1;

        if (pixel_reader_lag_counter_C0 == 1) begin
            hue_hist_blocks_mem_read_addr      = pixel_counter_C0;
            
        end else if (pixel_reader_lag_counter_C0 == 2) begin
            hue_hist_blocks_sum_C = hue_hist_blocks_sum_C + hue_hist_blocks_mem_read_data;
            $fdisplay(output_file_hue_hist_blocks, hue_hist_blocks_mem_read_data);  // row integer values of the histogram


        end else if (pixel_reader_lag_counter_C0 == 3) begin


            if (pixel_counter_C0 < (full_hue_range * crop_count * crop_count) - 1) begin
                // $display("pixel_counter_C0 + 1");

                pixel_counter_C0 = pixel_counter_C0 + 1;

            end else begin
                pixel_counter_C0 = 0;
                dump_hue_hist_blocks_mem_to_file_flag = 0;
                $fclose(output_file_hue_hist_blocks);  
                $display("finished dumping blocks hue hists... hue_hist_blocks_sum_C:%d (should be exactly width*height)", hue_hist_blocks_sum_C);
                $display("dumped output_file_hue_hist_blocks.txt");
                hue_hist_blocks_sum_C = 0;

                // process_union_mag_per_hue_color_range_for_all_blocks_flag = 1;
                build_union_mags_flag = 1;

            end


            pixel_reader_lag_counter_C0 = 0;

        end 
    end
end




reg                 [q_full - 1 : 0]                    pixel_counter_C1            = 0;
reg                 [q_full - 1 : 0]                    pixel_reader_lag_counter_C1    = 0;


// dump_union_mags_to_file_flag
always @(negedge clk) begin
    if (dump_union_mags_to_file_flag == 1) begin
        pixel_reader_lag_counter_C1 = pixel_reader_lag_counter_C1 + 1;

        if (pixel_reader_lag_counter_C1 == 1) begin
            hue_hist_blocks_mem_read_addr      = pixel_counter_C1;
            
        end else if (pixel_reader_lag_counter_C1 == 2) begin
            hue_hist_blocks_sum_C = hue_hist_blocks_sum_C + hue_hist_blocks_mem_read_data;
            $fdisplay(output_file_union_mags, SF * hue_hist_blocks_mem_read_data);  // for float value of um - just for plotting and comparing with python


        end else if (pixel_reader_lag_counter_C1 == 3) begin


            if (pixel_counter_C1 < (full_hue_range * crop_count * crop_count) - 1) begin
                // $display("pixel_counter_C1 + 1");

                pixel_counter_C1 = pixel_counter_C1 + 1;

            end else begin
                pixel_counter_C1 = 0;
                dump_union_mags_to_file_flag = 0;
                $fclose(output_file_union_mags);  
                $display("finished dumping union mags... sum union_mags: %f", SF* hue_hist_blocks_sum_C);
                $display("dumped output_file_hue_hist_blocks.txt");
                hue_hist_blocks_sum_C = 0;

                $display("C1: starting to FIND SS and SD process_union_mag_per_hue_color_range_for_all_blocks_flag");  
                process_union_mag_per_hue_color_range_for_all_blocks_flag = 1;

            end


            pixel_reader_lag_counter_C1 = 0;

        end 
    end
end



































