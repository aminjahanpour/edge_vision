
// UMapper DECODER
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################

/*
the issue is that the last block of the row prints one extra pixel traspassing into the next block
the extra pixel is actually the decoder_end_pixel_address

*/

reg                 [5: 0]                              decoder_stage               ;

localparam          [5: 0]                              decoder_stage_controller     = 0;
localparam          [5: 0]                              decoder_stage_worker         = 1;
localparam          [5: 0]                              decoder_stage_finished       = 2;


reg                 [laggers_len - 1 : 0]               decoder_lagger_1;
reg                 [laggers_len - 1 : 0]               decoder_lagger_2;

reg                 [q_full - 1 : 0]                    decoder_start_pixel_address;
reg                 [q_full - 1 : 0]                    decoder_end_pixel_address;


reg                 [q_full - 1 : 0]                    decoder_block_position;
reg                 [q_full - 1 : 0]                    decoder_block_row;
reg                 [q_full - 1 : 0]                    decoder_block_col;

reg                 [q_full - 1 : 0]                    decoder_pixel_block_column_counter;
reg                 [q_full - 1 : 0]                    decoder_pixel_block_counter;
reg                 [q_full - 1 : 0]                    decoder_total_pixel_counter;
reg                 [q_full - 1 : 0]                    decoder_aeb_counter;

reg                 [q_full - 1 : 0]                    decoder_pixel_counter;
reg                 [q_full - 1 : 0]                    decoder_block_counter;


reg                 [q_full - 1 : 0]                    decoder_r_full_q;
reg                 [q_full - 1 : 0]                    decoder_g_full_q;
reg                 [q_full - 1 : 0]                    decoder_b_full_q;
reg                 [q_full - 1 : 0]                    decoder_gray_full_q;



// Counting the Blocks
always @(negedge clk) begin

    if (decoder_stage == decoder_stage_controller) begin
        
        // $display("decoder_lagger_1:%d, block_counter:%d",decoder_lagger_1, block_counter);
        decoder_lagger_1 = decoder_lagger_1 + 1;

        if (decoder_lagger_1 == 1)  begin

            // Is the block among the most significant ones?
            if (most_significant_block_idxs[decoder_block_counter] == 1'b1) begin

                decoder_block_position      = nt_aeb.mult_hp(decoder_block_counter, one_over_crop_count);
                decoder_block_row           = decoder_block_position >> q_half;
                decoder_block_col           = nt_aeb.mult( (decoder_block_position & nt_aeb.floating_part_mask) , full_q_crop_count) >> q_half;

                // these addresses are inclusive
                decoder_start_pixel_address = (decoder_block_row * block_width * block_height * crop_count) + decoder_block_col * block_width;
                decoder_end_pixel_address = (decoder_block_row * crop_count * block_height * block_width) + ((block_height-1) * crop_count * block_width)+ ((decoder_block_col + 1) * block_width);

                decoder_pixel_counter = decoder_start_pixel_address;
                decoder_pixel_block_column_counter = 0;
                decoder_pixel_block_counter = 0;

                $display("DECODER Controller: ---------------block counter %d, block_global_row:%d, block_global_col:%d, decoder_start_pixel_address:%d, decoder_end_pixel_address:%d",
                 decoder_block_counter,
                 decoder_block_row,
                 decoder_block_col,
                 decoder_start_pixel_address,
                 decoder_end_pixel_address
                 );

                decoder_stage = decoder_stage_worker;

            end




        end else if (decoder_lagger_1 == 2)  begin

            if (decoder_block_counter == ((crop_count * crop_count) - 1)) begin
                decoder_stage = decoder_stage_finished;
                $display("DECODER: finished decoding %d pixels", decoder_total_pixel_counter);
                

                // $display("dumping..");
                // pixel_reader_lag_counter_decoder_dumper = 0;
                // decoder_pixel_counter = 0;
                // dump_aeb_frame_to_file_flag = 1;

                // $display("DECODER: starting to decode..");
                // umapper_decoder_active_flag = 1;
                dump_decoded_rgb_to_file_flag = 1;

                pixel_reader_lag_counter_decoder_dumper = 0;

            end else begin
                decoder_block_counter = decoder_block_counter + 1;

            end

            decoder_lagger_1 = 0;

        end

    end

end




// UMapper Decoding the Block
always @(negedge clk) begin

    if (decoder_stage == decoder_stage_worker) begin

        decoder_lagger_2 = decoder_lagger_2 + 1;

        if (decoder_lagger_2 == 1) begin
            aeb_frame_mem_read_addr = decoder_aeb_counter; // this should be a counter on the aeb pixels
            decoded_frame_rgb_mem_write_addr = decoder_pixel_counter; // this counter scans the block row by row


        end else if (decoder_lagger_2 == 3) begin


            // $display("decoder_aeb_counter:%d, decoder_pixel_counter:%d, aeb_frame_mem_read_data:%b, decoder_gray_full_q:%d",
            //  decoder_aeb_counter, 
            //  decoder_pixel_counter,
            //  aeb_frame_mem_read_data,
            //  decoder_gray_full_q
            //  );
            

            if (color_system == 0) begin

                // $display("decoder_aeb_counter: %d, aeb_frame_mem_read_data: %b", decoder_aeb_counter, aeb_frame_mem_read_data);

                decoder_r_full_q = aeb_frame_mem_read_data & r_mask;
                decoder_g_full_q = aeb_frame_mem_read_data & g_mask;
                decoder_b_full_q = aeb_frame_mem_read_data & b_mask;

                decoder_r_full_q = decoder_r_full_q >> (bpu_g + bpu_b);
                decoder_g_full_q = decoder_g_full_q >> bpu_b;

                // $display("decoder_r_full_q:%d, decoder_g_full_q:%d, decoder_b_full_q:%d", decoder_r_full_q, decoder_g_full_q, decoder_b_full_q);
                // $display("decoder_r_full_q:%d, red_base_points:%b", decoder_r_full_q, red_base_points);

                decoder_r_full_q = nt_aeb.aeb_to_basepoint(red_base_points, decoder_r_full_q);
                decoder_g_full_q = nt_aeb.aeb_to_basepoint(green_base_points, decoder_g_full_q);
                decoder_b_full_q = nt_aeb.aeb_to_basepoint(blue_base_points, decoder_b_full_q);

                // $display("extracted ----------decoder_r_full_q:%b, decoder_g_full_q:%d, decoder_b_full_q:%d", decoder_r_full_q, decoder_g_full_q, decoder_b_full_q);

                decoded_frame_rgb_mem_write_data =   (decoder_r_full_q << 16) + (decoder_g_full_q << 8) + (decoder_b_full_q);
                // decoded_frame_rgb_mem_write_data =   aeb_frame_mem_read_data;
                
                // $display("decoded_frame_rgb_mem_write_data:%d", decoded_frame_rgb_mem_write_data);
            end else if (color_system == 3) begin

                decoder_gray_full_q = aeb_frame_mem_read_data;
                // $display("ud_encoded_pixel_counter: %d, aeb_frame_mem_read_data: %b : %d", ud_encoded_pixel_counter, aeb_frame_mem_read_data , aeb_frame_mem_read_data);
                // $display("decoder_aeb_counter:%d, write_addr:%d, aeb_read_data:%b, decoder_gray_full_q:%d",
                // decoder_aeb_counter, 
                // decoder_pixel_counter,
                // aeb_frame_mem_read_data,
                // decoder_gray_full_q
                // );
            
                // $display("gray_base_points: %b", gray_base_points);
                decoder_gray_full_q = nt_aeb.aeb_to_basepoint(gray_base_points, decoder_gray_full_q);
                // $display("ud_encoded_pixel_counter: %d, decoder_gray_full_q: %b", ud_encoded_pixel_counter, decoder_gray_full_q);



                decoded_frame_rgb_mem_write_data =   (decoder_gray_full_q << 16) + (decoder_gray_full_q << 8) + (decoder_gray_full_q);

                // $display("ud_encoded_pixel_counter: %d, decoded_frame_rgb_mem_write_data: %b", ud_encoded_pixel_counter, decoded_frame_rgb_mem_write_data);


            end


        end else if (decoder_lagger_2 == 4) begin
            if (decoder_pixel_block_counter < (block_width * block_height)) begin
                decoded_frame_rgb_mem_write_enable = 1;
            end


        end else if (decoder_lagger_2 == 5) begin
            decoded_frame_rgb_mem_write_enable = 0;


        end else if (decoder_lagger_2 == 6) begin
            // $display("decoder_total_pixel_counter:%d, aeb:%b", decoder_total_pixel_counter, aeb);
            decoder_total_pixel_counter = decoder_total_pixel_counter + 1;


        end else if (decoder_lagger_2 == 7) begin

            if (decoder_pixel_counter == decoder_end_pixel_address) begin
                decoder_stage = decoder_stage_controller;
                decoder_total_pixel_counter = decoder_total_pixel_counter - 1;

                // $display("decoded %d pixels         decoder_total_pixel_counter:", decoder_pixel_block_counter, decoder_total_pixel_counter);

            end else begin
                decoder_pixel_counter = decoder_pixel_counter + 1;
                decoder_pixel_block_counter = decoder_pixel_block_counter + 1;
                decoder_pixel_block_column_counter = decoder_pixel_block_column_counter + 1;

                decoder_aeb_counter = decoder_aeb_counter + 1;

                /*
                    if we have reached the last column of the block we need to skip to the first column
                    of the next row.
                */
                if ((decoder_pixel_block_column_counter == block_width)&&(decoder_pixel_counter < decoder_end_pixel_address)) begin
                    // $display("decoder_pixel_counter: %d skipping to", decoder_pixel_counter);
                    decoder_pixel_block_column_counter = 0;
                    decoder_pixel_counter = decoder_pixel_counter + (crop_count - 1) * block_width;

                    // $display("decoder_pixel_counter: %d", decoder_pixel_counter);

                end

            end

            decoder_lagger_2 = 0;
        
        end


    end

end




reg                 [q_full - 1 : 0]                    pixel_counter_decoder_dumper            = 0;
reg                 [q_full - 1 : 0]                    pixel_reader_lag_counter_decoder_dumper    = 0;

always @(negedge clk) begin
    if (dump_decoded_rgb_to_file_flag == 1) begin
        pixel_reader_lag_counter_decoder_dumper = pixel_reader_lag_counter_decoder_dumper + 1;

        if (pixel_reader_lag_counter_decoder_dumper == 1) begin
            decoded_frame_rgb_mem_read_addr = pixel_counter_decoder_dumper;
            
        end else if (pixel_reader_lag_counter_decoder_dumper == 2) begin
            $fdisplayb(output_file_decoded_rgb, decoded_frame_rgb_mem_read_data);     // Displays in binary  

            // if (decoded_frame_rgb_mem_read_data > 0) begin
                // $display("dumper pixel_counter_decoder_dumper:%d, data: %b",pixel_counter_decoder_dumper, decoded_frame_rgb_mem_read_data);
            // end

        end else if (pixel_reader_lag_counter_decoder_dumper == 3) begin

            if (pixel_counter_decoder_dumper < (width * height - 1)) begin
                pixel_counter_decoder_dumper = pixel_counter_decoder_dumper + 1;

            end else begin
                pixel_counter_decoder_dumper = 0;
                dump_decoded_rgb_to_file_flag = 0;





                $fclose(output_file_decoded_rgb);  
                $display("dumping output_file_decoded_rgb.txt");
                $display("FINISHED ________________ at %d", $time);
            end

            pixel_reader_lag_counter_decoder_dumper = 0;

        end 
    end
end



