reg                 [q_full - 1 : 0]                    ram_reset_counter_cap;

reg                 [q_full - 1 : 0]                    pixel_counter_ram_reset                 = 0;
reg                 [q_full - 1 : 0]                    pixel_reader_lag_counter_ram_reset      = 0;


always @(negedge clk) begin
    if (reset_rams_flag == 1) begin
        pixel_reader_lag_counter_ram_reset = pixel_reader_lag_counter_ram_reset + 1;

        if (pixel_reader_lag_counter_ram_reset == 1) begin



            if (pixel_counter_ram_reset < (width * height)) begin
                decoded_frame_rgb_mem_write_addr            = pixel_counter_ram_reset;
                y_dct_mem_write_addr                        = pixel_counter_ram_reset;
                cb_dct_mem_write_addr                       = pixel_counter_ram_reset;
                cr_dct_mem_write_addr                       = pixel_counter_ram_reset;
            
            end

            if (pixel_counter_ram_reset < (hue_color_range_count * crop_count * crop_count)) begin
                ss_ram_write_addr                           = pixel_counter_ram_reset;
                sh_ram_write_addr                           = pixel_counter_ram_reset;
                s_ram_write_addr                            = pixel_counter_ram_reset;
                xb_ram_write_addr                           = pixel_counter_ram_reset;
                var_ram_write_addr                          = pixel_counter_ram_reset;
            end


            if (pixel_counter_ram_reset < (crop_count * crop_count)) begin
                ss_sum_ram_write_addr                       = pixel_counter_ram_reset;
                var_sum_ram_write_addr                      = pixel_counter_ram_reset;
                ss_sum_arg_sort_ram_write_addr              = pixel_counter_ram_reset; // counter
            end


            if (pixel_counter_ram_reset < full_color_range) begin
                red_hist_full_frame_masked_ram_write_addr   = pixel_counter_ram_reset;
                green_hist_full_frame_masked_ram_write_addr = pixel_counter_ram_reset;
                blue_hist_full_frame_masked_ram_write_addr  = pixel_counter_ram_reset;
                gray_hist_full_frame_masked_ram_write_addr  = pixel_counter_ram_reset;
            end


            if (pixel_counter_ram_reset < full_hue_range) begin
                hue_hist_full_frame_mem_write_addr          = pixel_counter_ram_reset;
                hue_values_full_frame_mem_write_addr        = pixel_counter_ram_reset; // counter
            end

            if (pixel_counter_ram_reset < (full_hue_range * crop_count * crop_count)) begin
                hue_hist_blocks_mem_write_addr              = pixel_counter_ram_reset;
            end


            

















        end else if (pixel_reader_lag_counter_ram_reset == 2) begin



            if (pixel_counter_ram_reset < (width * height)) begin
                decoded_frame_rgb_mem_write_data            = 0;
                y_dct_mem_write_data                        = 0;
                cb_dct_mem_write_data                       = 0;
                cr_dct_mem_write_data                       = 0;
            
            end

            if (pixel_counter_ram_reset < (hue_color_range_count * crop_count * crop_count)) begin
                ss_ram_write_data                           = 0;
                sh_ram_write_data                           = 0;
                s_ram_write_data                            = 0;
                xb_ram_write_data                           = 0;
                var_ram_write_data                          = 0;
            end


            if (pixel_counter_ram_reset < (crop_count * crop_count)) begin
                ss_sum_ram_write_data                       = 0;
                var_sum_ram_write_data                      = 0;
                ss_sum_arg_sort_ram_write_data              = pixel_counter_ram_reset; // counter
            end


            if (pixel_counter_ram_reset < full_color_range) begin
                red_hist_full_frame_masked_ram_write_data   = 0;
                green_hist_full_frame_masked_ram_write_data = 0;
                blue_hist_full_frame_masked_ram_write_data  = 0;
                gray_hist_full_frame_masked_ram_write_data  = 0;
            end


            if (pixel_counter_ram_reset < full_hue_range) begin
                hue_hist_full_frame_mem_write_data          = 0;
                hue_values_full_frame_mem_write_data        = pixel_counter_ram_reset; // counter
            end

            if (pixel_counter_ram_reset < (full_hue_range * crop_count * crop_count)) begin
                hue_hist_blocks_mem_write_data              = 0;
            end


























        end else if (pixel_reader_lag_counter_ram_reset == 3) begin




            if (pixel_counter_ram_reset < (width * height)) begin
                decoded_frame_rgb_mem_write_enable            = 1;
                y_dct_mem_write_enable                        = 1;
                cb_dct_mem_write_enable                       = 1;
                cr_dct_mem_write_enable                       = 1;
            end

            if (pixel_counter_ram_reset < (hue_color_range_count * crop_count * crop_count)) begin
                ss_ram_write_enable                           = 1;
                sh_ram_write_enable                           = 1;
                s_ram_write_enable                            = 1;
                xb_ram_write_enable                           = 1;
                var_ram_write_enable                          = 1;
            end


            if (pixel_counter_ram_reset < (crop_count * crop_count)) begin
                ss_sum_ram_write_enable                       = 1;
                var_sum_ram_write_enable                      = 1;
                ss_sum_arg_sort_ram_write_enable              = 1; // counter
            end


            if (pixel_counter_ram_reset < full_color_range) begin
                red_hist_full_frame_masked_ram_write_enable   = 1;
                green_hist_full_frame_masked_ram_write_enable = 1;
                blue_hist_full_frame_masked_ram_write_enable  = 1;
                gray_hist_full_frame_masked_ram_write_enable  = 1;
            end


            if (pixel_counter_ram_reset < full_hue_range) begin
                hue_hist_full_frame_mem_write_enable          = 1;
                hue_values_full_frame_mem_write_enable        = 1; // counter
            end

            if (pixel_counter_ram_reset < (full_hue_range * crop_count * crop_count)) begin
                hue_hist_blocks_mem_write_enable              = 1;
            end




























        end else if (pixel_reader_lag_counter_ram_reset == 4) begin



            
            if (pixel_counter_ram_reset < (width * height)) begin
                decoded_frame_rgb_mem_write_enable            = 0;
                y_dct_mem_write_enable                        = 0;
                cb_dct_mem_write_enable                       = 0;
                cr_dct_mem_write_enable                       = 0;
            end

            if (pixel_counter_ram_reset < (hue_color_range_count * crop_count * crop_count)) begin
                ss_ram_write_enable                           = 0;
                sh_ram_write_enable                           = 0;
                s_ram_write_enable                            = 0;
                xb_ram_write_enable                           = 0;
                var_ram_write_enable                          = 0;
            end


            if (pixel_counter_ram_reset < (crop_count * crop_count)) begin
                ss_sum_ram_write_enable                       = 0;
                var_sum_ram_write_enable                      = 0;
                ss_sum_arg_sort_ram_write_enable              = 0; // counter
            end


            if (pixel_counter_ram_reset < full_color_range) begin
                red_hist_full_frame_masked_ram_write_enable   = 0;
                green_hist_full_frame_masked_ram_write_enable = 0;
                blue_hist_full_frame_masked_ram_write_enable  = 0;
                gray_hist_full_frame_masked_ram_write_enable  = 0;
            end


            if (pixel_counter_ram_reset < full_hue_range) begin
                hue_hist_full_frame_mem_write_enable          = 0;
                hue_values_full_frame_mem_write_enable        = 0; // counter
            end

            if (pixel_counter_ram_reset < (full_hue_range * crop_count * crop_count)) begin
                hue_hist_blocks_mem_write_enable              = 0;
            end







        end else if (pixel_reader_lag_counter_ram_reset == 5) begin

            if (pixel_counter_ram_reset < ram_reset_counter_cap - 1) begin
                pixel_counter_ram_reset = pixel_counter_ram_reset + 1;

            end else begin
                pixel_counter_ram_reset = 0;
                reset_rams_flag = 0;
                $display("finished reset_rams_flag");


                ram_reset_is_done_milestone = 1;
            end


            pixel_reader_lag_counter_ram_reset = 0;

        end 
    end
end











reg                 [q_full - 1 : 0]                    counter_populate_block_ram_idx_Z1                 = 0;
reg                 [q_full - 1 : 0]                    lagger_populate_block_ram_idx_Z1      = 0;


reg                 [q_full - 1 : 0]                    block_col_Z1      = 0;
reg                 [q_full - 1 : 0]                    block_row_Z1      = 0;
reg                 [q_full - 1 : 0]                    pixel_col_counter_Z1      = 0;
reg                 [q_full - 1 : 0]                    pixel_row_counter_Z1      = 0;


reg                 [q_full - 1 : 0]                    group_col_Z2      = 0;
reg                 [q_full - 1 : 0]                    group_row_Z2      = 0;
reg                 [q_full - 1 : 0]                    pixel_col_counter_Z2      = 0;
reg                 [q_full - 1 : 0]                    pixel_row_counter_Z2      = 0;


// this code is used to identify the block to which every pixel belongs
// results are stored in block_idx_mem
always @(negedge clk) begin
    if (populate_block_idx_flag == 1) begin
        lagger_populate_block_ram_idx_Z1 = lagger_populate_block_ram_idx_Z1 + 1;

        if (lagger_populate_block_ram_idx_Z1 == 1) begin

            block_idx_mem_write_addr = counter_populate_block_ram_idx_Z1;
            // group_idx_mem_write_addr = counter_populate_block_ram_idx_Z1;

        end else if (lagger_populate_block_ram_idx_Z1 == 2) begin

            if (pixel_col_counter_Z1 == block_width) begin
                block_col_Z1 = block_col_Z1 + 1;
                pixel_col_counter_Z1 = 0;
            end


            if (block_col_Z1 == crop_count) begin
                block_col_Z1 = 0;
                pixel_row_counter_Z1 = pixel_row_counter_Z1 + 1;
            end

            if (pixel_row_counter_Z1 == block_height) begin
                pixel_row_counter_Z1 = 0;
                block_row_Z1 = block_row_Z1 + 1;
            end

            pixel_col_counter_Z1 = pixel_col_counter_Z1 + 1;

            block_idx_mem_write_data = block_row_Z1 * crop_count + block_col_Z1;


            // $display("counter: %d, block_col_Z1:%d , block_row_Z1:%d, block_idx:%d", 
            // counter_populate_block_ram_idx_Z1,
            // block_col_Z1,
            // block_row_Z1,
            // block_idx_mem_write_data
            
            // );

        end else if (lagger_populate_block_ram_idx_Z1 == 3) begin
            block_idx_mem_write_enable = 1;

        end else if (lagger_populate_block_ram_idx_Z1 == 4) begin
            block_idx_mem_write_enable = 0;






        end else if (lagger_populate_block_ram_idx_Z1 == 5) begin
            
            if (pixel_col_counter_Z2 == 8) begin
                group_col_Z2 = group_col_Z2 + 1;
                pixel_col_counter_Z2 = 0;
            end


            if (group_col_Z2 == width_over_eight) begin // that's a row
                group_col_Z2 = 0;
                pixel_row_counter_Z2 = pixel_row_counter_Z2 + 1;
            end

            if (pixel_row_counter_Z2 == 8) begin
                pixel_row_counter_Z2 = 0;
                group_row_Z2 = group_row_Z2 + 1;
            end

            pixel_col_counter_Z2 = pixel_col_counter_Z2 + 1;

            group_idx_mem_write_data = group_row_Z2 * width_over_eight + group_col_Z2;


            // $display("counter: %d, group_col_Z2:%d , group_row_Z2:%d, group_idx:%d", 
            // counter_populate_block_ram_idx_Z1,
            // group_col_Z2,
            // group_row_Z2,
            // group_idx_mem_write_data
            
            // );

            // $display("counter: %d, group_idx_mem_write_data:%d , block_idx_mem_write_data:%d", 
            // counter_populate_block_ram_idx_Z1,
            // group_idx_mem_write_data,
            // block_idx_mem_write_data            
            // );


        end else if (lagger_populate_block_ram_idx_Z1 == 6) begin
            group_block_idx_mem_write_addr = group_idx_mem_write_data;

        end else if (lagger_populate_block_ram_idx_Z1 == 7) begin
            group_block_idx_mem_write_data = block_idx_mem_write_data;


        end else if (lagger_populate_block_ram_idx_Z1 == 8) begin
            group_block_idx_mem_write_enable = 1;

        end else if (lagger_populate_block_ram_idx_Z1 == 9) begin
            group_block_idx_mem_write_enable = 0;



        end else if (lagger_populate_block_ram_idx_Z1 == 10) begin
            group_idx_mem_write_enable = 1;

        end else if (lagger_populate_block_ram_idx_Z1 == 11) begin
            group_idx_mem_write_enable = 0;




        end else if (lagger_populate_block_ram_idx_Z1 == 12) begin
            if (counter_populate_block_ram_idx_Z1 < width * height - 1) begin
                counter_populate_block_ram_idx_Z1 = counter_populate_block_ram_idx_Z1 + 1;

            end else begin
                counter_populate_block_ram_idx_Z1 = 0;
                populate_block_idx_flag = 0;

                $display("finished populating block_idx ram");
                block_idx_mem_is_populated_milestone = 1;


                // $display("finished populating group_idx ram");
                // group_idx_mem_is_populated_milestone = 1;

            end

            lagger_populate_block_ram_idx_Z1 = 0;

        end 
    end
end










// reg                 [q_full - 1 : 0]                    counter_populate_group_ram_idx_Z2                 = 0;
// reg                 [q_full - 1 : 0]                    lagger_populate_group_ram_idx_Z2      = 0;


// reg                 [q_full - 1 : 0]                    group_col_Z2      = 0;
// reg                 [q_full - 1 : 0]                    group_row_Z2      = 0;
// reg                 [q_full - 1 : 0]                    pixel_col_counter_Z2      = 0;
// reg                 [q_full - 1 : 0]                    pixel_row_counter_Z2      = 0;


// // this code is used to identify the 8*8 pixel group to which every pixel belongs
// // results are stored in group_idx_mem
// always @(negedge clk) begin
//     if (populate_group_idx_flag == 1) begin
//         lagger_populate_group_ram_idx_Z2 = lagger_populate_group_ram_idx_Z2 + 1;

//         if (lagger_populate_group_ram_idx_Z2 == 1) begin

//             group_idx_mem_write_addr = counter_populate_group_ram_idx_Z2;

//         end else if (lagger_populate_group_ram_idx_Z2 == 2) begin

//             if (pixel_col_counter_Z2 == 8) begin
//                 group_col_Z2 = group_col_Z2 + 1;
//                 pixel_col_counter_Z2 = 0;
//             end


//             if (group_col_Z2 == width_over_eight) begin // that's a row
//                 group_col_Z2 = 0;
//                 pixel_row_counter_Z2 = pixel_row_counter_Z2 + 1;
//             end

//             if (pixel_row_counter_Z2 == 8) begin
//                 pixel_row_counter_Z2 = 0;
//                 group_row_Z2 = group_row_Z2 + 1;
//             end

//             pixel_col_counter_Z2 = pixel_col_counter_Z2 + 1;

//             group_idx_mem_write_data = group_row_Z2 * width_over_eight + group_col_Z2;


//             $display("counter: %d, group_col_Z2:%d , group_row_Z2:%d, group_idx:%d", 
//             counter_populate_group_ram_idx_Z2,
//             group_col_Z2,
//             group_row_Z2,
//             group_idx_mem_write_data
            
//             );

//         end else if (lagger_populate_group_ram_idx_Z2 == 3) begin
//             group_idx_mem_write_enable = 1;

//         end else if (lagger_populate_group_ram_idx_Z2 == 4) begin
//             group_idx_mem_write_enable = 0;

//         end else if (lagger_populate_group_ram_idx_Z2 == 5) begin
//             if (counter_populate_group_ram_idx_Z2 < width * height - 1) begin
//                 counter_populate_group_ram_idx_Z2 = counter_populate_group_ram_idx_Z2 + 1;

//             end else begin
//                 counter_populate_group_ram_idx_Z2 = 0;
//                 populate_group_idx_flag = 0;
//                 $display("finished populating group_idx ram");
                
//                 group_idx_mem_is_populated_milestone = 1;
//             end

//             lagger_populate_group_ram_idx_Z2 = 0;

//         end 
//     end
// end
