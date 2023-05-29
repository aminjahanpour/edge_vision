// ########################################################################################################################################################################################
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################
// start of process 2

reg                 [laggers_len - 1 : 0]               lagger_E0;
reg                 [q_full - 1 : 0]                    counter_E0;
reg                 [q_full - 1 : 0]                    hue_E0;


reg                 [laggers_len - 1 : 0]               lagger_E1;
reg                 [q_full - 1 : 0]                    counter_E1;


reg                 [q_full - 1 : 0]                    red_E1;
reg                 [q_full - 1 : 0]                    green_E1;
reg                 [q_full - 1 : 0]                    blue_E1;
reg                 [q_full - 1 : 0]                    gray_E1;



/*
you need to wait for process 1 to produce `excluded_hues`
then you proceed to eventually generate basepoints

then you wait until process one generates `most_significant_blocks_idx`

then we are ready for encoding

*/
// E0
always @(negedge clk) begin
    if (build_frame_ram_with_hue_included_mask_flag == 1) begin
        // task_manager_aux_flag_1 = 0;
        
        lagger_E0 = lagger_E0 + 1;

        if (lagger_E0 == 1) begin

            source_frame_hsv_mem_read_addr          = counter_E0;

            if (color_system == 0) begin
                masked_rgb_frame_ram_read_addr      = counter_E0;
                masked_rgb_frame_ram_write_addr     = counter_E0;

            end else if (color_system == 0) begin
                masked_gray_frame_ram_read_addr     = counter_E0;
                masked_gray_frame_ram_write_addr    = counter_E0;

            end

        end else if (lagger_E0 == 2) begin

            hue_E0 = (source_frame_hsv_mem_read_data & full_h_mask) >> 16;


            // $display("counter_E0=%d, hue_E0=%d,  %b",
            // counter_E0,
            //  hue_E0,
            //  excluded_hues[hue_E0],
            //   );

        end else if (lagger_E0 == 3) begin

                if (color_system == 0) begin
                    masked_rgb_frame_ram_write_data = 0;

                end else if (color_system == 3) begin
                    masked_gray_frame_ram_write_data = 0;

                end


        end else if (lagger_E0 == 4) begin

            if (excluded_hues[hue_E0] == 1'b1) begin

                if (color_system == 0) begin
                    masked_rgb_frame_ram_write_enable = 1;

                end else if (color_system == 3) begin
                    masked_gray_frame_ram_write_enable = 1;
                end

            end


        end else if (lagger_E0 == 5) begin
            masked_rgb_frame_ram_write_enable = 0;
            masked_gray_frame_ram_write_enable = 0;

        end else if (lagger_E0 == 6) begin
            if (color_system == 0) begin
                $fdisplayb(output_file_masked_rgb_frame, masked_rgb_frame_ram_read_data);

            end else if (color_system == 3) begin
                $fdisplayb(output_file_masked_gray_frame, masked_gray_frame_ram_read_data);

            end

        end else if (lagger_E0 == 7) begin

            if (counter_E0 < (width * height - 1)) begin
                counter_E0 = counter_E0 + 1;

            end else begin
                counter_E0 = 0;
                build_frame_ram_with_hue_included_mask_flag = 0;

                if (color_system == 0) begin
                    $fclose(output_file_masked_rgb_frame);  
                    $display("E0: dumped output_file_masked_rgb_frame.txt");

                end else if (color_system == 3) begin
                    $fclose(output_file_masked_gray_frame);  
                    $display("E0: dumped output_file_masked_gray_frame.txt");

                end

                $display("E0: going ahead with get_color_hists_for_masked_full_frame");
                get_color_hists_for_masked_full_frame = 1;
            end

            lagger_E0 = 0;

        end 



    end
end


// get_color_hists_for_masked_full_frame
// E1
always @(negedge clk) begin
    if (get_color_hists_for_masked_full_frame == 1) begin
        
        lagger_E1 = lagger_E1 + 1;

        if (lagger_E1 == 1) begin
            if (color_system == 0) begin
                masked_rgb_frame_ram_read_addr = counter_E1;
                
            end else if (color_system == 3) begin
                masked_gray_frame_ram_read_addr = counter_E1;
            end

        end else if (lagger_E1 == 2) begin
            if (color_system == 0) begin
                red_E1 =   (masked_rgb_frame_ram_read_data & full_r_mask) >> 16;
                green_E1 = (masked_rgb_frame_ram_read_data & full_g_mask) >> 8;
                blue_E1 =  (masked_rgb_frame_ram_read_data & full_b_mask);

                // $display("masked_rgb_frame_ram_read_data:%b, red:%b, green:%b, blue:%b",
                // masked_rgb_frame_ram_read_data,
                //  red_E1,
                //  green_E1,
                //  blue_E1);

            end else if (color_system == 3) begin
                gray_E1 = masked_gray_frame_ram_read_data;

            end

        end else if (lagger_E1 == 3) begin
            if (color_system == 0) begin
                red_hist_full_frame_masked_ram_read_addr    = red_E1;
                green_hist_full_frame_masked_ram_read_addr  = green_E1;
                blue_hist_full_frame_masked_ram_read_addr   = blue_E1;

                red_hist_full_frame_masked_ram_write_addr    = red_E1;
                green_hist_full_frame_masked_ram_write_addr  = green_E1;
                blue_hist_full_frame_masked_ram_write_addr   = blue_E1;


            end else if (color_system == 3) begin
                gray_hist_full_frame_masked_ram_read_addr   = gray_E1;
                gray_hist_full_frame_masked_ram_write_addr   = gray_E1;

            end



            // $display("lagger_E1:%d,hue_hist_full_frame_mem_write_addr: %b, %d", lagger_E1, hue_hist_full_frame_mem_write_addr, hue_hist_full_frame_mem_write_addr);

        end else if (lagger_E1 == 4) begin
            if (color_system == 0) begin
                red_hist_full_frame_masked_ram_write_data   = red_hist_full_frame_masked_ram_read_data      + 1;
                green_hist_full_frame_masked_ram_write_data = green_hist_full_frame_masked_ram_read_data    + 1;
                blue_hist_full_frame_masked_ram_write_data  = blue_hist_full_frame_masked_ram_read_data     + 1;

            end else if (color_system == 3) begin
                gray_hist_full_frame_masked_ram_write_data   = gray_hist_full_frame_masked_ram_read_data      + 1;

            end

            // $display("lagger_E1:%d,hue_hist_full_frame_mem_write_data: %b, %d", lagger_E1, hue_hist_full_frame_mem_write_data, hue_hist_full_frame_mem_write_data);

        end else if (lagger_E1 == 5) begin
            if (color_system == 0) begin

                if (red_E1 > 0) begin
                    red_hist_full_frame_masked_ram_write_enable = 1;
                end

                if (green_E1 > 0) begin
                    green_hist_full_frame_masked_ram_write_enable = 1;
                end

                if (blue_E1 > 0) begin
                    blue_hist_full_frame_masked_ram_write_enable = 1;
                end

            end else if (color_system == 3) begin

                if (gray_E1 > 0) begin
                    gray_hist_full_frame_masked_ram_write_enable = 1;
                end
            end


        end else if (lagger_E1 == 6) begin
            if (color_system == 0) begin
                red_hist_full_frame_masked_ram_write_enable = 0;
                green_hist_full_frame_masked_ram_write_enable = 0;
                blue_hist_full_frame_masked_ram_write_enable = 0;

            end else if (color_system == 3) begin
                gray_hist_full_frame_masked_ram_write_enable = 0;

            end


        end else if (lagger_E1 == 7) begin

            if (counter_E1 < (width * height - 1)) begin
                counter_E1 = counter_E1 + 1;

            end else begin
                counter_E1 = 0;
                get_color_hists_for_masked_full_frame = 0;
                // dump_hue_hist_full_frame_mem_to_file_flag = 1; // output_file_hue_hist_full_frame.txt
                // hue_hist_full_frame_norm_sum = 0;

                $display("E1: finished get_color_hists_for_masked_full_frame");  
                
                // $display("starting to dump_hue_hist_full_frame_mem_to_file_flag");  
                // dump_hue_hist_full_frame_mem_to_file_flag = 1;


                $display("E1: going to get_color_hists_for_masked_full_frame");  
                get_remaining_pixels_count_for_rgb_hists_flag = 1;

            end

            lagger_E1 = 0;

        end 

    end
end

