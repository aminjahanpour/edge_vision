reg                                                     reshape_two_by_two_to_eight_by_eight = 0;
reg                                                     dump_eight_by_eight_grouped_mem_flag = 0;


reg                 [q_full - 1 : 0]                    counter_M0;
reg                 [laggers_len - 1 : 0]               lagger_M0;

reg                 [q_full - 1 : 0]                    target_address_in_two_by_two_M0;

reg                 [q_full - 1 : 0]                    h_eight_counter_M0;
reg                 [q_full - 1 : 0]                    v_eight_counter_M0;
reg                 [q_full - 1 : 0]                    group_col_idx_M0;
reg                 [q_full - 1 : 0]                    group_row_idx_M0;

reg                 [q_full - 1 : 0]                    anchor_M0;
reg                 [q_full - 1 : 0]                    top_anchor_M0;


reg                 [10: 0]                             steps_horizental_from_anchor_M0 [7: 0]  ;
reg                 [10: 0]                             steps_vertical_from_top_anchor_M0   [7: 0]  ;

// reshape_two_by_two_to_eight_by_eight
always @(negedge clk) begin
    if (reshape_two_by_two_to_eight_by_eight == 1) begin

        lagger_M0 = lagger_M0 + 1;

        if (lagger_M0 == 1) begin

            /*
                figure out address in two_by_two from where you need to read
                the value for counter_M0
            */

            target_address_in_two_by_two_M0 = anchor_M0 + steps_horizental_from_anchor_M0[h_eight_counter_M0];


            // $display(
            //     "counter_M0:%d, (group_col_idx_M0:%d, group_row_idx_M0:%d)  h_eight_counter_M0:%d, v_eight_counter_M0:%d,  top_anchor_M0:%d,  anchor_M0:%d,  addr:%d",
            //     counter_M0,      group_col_idx_M0,    group_row_idx_M0,   h_eight_counter_M0,    v_eight_counter_M0,           top_anchor_M0,     anchor_M0,     target_address_in_two_by_two_M0
            //  );


        end else if (lagger_M0 == 2) begin
            two_by_two_grouped_mem_read_addr = target_address_in_two_by_two_M0;

            eight_by_eight_grouped_mem_write_addr = counter_M0;


        end else if (lagger_M0 == 3) begin
            eight_by_eight_grouped_mem_write_data = two_by_two_grouped_mem_read_data;
                

        end else if (lagger_M0 == 4) begin
            eight_by_eight_grouped_mem_write_enable = 1;


        end else if (lagger_M0 == 5) begin
            eight_by_eight_grouped_mem_write_enable = 0;


        end else if (lagger_M0 == 6) begin

            if (counter_M0 < (width * height -1)) begin
                counter_M0 = counter_M0 + 1;

                h_eight_counter_M0 = h_eight_counter_M0 + 1;

                if (h_eight_counter_M0 == 8) begin
                    h_eight_counter_M0 = 0;
                    v_eight_counter_M0 = v_eight_counter_M0 + 1; 

                end

                if (v_eight_counter_M0 == 8)begin
                    group_col_idx_M0 = group_col_idx_M0 + 1;
                    v_eight_counter_M0 = 0;

                    // $display("NEXT GROUP");

                end 

                if (group_col_idx_M0 == width_over_eight) begin
                    group_row_idx_M0 = group_row_idx_M0 + 1;
                    group_col_idx_M0 = 0;

                end


                top_anchor_M0 =  8 * width * group_row_idx_M0 + 16 * group_col_idx_M0;

                anchor_M0 = top_anchor_M0 + steps_vertical_from_top_anchor_M0[v_eight_counter_M0];


            end else begin
                counter_M0 = 0;

                reshape_two_by_two_to_eight_by_eight = 0;
                $display("K0: finished down sampling");


                dump_eight_by_eight_grouped_mem_flag = 1;


            end

            lagger_M0 = 0;
            
        end 
    end
end













reg                 [q_full - 1 : 0]                    pixel_counter_M            = 0;
reg                 [q_full - 1 : 0]                    pixel_reader_lag_counter_M    = 0;


// dump_eight_by_eight_grouped_mem_flag
always @(negedge clk) begin
    if (dump_eight_by_eight_grouped_mem_flag == 1) begin
        pixel_reader_lag_counter_M = pixel_reader_lag_counter_M + 1;

        if (pixel_reader_lag_counter_M == 1) begin
            eight_by_eight_grouped_mem_read_addr      = pixel_counter_M;


            
        end else if (pixel_reader_lag_counter_M == 2) begin

            $fdisplayb(output_file_eight_by_eight_grouped, eight_by_eight_grouped_mem_read_data);     // Displays in binary  

            


        end else if (pixel_reader_lag_counter_M == 3) begin

            if (pixel_counter_M < width * height - 1) begin
                pixel_counter_M = pixel_counter_M + 1;

            end else begin
                pixel_counter_M = 0;
                dump_eight_by_eight_grouped_mem_flag = 0;

                $fclose(output_file_eight_by_eight_grouped);  
                $display("dumped output_file_eight_by_eight_grouped.txt");


                $display("going ahead with generate_dct_frame_flag");
                generate_dct_frame_flag = 1;


            end


            pixel_reader_lag_counter_M = 0;

        end 
    end
end









