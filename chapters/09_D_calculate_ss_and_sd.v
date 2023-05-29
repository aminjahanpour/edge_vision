// FIND SS and SD
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################


reg                 [laggers_len - 1 : 0]               lagger_D0;
reg                 [q_full - 1 : 0]                    block_counter_D0;
reg                 [q_full - 1 : 0]                    all_blocks_hue_counter_D0;
reg                 [q_full - 1 : 0]                    hue_counter_D0;


reg                 [laggers_len - 1 : 0]               lagger_D1;
reg                 [q_full - 1 : 0]                    counter_D1;


reg                 [laggers_len - 1 : 0]               lagger_D2;
reg                 [q_full - 1 : 0]                    all_blocks_hue_counter_D2;
reg                 [q_full - 1 : 0]                    hue_counter_D2;
reg                 [q_full - 1 : 0]                    block_counter_D2;


reg                 [laggers_len - 1 : 0]               lagger_D3;
reg                 [q_full - 1 : 0]                    counter_D3;


reg                 [laggers_len - 1 : 0]               lagger_D4;
reg                 [q_full - 1 : 0]                    counter_D4;

reg                 [q_full - 1 : 0]                    demeaned                           ;
reg                 [q_full - 1 : 0]                    hue_full_q                           ;

reg                 [q_full - 1 : 0]                    ss_sum                          ;
reg                 [q_full - 1 : 0]                    var_sum                         ;
reg                 [q_full - 1 : 0]                    ss_sum_counter                  ;






// Division D1
reg                                                     division_D1_start=0;
wire                                                    division_D1_busy;
wire                                                    division_D1_valid;
wire                                                    division_D1_dbz;
wire                                                    division_D1_ovf;
reg                         [q_full - 1 : 0]            division_D1_x;
reg                         [q_full - 1 : 0]            division_D1_y;
wire                        [q_full - 1 : 0]            division_D1_q;
wire                        [q_full - 1 : 0]            division_D1_r;

division #(
    .width(q_full),
    .floating_bits(q_half)
    ) division_D1 (
        .clk(   clk),
        .start( division_D1_start),
        .busy(  division_D1_busy),
        .valid( division_D1_valid),
        .dbz(   division_D1_dbz),
        .ovf(   division_D1_ovf),
        .x(     division_D1_x),
        .y(     division_D1_y),
        .q(     division_D1_q),
        .r(     division_D1_r)
    );


always @(negedge division_D1_busy) begin
    calculate_xb_mem_flag = 1;


    if ((division_D1_valid == 0) || (division_D1_ovf == 1)) begin
        $display("!!! diviosn error at D1");

        $display("%d:\t%f \t/ \t%f \t= \t(%f)\t\t(V=%b) (DBZ=%b) (OVF=%b)",
        $time, division_D1_x*SF, division_D1_y*SF, division_D1_q*SF, 
        division_D1_valid, division_D1_dbz, division_D1_ovf);

        $display("%d:\t%b \t/ \t%b \t= \t(%b)\t\t(V=%b) (DBZ=%b) (OVF=%b)",
        $time, division_D1_x, division_D1_y, division_D1_q, 
        division_D1_valid, division_D1_dbz, division_D1_ovf);
    end

end








// Division D3
reg                                                     division_D3_start=0;
wire                                                    division_D3_busy;
wire                                                    division_D3_valid;
wire                                                    division_D3_dbz;
wire                                                    division_D3_ovf;
reg                         [q_full - 1 : 0]            division_D3_x;
reg                         [q_full - 1 : 0]            division_D3_y;
wire                        [q_full - 1 : 0]            division_D3_q;
wire                        [q_full - 1 : 0]            division_D3_r;

division #(
    .width(q_full),
    .floating_bits(q_half)
    ) division_D3 (
        .clk(   clk),
        .start( division_D3_start),
        .busy(  division_D3_busy),
        .valid( division_D3_valid),
        .dbz(   division_D3_dbz),
        .ovf(   division_D3_ovf),
        .x(     division_D3_x),
        .y(     division_D3_y),
        .q(     division_D3_q),
        .r(     division_D3_r)
    );


always @(negedge division_D3_busy) begin
    calculate_var_flag = 1;


    if ((division_D3_valid == 0) || (division_D3_ovf == 1)) begin
        $display("!!! diviosn error at D3");

        $display("%d:\t%f \t/ \t%f \t= \t(%f)\t\t(V=%b) (DBZ=%b) (OVF=%b)",
        $time, division_D3_x*SF, division_D3_y*SF, division_D3_q*SF, 
        division_D3_valid, division_D3_dbz, division_D3_ovf);

        $display("%d:\t%b \t/ \t%b \t= \t(%b)\t\t(V=%b) (DBZ=%b) (OVF=%b)",
        $time, division_D3_x, division_D3_y, division_D3_q, 
        division_D3_valid, division_D3_dbz, division_D3_ovf);
    end

end



/*
goes through all union_mag in  hue_hist_blocks_mem
figures out the right hue_color_range based on the hue value
generates:
s,
ss,
sh
rams
*/
//D0
// process_union_mag_per_hue_color_range_for_all_blocks_flag
always @(negedge clk) begin
    if (process_union_mag_per_hue_color_range_for_all_blocks_flag == 1) begin
        
        lagger_D0 = lagger_D0 + 1;


        if (lagger_D0 == 1) begin
            hue_hist_blocks_mem_read_addr = all_blocks_hue_counter_D0; // this is the union_mag



        end else if (lagger_D0 == 2) begin


            if (hue_counter_D0 < 20) begin
                ss_ram_read_addr = (block_counter_D0 * hue_color_range_count) + 0;

            end else if ((20 <= hue_counter_D0) && (hue_counter_D0 < 35)) begin
                ss_ram_read_addr = (block_counter_D0 * hue_color_range_count) + 1;

            end else if ((35 <= hue_counter_D0) && (hue_counter_D0 < 80)) begin
                ss_ram_read_addr = (block_counter_D0 * hue_color_range_count) + 2;

            end else if ((80 <= hue_counter_D0) && (hue_counter_D0 < 132)) begin
                ss_ram_read_addr = (block_counter_D0 * hue_color_range_count) + 3;

            end else if ((132 <= hue_counter_D0) && (hue_counter_D0 < 160)) begin
                ss_ram_read_addr = (block_counter_D0 * hue_color_range_count) + 4;

            end else if (160 <= hue_counter_D0) begin
                ss_ram_read_addr = (block_counter_D0 * hue_color_range_count) + 5;

            end

            ss_ram_write_addr = ss_ram_read_addr;
            sh_ram_read_addr = ss_ram_read_addr;
            sh_ram_write_addr = ss_ram_read_addr;
            s_ram_read_addr = ss_ram_read_addr;
            s_ram_write_addr = ss_ram_read_addr;


        end else if (lagger_D0 == 3) begin

            // to avoid lossing floating precision, here we multiply the union_mag by thousand, before squaring it 
            ss_ram_write_data = ss_ram_read_data + nt_aeb.mult(
                hue_hist_blocks_mem_read_data , 
                hue_hist_blocks_mem_read_data
            );


            hue_full_q = hue_counter_D0 << q_half;
            sh_ram_write_data = sh_ram_read_data + nt_aeb.mult(
                hue_hist_blocks_mem_read_data,
                hue_full_q
            );


            s_ram_write_data = s_ram_read_data +
                hue_hist_blocks_mem_read_data ;



        end else if (lagger_D0 == 4) begin
            ss_ram_write_enable = 1;
            sh_ram_write_enable = 1;
            s_ram_write_enable = 1;


        end else if (lagger_D0 == 5) begin
            ss_ram_write_enable = 0;
            sh_ram_write_enable = 0;
            s_ram_write_enable = 0;


        // end else if (lagger_D0 == 6) begin

            // $display("block_counter_D0:%d, hue_counter_D0: %d, hue_hist_blocks_mem_read_addr:%d, hue_hist_blocks_mem_read_data:%f, ss_addr:%d, ss_write_data:%f",
            //           block_counter_D0,    hue_counter_D0,  
            //              hue_hist_blocks_mem_read_addr    
            //           ,SF*hue_hist_blocks_mem_read_data
            //           ,ss_ram_read_addr, 
            //           SF*ss_ram_write_data);


        end else if (lagger_D0 == 8) begin

            if (all_blocks_hue_counter_D0 < (full_hue_range * crop_count * crop_count) - 1) begin

                all_blocks_hue_counter_D0 = all_blocks_hue_counter_D0 + 1;

                hue_counter_D0 = hue_counter_D0 + 1;

                if (hue_counter_D0 == full_hue_range) begin
                    hue_counter_D0 = 0;
                    block_counter_D0 = block_counter_D0 + 1;
                end


            end else begin
                all_blocks_hue_counter_D0 = 0;
                process_union_mag_per_hue_color_range_for_all_blocks_flag = 0;

                $display("D0: finished process_union_mag_per_hue_color_range_for_all_blocks_flag...");
                $display("D0: loaded S, SS, SH rams.");
                $display("D0: going to generate XB ram");
                // dump_ss_mem_to_file_flag = 1;

                calculate_xb_mem_flag = 1;
            end


            lagger_D0 = 0;

        end 

    end
end




/*
goes through all hue_color_range_count for each block
reads s, sh and calculates xb = sh /s
*/
// D1
// calculating XB ram
always @(negedge clk) begin
    if(calculate_xb_mem_flag == 1) begin

        lagger_D1 = lagger_D1 + 1;

            
        if (lagger_D1 == 1) begin
            sh_ram_read_addr        = counter_D1;
            s_ram_read_addr         = counter_D1;
            xb_ram_write_addr       = counter_D1;


        end else if (lagger_D1 == 2) begin

            division_D1_x = sh_ram_read_data;
            division_D1_y = s_ram_read_data;

            // $display("%b / %b", division_D1_x, division_D1_y);

        end else if (lagger_D1 == 3) begin

            if (division_D1_y != 0) begin
                division_D1_start = 1;
                calculate_xb_mem_flag = 0;
            end else begin
                xb_ram_write_data = 0;
            end

        end else if (lagger_D1 == 5) begin

            if (division_D1_y != 0) begin
                division_D1_start = 0;
                xb_ram_write_data = division_D1_q;
            end


        end else if (lagger_D1 == 6) begin
            if (division_D1_y != 0) begin
                xb_ram_write_enable = 1;
            end

        end else if (lagger_D1 == 7) begin
            xb_ram_write_enable = 0;



        end else if (lagger_D1 == 8) begin

            if (counter_D1 < (hue_color_range_count * crop_count * crop_count) - 1) begin

                counter_D1 = counter_D1 + 1;


            end else begin
                counter_D1 = 0;

                calculate_xb_mem_flag = 0;
                $display("D1: finished calculate_xb_mem_flag");


                $display("D1: starting to calculate_var_nominator_flag");  
                calculate_var_nominator_flag = 1;
                // hue_counter=0;
                lagger_D1 = 0;
                // all_blocks_hue_counter = 0;


                // $display("starting to dump_ss_mem_to_file_flag");  
                // dump_ss_mem_to_file_flag = 1;
            end


            lagger_D1 = 0;

        end 



    end
end

/*
goes through all union_mag in  hue_hist_blocks_mem
similar to the firt loop over union mag
but now we have all we need to calculate the variance
again here we figure out the right hue_color_range based on the hue value
the we populate var ram
*/
//D2
// calculate_var_nominator_flag
always @(negedge clk) begin
    if (calculate_var_nominator_flag == 1) begin
        
        lagger_D2 = lagger_D2 + 1;


        if (lagger_D2 == 1) begin
            hue_hist_blocks_mem_read_addr = all_blocks_hue_counter_D2; // this is the union_mag


        end else if (lagger_D2 == 2) begin


            if (hue_counter_D2 < 20) begin
                var_ram_read_addr = (block_counter_D2 * hue_color_range_count) + 0;

            end else if ((20 <= hue_counter_D2) && (hue_counter_D2 < 35)) begin
                var_ram_read_addr = (block_counter_D2 * hue_color_range_count) + 1;

            end else if ((35 <= hue_counter_D2) && (hue_counter_D2 < 80)) begin
                var_ram_read_addr = (block_counter_D2 * hue_color_range_count) + 2;

            end else if ((80 <= hue_counter_D2) && (hue_counter_D2 < 132)) begin
                var_ram_read_addr = (block_counter_D2 * hue_color_range_count) + 3;

            end else if ((132 <= hue_counter_D2) && (hue_counter_D2 < 160)) begin
                var_ram_read_addr = (block_counter_D2 * hue_color_range_count) + 4;

            end else if (160 <= hue_counter_D2) begin
                var_ram_read_addr = (block_counter_D2 * hue_color_range_count) + 5;

            end

            var_ram_write_addr = var_ram_read_addr;
            xb_ram_read_addr   = var_ram_read_addr;
            s_ram_read_addr    = var_ram_read_addr;

        end else if (lagger_D2 == 3) begin

            // to avoid lossing floating precision, here we multiply the union_mag by thousand, before squaring it 
            
            hue_full_q = hue_counter_D2 << q_half;

            hue_full_q = hue_full_q;

            if(hue_full_q > xb_ram_read_data) begin
                demeaned = hue_full_q - xb_ram_read_data;
            end else begin
                demeaned = xb_ram_read_data - hue_full_q;
            end

        end else if (lagger_D2 == 4) begin

            demeaned = nt_aeb.mult(demeaned, demeaned);

        end else if (lagger_D2 == 5) begin

            demeaned = nt_aeb.mult(hue_hist_blocks_mem_read_data, demeaned);


        end else if (lagger_D2 == 6) begin
            var_ram_write_data = var_ram_read_data + demeaned; 


        end else if (lagger_D2 == 9) begin
            var_ram_write_enable = 1;


        end else if (lagger_D2 == 10) begin
            var_ram_write_enable = 0;


        // end else if (lagger_D2 == 11) begin

            // $display("block_counter_D2:%d, hue_counter_D2: %d, hue_hist_blocks_mem_read_addr:%d, hue_hist_blocks_mem_read_data:%f, ss_addr:%d, ss_write_data:%f",
            //           block_counter_D2,    hue_counter_D2,  
            //              hue_hist_blocks_mem_read_addr    
            //           ,SF*hue_hist_blocks_mem_read_data
            //           ,ss_ram_read_addr, 
            //           SF*ss_ram_write_data);


        end else if (lagger_D2 == 12) begin

            if (all_blocks_hue_counter_D2 < (full_hue_range * crop_count * crop_count) - 1) begin

                all_blocks_hue_counter_D2 = all_blocks_hue_counter_D2 + 1;

                hue_counter_D2 = hue_counter_D2 + 1;

                if (hue_counter_D2 == full_hue_range) begin
                    hue_counter_D2 = 0;
                    block_counter_D2 = block_counter_D2 + 1;
                end


            end else begin
                all_blocks_hue_counter_D2 = 0;
                calculate_var_nominator_flag = 0;
                lagger_D2 = 0;

                $display("D2: finished calculate_var_nominator_flag...");

                // $display("starting to dump_ss_mem_to_file_flag");  
                // dump_ss_mem_to_file_flag = 1;

                $display("D2: going ahead with calculate_var_flag...");
                calculate_var_flag = 1;
            end


            lagger_D2 = 0;

        end 

    end
end








/*
we have the var_nominator already
here we to devide it by sigma ss
*/
// D3
// calculating var
always @(negedge clk) begin
    if(calculate_var_flag == 1) begin

        lagger_D3 = lagger_D3 + 1;

            
        if (lagger_D3 == 1) begin
            var_ram_read_addr       = counter_D3;
            var_ram_write_addr      = counter_D3;
            s_ram_read_addr         = counter_D3;


        end else if (lagger_D3 == 2) begin

            division_D3_x = var_ram_read_data;
            division_D3_y = s_ram_read_data;


        end else if (lagger_D3 == 3) begin
            if (division_D3_y != 0) begin
                division_D3_start = 1;
                calculate_var_flag = 0;

            end else begin
                var_ram_write_data = 0;

            end

        end else if (lagger_D3 == 5) begin
            // $display("%b / %b = %b", division_D3_x, division_D3_y, division_D3_q);
            if (division_D3_y != 0) begin
                division_D3_start = 0;
                var_ram_write_data = division_D3_q;
                
            end


        end else if (lagger_D3 == 6) begin
            if (division_D3_y != 0) begin
                var_ram_write_enable = 1;
            end

        end else if (lagger_D3 == 7) begin
            var_ram_write_enable = 0;



        end else if (lagger_D3 == 8) begin

            if (counter_D3 < (hue_color_range_count * crop_count * crop_count) - 1) begin

                counter_D3 = counter_D3 + 1;


            end else begin
                counter_D3 = 0;

                calculate_var_flag = 0;
                $display("D3: finished calculate_var_flag");

                $display("D3: going ahead with populate_ss_sum_and_var_sum_flag...");
                populate_ss_sum_and_var_sum_flag = 1;
                ss_sum_ram_write_addr = 0;
                var_sum_ram_write_addr = 0;

                // $display("starting to dump_ss_mem_to_file_flag");  
                // dump_ss_mem_to_file_flag = 1;
            end


            lagger_D3 = 0;

        end 



    end
end





// populate_ss_sum_and_var_sum_flag
//D4
always @(negedge clk) begin
    if (populate_ss_sum_and_var_sum_flag == 1) begin
        
        lagger_D4 = lagger_D4 + 1;

        if (lagger_D4 == 1) begin
            ss_ram_read_addr        = counter_D4;
            var_ram_read_addr       = counter_D4;
            
        end else if (lagger_D4 == 2) begin
            ss_sum = ss_sum + ss_ram_read_data;
            var_sum = var_sum + var_ram_read_data;


        end else if (lagger_D4 == 3) begin
            ss_sum_ram_write_data = ss_sum;
            var_sum_ram_write_data = var_sum;

        end else if (lagger_D4 == 4) begin
            // $display("counter_D4:%d ss_sum: %f\tvar_sum: %f,     %d",counter_D4, SF * ss_sum, SF * var_sum, ss_sum_ram_write_addr);
            
            if ((ss_sum_counter == hue_color_range_count) || (counter_D4 == ((hue_color_range_count * crop_count * crop_count) - 1))) begin
                $display("D4: ss_sum: %f\tvar_sum: %f", SF * ss_sum, SF * var_sum);
                // $display("----------------------------------------------------------------------------");

                ss_sum_ram_write_enable = 1;
                var_sum_ram_write_enable = 1;

            end


        end else if (lagger_D4 == 5) begin
                ss_sum_ram_write_enable = 0;
                var_sum_ram_write_enable = 0;


        end else if (lagger_D4 == 6) begin

            if (ss_sum_counter == hue_color_range_count) begin

                ss_sum_counter = 0;
                ss_sum_ram_write_addr = ss_sum_ram_write_addr + 1;
                var_sum_ram_write_addr = var_sum_ram_write_addr + 1;
                ss_sum = 0;
                var_sum = 0;
            end


        end else if (lagger_D4 == 7) begin


            if (counter_D4 < (hue_color_range_count * crop_count * crop_count) - 1) begin

                counter_D4 = counter_D4 + 1;

                ss_sum_counter = ss_sum_counter + 1;


            end else begin


                $display("D4: finished populate_ss_sum_and_var_sum_flag... ");
                populate_ss_sum_and_var_sum_flag = 0;



                $display("D4: starting build_nondominated_blocks_bus_flag... ");
                updater_stage = updater_stage_controller;
                counter_D4 = 0;
                ss_sum_counter = 0;

            end


            lagger_D4 = 0;

        end 

    end
end



