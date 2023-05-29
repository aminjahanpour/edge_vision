
// UMapper ENCODER
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################


reg                 [5: 0]                              umapper_stage               ;

localparam          [5: 0]                              umapper_stage_controller     = 0;
localparam          [5: 0]                              umapper_stage_worker         = 1;
localparam          [5: 0]                              umapper_stage_finished       = 2;

reg                 [sum_bpu - 1 : 0]                   encoder_aeb;

reg                 [laggers_len - 1 : 0]               umapper_lagger_1;
reg                 [laggers_len - 1 : 0]               umapper_lagger_2;

reg                 [q_full - 1 : 0]                    encoder_start_pixel_address;
reg                 [q_full - 1 : 0]                    encoder_end_pixel_address;


reg                 [q_full - 1 : 0]                    encoder_block_position;
reg                 [q_full - 1 : 0]                    encoder_block_row;
reg                 [q_full - 1 : 0]                    encoder_block_col;

reg                 [q_full - 1 : 0]                    encoder_pixel_block_column_counter;
reg                 [q_full - 1 : 0]                    encoder_pixel_block_counter;
reg                 [q_full - 1 : 0]                    encoder_total_pixel_counter;

reg                 [q_full - 1 : 0]                    encoder_block_counter;
reg                 [q_full - 1 : 0]                    encoder_pixel_counter;


reg                 [q_full - 1 : 0]                    encoder_r_full_q                            ;
reg                 [q_full - 1 : 0]                    encoder_g_full_q                            ;
reg                 [q_full - 1 : 0]                    encoder_b_full_q                            ;
reg                 [q_full - 1 : 0]                    encoder_gray_full_q                            ;


// Counting the Blocks
always @(negedge clk) begin

    if (umapper_stage == umapper_stage_controller) begin
        // task_manager_aux_flag_2 = 0;
        
        // $display("umapper_lagger_1:%d, encoder_block_counter:%d",umapper_lagger_1, encoder_block_counter);
        umapper_lagger_1 = umapper_lagger_1 + 1;

        if (umapper_lagger_1 == 1)  begin

            // Is the block among the most significant ones?
            if (most_significant_block_idxs[encoder_block_counter] == 1'b1) begin

                encoder_block_position      = nt_aeb.mult_hp(encoder_block_counter, one_over_crop_count);
                encoder_block_row           = encoder_block_position >> q_half;
                encoder_block_col           = nt_aeb.mult( (encoder_block_position & nt_aeb.floating_part_mask) , full_q_crop_count) >> q_half;

                // these addresses are inclusive
                encoder_start_pixel_address = (encoder_block_row * block_width * block_height * crop_count) + encoder_block_col * block_width;
                encoder_end_pixel_address = (encoder_block_row * crop_count * block_height * block_width) + ((block_height-1) * crop_count * block_width)+ ((encoder_block_col + 1) * block_width);

                encoder_pixel_counter = encoder_start_pixel_address;
                encoder_pixel_block_column_counter = 0;
                encoder_pixel_block_counter = 0;

                $display("ENCODER Controller: ---------------block counter %d, block_global_row:%d, block_global_col:%d, encoder_start_pixel_address:%d, encoder_end_pixel_address:%d",
                 encoder_block_counter,
                 encoder_block_row,
                 encoder_block_col,
                 encoder_start_pixel_address,
                 encoder_end_pixel_address
                 
                 );

                umapper_stage = umapper_stage_worker;

            end 
            
            
            

        end else if (umapper_lagger_1 == 2)  begin

            if (encoder_block_counter == ((crop_count * crop_count) - 1)) begin
                umapper_stage = umapper_stage_finished;
                $display("ENCODER: finished mapping %d pixels in total.", encoder_total_pixel_counter);
                

                $fclose(output_file_aeb_frame);     // Displays in binary  

                // $display("dumping..");
                // pixel_reader_lag_counter = 0;
                // encoder_pixel_counter = 0;
                // dump_aeb_frame_to_file_flag = 1;

                $display("ENCODER: starting to decode..");
                // umapper_decoder_active_flag = 1;
                decoder_stage = decoder_stage_controller;


            end else begin
                encoder_block_counter = encoder_block_counter + 1;

            end

            umapper_lagger_1 = 0;

        end

    end

end




// UMapper Encoding the Block
always @(negedge clk) begin

    if (umapper_stage == umapper_stage_worker) begin

        umapper_lagger_2 = umapper_lagger_2 + 1;

        if (umapper_lagger_2 == 1) begin
            if (color_system == 0) begin
                source_frame_rgb_mem_read_addr = encoder_pixel_counter;

            end else if (color_system == 3) begin
                source_frame_gray_mem_read_addr = encoder_pixel_counter;

            end

        end else if (umapper_lagger_2 == 2) begin
            encoder_aeb= 0;

        end else if (umapper_lagger_2 == 3) begin

            if (color_system == 0) begin
                if(red_base_points > 0) begin
                    encoder_r_full_q = (source_frame_rgb_mem_read_data & full_r_mask) >> 16;
                    encoder_r_full_q = nt_aeb.get_aeb(red_base_points, encoder_r_full_q);
                    encoder_aeb=       encoder_r_full_q << (bpu_g + bpu_b);

                end 
            end else if (color_system == 3) begin
                if(gray_base_points > 0) begin
                    encoder_gray_full_q = source_frame_gray_mem_read_data;
                                        // $display("encoder_gray_full_q: %b", encoder_gray_full_q);

                    encoder_gray_full_q = nt_aeb.get_aeb(gray_base_points, encoder_gray_full_q);
                    encoder_aeb=       encoder_gray_full_q;

                end 
            end 
            


        end else if (umapper_lagger_2 == 4) begin

            if (color_system == 0) begin
                if(green_base_points > 0) begin
                    encoder_g_full_q = (source_frame_rgb_mem_read_data & full_g_mask) >> 8;
                    encoder_g_full_q = nt_aeb.get_aeb(green_base_points, encoder_g_full_q);
                    encoder_aeb= encoder_aeb+ (encoder_g_full_q << bpu_b);

                end 
            end 
            

        end else if (umapper_lagger_2 == 5) begin

            if (color_system == 0) begin
                if(blue_base_points > 0) begin
                    encoder_b_full_q = (source_frame_rgb_mem_read_data & full_b_mask);
                    encoder_b_full_q = nt_aeb.get_aeb(blue_base_points, encoder_b_full_q);
                    encoder_aeb= encoder_aeb+ encoder_b_full_q;

                end 
            end 


        end else if (umapper_lagger_2 == 6) begin
            // $display("encoder_total_pixel_counter:%d, encoder_aeb:%b", encoder_total_pixel_counter, encoder_aeb);
            aeb_frame_mem_write_addr = encoder_total_pixel_counter;
            encoder_total_pixel_counter = encoder_total_pixel_counter + 1;


        end else if (umapper_lagger_2 == 7) begin
            aeb_frame_mem_write_data = encoder_aeb;


        end else if (umapper_lagger_2 == 8) begin
            aeb_frame_mem_write_enable = 1;


        end else if (umapper_lagger_2 == 9) begin
            aeb_frame_mem_write_enable = 0;

        end else if (umapper_lagger_2 == 10) begin
            
            if (encoder_pixel_counter == encoder_end_pixel_address) begin
                umapper_stage = umapper_stage_controller;
                encoder_total_pixel_counter = encoder_total_pixel_counter - 1;
                // $display("encoded %d pixels         encoder_total_pixel_counter:", encoder_pixel_block_counter, encoder_total_pixel_counter);

            end else begin
                encoder_pixel_counter = encoder_pixel_counter + 1;
                encoder_pixel_block_counter = encoder_pixel_block_counter + 1;
                encoder_pixel_block_column_counter = encoder_pixel_block_column_counter + 1;


                $fdisplayb(output_file_aeb_frame, encoder_aeb);     // Displays in binary  

                /*
                    if we have reached the last column of the block we need to skip to the first column
                    of the next row.
                */
                if ((encoder_pixel_block_column_counter == block_width)&&(encoder_pixel_counter < encoder_end_pixel_address)) begin
                    // $display("encoder_pixel_counter: %d skipping to", encoder_pixel_counter);
                    encoder_pixel_block_column_counter = 0;
                    encoder_pixel_counter = encoder_pixel_counter + (crop_count - 1) * block_width;

                    // $display("encoder_pixel_counter: %d", encoder_pixel_counter);

                end

            end

            umapper_lagger_2 = 0;
        end


    end

end

