reg                                                     convert_source_rgb_to_ycbcr_flag = 0;
reg                                                     dump_two_by_two_grouped_mem_flag = 0;

reg                 [q_full - 1 : 0]                    counter_K0;
reg                 [laggers_len - 1 : 0]               lagger_K0;

reg                 [q_full - 1 : 0]                    r_full_q_K0;
reg                 [q_full - 1 : 0]                    g_full_q_K0;
reg                 [q_full - 1 : 0]                    b_full_q_K0;

reg                 [24 - 1 : 0]                        gray_to_rgb_dump_K0;





reg                 [q_full - 1 : 0]                    group_col_K0      = 0;
reg                 [q_full - 1 : 0]                    group_row_K0      = 0;
reg                 [q_full - 1 : 0]                    pixel_col_counter_K0      = 0;
reg                 [q_full - 1 : 0]                    pixel_row_counter_K0      = 0;




// convert_source_rgb_to_ycbcr_flag
always @(negedge clk) begin
    if (convert_source_rgb_to_ycbcr_flag == 1) begin

        lagger_K0 = lagger_K0 + 1;

        if (lagger_K0 == 1) begin
            source_frame_rgb_mem_read_addr = counter_K0;
            
        end else if (lagger_K0 == 2) begin
            r_full_q_K0 = (source_frame_rgb_mem_read_data & full_r_mask) >> 16;
            g_full_q_K0 = (source_frame_rgb_mem_read_data & full_g_mask) >> 8;
            b_full_q_K0 = (source_frame_rgb_mem_read_data & full_b_mask);




        end else if (lagger_K0 == 4) begin
            source_frame_ycbcr_mem_write_addr     = counter_K0;
            

        end else if (lagger_K0 == 5) begin

            // writing 8-bit gray
            source_frame_ycbcr_mem_write_data = nt_aeb.rgb_to_ycbcr(r_full_q_K0, g_full_q_K0, b_full_q_K0);
            
            // $display("counter_K0:%d   \nsource_frame_rgb_mem_read_data:\n   %b, \n r: %b %d \ng: %b %d\n b: %b %d\n,           gray: %d", 
            // counter_K0, source_frame_rgb_mem_read_data,
            //  r_full_q_K0,r_full_q_K0,
            //   g_full_q_K0,g_full_q_K0,
            //    b_full_q_K0,b_full_q_K0,
            //     source_frame_ycbcr_mem_write_data);
        

            
            // writing the ycbcr to file 
            $fdisplayb(output_file_source_ycbcr_frame, source_frame_ycbcr_mem_write_data);    






        end else if (lagger_K0 == 6) begin
            source_frame_ycbcr_mem_write_enable = 1;


        end else if (lagger_K0 == 7) begin
            source_frame_ycbcr_mem_write_enable = 0;



        // end else if (lagger_K0 == 8) begin

        //     if (pixel_col_counter_K0 == 8) begin
        //         group_col_K0 = group_col_K0 + 1;
        //         pixel_col_counter_K0 = 0;
        //     end


        //     if (group_col_K0 == width_over_eight) begin // that's a row
        //         group_col_K0 = 0;
        //         pixel_row_counter_K0 = pixel_row_counter_K0 + 1;
        //     end

        //     if (pixel_row_counter_K0 == 8) begin
        //         pixel_row_counter_K0 = 0;
        //         group_row_K0 = group_row_K0 + 1;
        //     end



        //     eight_by_eight_grouped_mem_write_addr = 
        //     64 * (group_row_K0 * width_over_eight + group_col_K0)
        //     + pixel_row_counter_K0 * 8 
        //     + pixel_col_counter_K0
            
        //     ;

        //     pixel_col_counter_K0 = pixel_col_counter_K0 + 1;


        // end else if (lagger_K0 == 9) begin
        //     eight_by_eight_grouped_mem_write_data = source_frame_ycbcr_mem_write_data;

        // end else if (lagger_K0 == 10) begin
        //     eight_by_eight_grouped_mem_write_enable = 1;

        // end else if (lagger_K0 == 11) begin
        //     eight_by_eight_grouped_mem_write_enable = 0;



        end else if (lagger_K0 == 8) begin

            if (pixel_col_counter_K0 == 2) begin
                group_col_K0 = group_col_K0 + 1;
                pixel_col_counter_K0 = 0;
            end


            if (group_col_K0 == width_over_two) begin // that's a row
                group_col_K0 = 0;
                pixel_row_counter_K0 = pixel_row_counter_K0 + 1;
            end

            if (pixel_row_counter_K0 == 2) begin
                pixel_row_counter_K0 = 0;
                group_row_K0 = group_row_K0 + 1;
            end



            two_by_two_grouped_mem_write_addr = 
            4 * (group_row_K0 * width_over_two + group_col_K0)
            + pixel_row_counter_K0 * 2 
            + pixel_col_counter_K0
            ;

            pixel_col_counter_K0 = pixel_col_counter_K0 + 1;


        end else if (lagger_K0 == 9) begin
            two_by_two_grouped_mem_write_data = source_frame_ycbcr_mem_write_data;

        end else if (lagger_K0 == 10) begin
            two_by_two_grouped_mem_write_enable = 1;

        end else if (lagger_K0 == 11) begin
            two_by_two_grouped_mem_write_enable = 0;







        end else if (lagger_K0 == 15) begin

            if (counter_K0 < (width * height - 1)) begin
                counter_K0 = counter_K0 + 1;

            end else begin
                counter_K0 = 0;


                convert_source_rgb_to_ycbcr_flag = 0;
                $display("K0: finished converting rgb to ycbcr");

                $fclose(output_file_source_ycbcr_frame);  


                down_sample_c_channels_flag = 1;
                // dump_two_by_two_grouped_mem_flag=  1;

            end

            lagger_K0 = 0;
            
        end 
    end
end













reg                 [q_full - 1 : 0]                    pixel_counter_K            = 0;
reg                 [q_full - 1 : 0]                    pixel_reader_lag_counter_K    = 0;


// dump_two_by_two_grouped_mem_flag
always @(negedge clk) begin
    if (dump_two_by_two_grouped_mem_flag == 1) begin
        pixel_reader_lag_counter_K = pixel_reader_lag_counter_K + 1;

        if (pixel_reader_lag_counter_K == 1) begin
            two_by_two_grouped_mem_read_addr      = pixel_counter_K;


            
        end else if (pixel_reader_lag_counter_K == 2) begin

            $fdisplayb(output_file_two_by_two_grouped, two_by_two_grouped_mem_read_data);     // Displays in binary  

            


        end else if (pixel_reader_lag_counter_K == 3) begin

            if (pixel_counter_K < width * height - 1) begin
                pixel_counter_K = pixel_counter_K + 1;

            end else begin
                pixel_counter_K = 0;
                dump_two_by_two_grouped_mem_flag = 0;

                $fclose(output_file_two_by_two_grouped);  
                $display("dumped output_file_two_by_two_grouped.txt");
                $display("FINISHED_________________________");


            end


            pixel_reader_lag_counter_K = 0;

        end 
    end
end









