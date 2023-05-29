reg                                                     down_sample_c_channels_flag = 0;


reg                 [q_full - 1 : 0]                    counter_L0;
reg                 [laggers_len - 1 : 0]               lagger_L0;

reg                 [q_full - 1 : 0]                    pixel_in_group_counter_L0;
reg                 [q_full - 1 : 0]                    group_counter_L0;

reg                 [q_full - 1 : 0]                    y_full_q_L0;
reg                 [q_full - 1 : 0]                    cb_full_q_L0;
reg                 [q_full - 1 : 0]                    cr_full_q_L0;

reg                 [q_full - 1 : 0]                    cb_sum_L0;
reg                 [q_full - 1 : 0]                    cr_sum_L0;

reg                                                     over_writting_L0;


// down_sample_c_channels_flag
always @(negedge clk) begin
    if (down_sample_c_channels_flag == 1) begin

        lagger_L0 = lagger_L0 + 1;

        if (lagger_L0 == 1) begin
            two_by_two_grouped_mem_read_addr = counter_L0;

            // $display("counter_L0:%d, next pixel, \t overwriting:%b", counter_L0, over_writting_L0);


        end else if (lagger_L0 == 2) begin
            y_full_q_L0     = (two_by_two_grouped_mem_read_data & full_r_mask) >> 16;
            cb_full_q_L0    = (two_by_two_grouped_mem_read_data & full_g_mask) >> 8;
            cr_full_q_L0    = (two_by_two_grouped_mem_read_data & full_b_mask);

            // $display("counter_L0:%d    \t\t\t\t\t\t reading: cb_sum_L0:%d, cr_sum_L0:%d ", counter_L0, cb_sum_L0, cr_sum_L0);

        end else if (lagger_L0 == 3) begin

            if (over_writting_L0 == 0) begin

                // $display("counter_L0:%d       pixel_in_group_counter_L0:%d         while adding    cb_sum_L0:%d, cr_sum_L0:%d ",counter_L0,pixel_in_group_counter_L0,cb_sum_L0,cr_sum_L0);
                
                if (pixel_in_group_counter_L0 == 3) begin
                    // $display("counter_L0:%d       pixel_in_group_counter_L0:%d         before multed   cb_sum_L0:%d, cr_sum_L0:%d ",counter_L0,pixel_in_group_counter_L0,cb_sum_L0,cr_sum_L0);
                    
                    // $display("\n starting to overwrite ");
                    cb_sum_L0     = cb_sum_L0 + cb_full_q_L0;
                    cr_sum_L0     = cr_sum_L0 + cr_full_q_L0;

                    cb_sum_L0 = nt_aeb.mult(cb_sum_L0 << q_half, nt_aeb.one_over_4);
                    cr_sum_L0 = nt_aeb.mult(cr_sum_L0 << q_half, nt_aeb.one_over_4);

                    cb_sum_L0 = nt_aeb.round_to_int(cb_sum_L0) >> q_half;
                    cr_sum_L0 = nt_aeb.round_to_int(cr_sum_L0) >> q_half;



                    // $display("counter_L0:%d       pixel_in_group_counter_L0:%d       --ov divided      cb_sum_L0:%d, cr_sum_L0:%d\n\n\n ",counter_L0,pixel_in_group_counter_L0,cb_sum_L0,cr_sum_L0);
                
                end else begin
                    cb_sum_L0     = cb_sum_L0 + cb_full_q_L0;
                    cr_sum_L0     = cr_sum_L0 + cr_full_q_L0;


                    // $display("counter_L0:%d       pixel_in_group_counter_L0:%d       --ov collectnig      cb_sum_L0:%d, cr_sum_L0:%d ",counter_L0,pixel_in_group_counter_L0,cb_sum_L0,cr_sum_L0);

                end

            end  


        end else if (lagger_L0 == 4) begin
            if (over_writting_L0 == 1) begin

                two_by_two_grouped_mem_write_addr = counter_L0;
                two_by_two_grouped_mem_write_data = (y_full_q_L0 << 16) + (cb_sum_L0 << 8) + (cr_sum_L0);
                
                // $display("counter_L0:%d                           write_data:%d write_addr:%d", counter_L0, two_by_two_grouped_mem_write_data, two_by_two_grouped_mem_write_addr);

            end


        end else if (lagger_L0 == 5) begin
            if (over_writting_L0 == 1) begin
                two_by_two_grouped_mem_write_enable = 1;
            end


        end else if (lagger_L0 == 6) begin
            if (over_writting_L0 == 1) begin
                two_by_two_grouped_mem_write_enable = 0;
            end


        end else if (lagger_L0 == 7) begin

            if (counter_L0 < (width * height )) begin
                counter_L0 = counter_L0 + 1;

                pixel_in_group_counter_L0 = pixel_in_group_counter_L0 + 1;

                if (pixel_in_group_counter_L0 == 4) begin
                    
                    if (over_writting_L0 == 0) begin
                        over_writting_L0 = 1;
                        counter_L0 = (group_counter_L0 * 4);

                    end else begin
                        over_writting_L0 = 0;
                        cb_sum_L0 = 0;
                        cr_sum_L0 = 0;

                        group_counter_L0 = group_counter_L0 + 1;

                    end

                    pixel_in_group_counter_L0 = 0;

                end


            end else begin
                counter_L0 = 0;

                down_sample_c_channels_flag = 0;
                $display("K0: finished down sampling");


                reshape_two_by_two_to_eight_by_eight = 1;


            end

            lagger_L0 = 0;
            
        end 
    end
end










