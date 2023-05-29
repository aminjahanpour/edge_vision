

reg                 [laggers_len - 1 : 0]               lagger_E2;
reg                 [q_full - 1 : 0]                    counter_E2;

reg                 [laggers_len - 1 : 0]               lagger_E3;


reg                 [laggers_len - 1 : 0]               lagger_E4;
reg                 [q_full - 1 : 0]                    counter_E4;


reg                 [laggers_len - 1 : 0]               lagger_E5;
reg                 [q_full - 1 : 0]                    counter_E5;


reg                 [q_full - 1 : 0]                    remaining_pixels_count_red_hist;
reg                 [q_full - 1 : 0]                    remaining_pixels_count_green_hist;
reg                 [q_full - 1 : 0]                    remaining_pixels_count_blue_hist;
reg                 [q_full - 1 : 0]                    remaining_pixels_count_gray_hist;

reg                 [q_full - 1 : 0]                    basepoint_cap_red;
reg                 [q_full - 1 : 0]                    basepoint_cap_green;
reg                 [q_full - 1 : 0]                    basepoint_cap_blue;
reg                 [q_full - 1 : 0]                    basepoint_cap_gray;

reg                 [full_color_range - 1 : 0]          red_base_points;
reg                 [full_color_range - 1 : 0]          green_base_points;
reg                 [full_color_range - 1 : 0]          blue_base_points;
reg                 [full_color_range - 1 : 0]          gray_base_points;

reg                 [q_full - 1 : 0]                    red_hist_cum_var;
reg                 [q_full - 1 : 0]                    green_hist_cum_var;
reg                 [q_full - 1 : 0]                    blue_hist_cum_var;
reg                 [q_full - 1 : 0]                    gray_hist_cum_var;

reg                 [q_full - 1 : 0]                    max_base_point_count_red;
reg                 [q_full - 1 : 0]                    max_base_point_count_green;
reg                 [q_full - 1 : 0]                    max_base_point_count_blue;
reg                 [q_full - 1 : 0]                    max_base_point_count_gray;


reg                 [q_full - 1 : 0]                    base_point_count_red;
reg                 [q_full - 1 : 0]                    base_point_count_green;
reg                 [q_full - 1 : 0]                    base_point_count_blue;
reg                 [q_full - 1 : 0]                    base_point_count_gray;



// Division E3
reg                                                     division_E3_start=0;
wire                                                    division_E3_busy;
wire                                                    division_E3_valid;
wire                                                    division_E3_dbz;
wire                                                    division_E3_ovf;
reg                         [q_full - 1 : 0]            division_E3_x;
reg                         [q_full - 1 : 0]            division_E3_y;
wire                        [q_full - 1 : 0]            division_E3_q;
wire                        [q_full - 1 : 0]            division_E3_r;

division #(
    .width(q_full),
    .floating_bits(q_half)
    ) division_E3 (
        .clk(   clk),
        .start( division_E3_start),
        .busy(  division_E3_busy),
        .valid( division_E3_valid),
        .dbz(   division_E3_dbz),
        .ovf(   division_E3_ovf),
        .x(     division_E3_x),
        .y(     division_E3_y),
        .q(     division_E3_q),
        .r(     division_E3_r)
    );


always @(negedge division_E3_busy) begin
    get_base_points_caps_flag = 1;


    if ((division_E3_valid == 0) || (division_E3_ovf == 1)) begin
        $display("!!! diviosn error at E3");
        $display("%d:\t%f \t/ \t%f \t= \t(%f)\t\t(V=%b) (DBZ=%b) (OVF=%b)",
        $time, division_E3_x*SF, division_E3_y*SF, division_E3_q*SF, 
        division_E3_valid, division_E3_dbz, division_E3_ovf);

        $display("%d:\t%b \t/ \t%b \t= \t(%b)\t\t(V=%b) (DBZ=%b) (OVF=%b)",
        $time, division_E3_x, division_E3_y, division_E3_q, 
        division_E3_valid, division_E3_dbz, division_E3_ovf);
    end

end




// get_remaining_pixels_count_for_rgb_hists_flag
//E2
always @(negedge clk) begin
    if (get_remaining_pixels_count_for_rgb_hists_flag == 1) begin

        lagger_E2 = lagger_E2 + 1;

        if (lagger_E2 == 1) begin

            if (color_system == 0) begin
                red_hist_full_frame_masked_ram_read_addr    = counter_E2;
                green_hist_full_frame_masked_ram_read_addr  = counter_E2;
                blue_hist_full_frame_masked_ram_read_addr   = counter_E2;

            end else if (color_system == 3) begin
                gray_hist_full_frame_masked_ram_read_addr   = counter_E2;

            end

            
        end else if (lagger_E2 == 2) begin
            if (color_system == 0) begin
                // $display("%b", red_hist_full_frame_masked_ram_read_data);
                remaining_pixels_count_red_hist =   remaining_pixels_count_red_hist     + red_hist_full_frame_masked_ram_read_data;
                remaining_pixels_count_green_hist = remaining_pixels_count_green_hist   + green_hist_full_frame_masked_ram_read_data;
                remaining_pixels_count_blue_hist =  remaining_pixels_count_blue_hist    + blue_hist_full_frame_masked_ram_read_data;


            end else if (color_system == 3) begin
                remaining_pixels_count_gray_hist =  remaining_pixels_count_gray_hist    + gray_hist_full_frame_masked_ram_read_data;

            end


        end else if (lagger_E2 == 3) begin
            if (color_system == 0) begin
                $fdisplay(output_file_red_hist_full_frame_masked,   red_hist_full_frame_masked_ram_read_data); 
                $fdisplay(output_file_green_hist_full_frame_masked, green_hist_full_frame_masked_ram_read_data);
                $fdisplay(output_file_blue_hist_full_frame_masked,  blue_hist_full_frame_masked_ram_read_data);

            end else if (color_system == 3) begin
                $fdisplay(output_file_gray_hist_full_frame_masked,  gray_hist_full_frame_masked_ram_read_data);

            end


        end else if (lagger_E2 == 4) begin

            if (counter_E2 < full_color_range - 1) begin
                counter_E2 = counter_E2 + 1;

            end else begin
                counter_E2 = 0;
                get_remaining_pixels_count_for_rgb_hists_flag = 0;

                if (color_system == 0) begin
                    $display("E2: remaining_pixels_count_red_hist: %d", remaining_pixels_count_red_hist);
                    $display("E2: remaining_pixels_count_green_hist: %d", remaining_pixels_count_green_hist);
                    $display("E2: remaining_pixels_count_blue_hist: %d", remaining_pixels_count_blue_hist);

                    // $fclose(remaining_pixels_count_red_hist);  
                    // $fclose(remaining_pixels_count_green_hist);  
                    // $fclose(remaining_pixels_count_blue_hist);  




                end else if (color_system == 3) begin
                    $display("E2: remaining_pixels_count_gray_hist: %d", remaining_pixels_count_gray_hist);
                    
                    $fclose(remaining_pixels_count_gray_hist);  

                end
            
                get_base_points_caps_flag = 1;

            end
            lagger_E2 = 0;

        end 
    end
end



// get_base_points_caps_flag
//E3
always @(negedge clk) begin
    if (get_base_points_caps_flag == 1) begin

        lagger_E3 = lagger_E3 + 1;

        if (lagger_E3 == 1) begin

            if (color_system == 0) begin
                division_E3_x = remaining_pixels_count_red_hist << q_half;
                division_E3_y = max_base_point_count_red << q_half;

            end else if (color_system == 3) begin
                division_E3_x = remaining_pixels_count_gray_hist << q_half;
                division_E3_y = max_base_point_count_gray << q_half;

            end

            // $display("x=%f, y=%f", SF * division_E3_x, SF * division_E3_y);

        end else if (lagger_E3 == 2) begin
            division_E3_start = 1;
            get_base_points_caps_flag = 0;

        end else if (lagger_E3 == 3) begin
            division_E3_start = 0;

            if (color_system == 0) begin
                basepoint_cap_red = division_E3_q;
                $display("E3: basepoint_cap_red=%f", SF * basepoint_cap_red);

            end else if (color_system == 3) begin
                basepoint_cap_gray = division_E3_q;
                $display("E3: basepoint_cap_gray=%f", SF * basepoint_cap_gray);

            end





        end else if (lagger_E3 == 4) begin
            if (color_system == 0) begin
                division_E3_x = remaining_pixels_count_green_hist << q_half;
                division_E3_y = max_base_point_count_green << q_half;
            end

            // $display("x=%f, y=%f", SF * division_E3_x, SF * division_E3_y);

        end else if (lagger_E3 == 5) begin
            if (color_system == 0) begin
                division_E3_start = 1;
                get_base_points_caps_flag = 0;
            end

        end else if (lagger_E3 == 6) begin
            if (color_system == 0) begin
                division_E3_start = 0;
                basepoint_cap_green = division_E3_q;
                $display("E3: basepoint_cap_green=%f", SF * basepoint_cap_green);
            end


        end else if (lagger_E3 == 7) begin
            if (color_system == 0) begin
                division_E3_x = remaining_pixels_count_blue_hist << q_half;
                division_E3_y = max_base_point_count_blue << q_half;
                // $display("x=%f, y=%f", SF * division_E3_x, SF * division_E3_y);
            end

        end else if (lagger_E3 == 8) begin
            if (color_system == 0) begin
                division_E3_start = 1;
                get_base_points_caps_flag = 0;
            end

        end else if (lagger_E3 == 9) begin
            if (color_system == 0) begin
                division_E3_start = 0;
                basepoint_cap_blue = division_E3_q;
                $display("basepoint_cap_blue=%f", SF * basepoint_cap_blue);
            end



        end else if (lagger_E3 == 10) begin


            $display("E3: finished with basepoint caps");
            $display("E3: going ahead with get_base_points_flag");


            get_base_points_caps_flag = 0;
            get_base_points_flag = 1;

            lagger_E3 = 0;

        end 
    end
end





// get_base_points_flag
//E4
always @(negedge clk) begin
    if (get_base_points_flag == 1) begin

        lagger_E4 = lagger_E4 + 1;

        if (lagger_E4 == 1) begin

            if (color_system == 0) begin
                red_hist_full_frame_masked_ram_read_addr    = counter_E4;
                green_hist_full_frame_masked_ram_read_addr  = counter_E4;
                blue_hist_full_frame_masked_ram_read_addr   = counter_E4;
                
            end else if (color_system == 3) begin
                gray_hist_full_frame_masked_ram_read_addr   = counter_E4;
            end
            
        end else if (lagger_E4 == 2) begin
            if (color_system == 0) begin
                red_hist_cum_var =   red_hist_cum_var     + red_hist_full_frame_masked_ram_read_data;
                green_hist_cum_var = green_hist_cum_var   + green_hist_full_frame_masked_ram_read_data;
                blue_hist_cum_var =  blue_hist_cum_var    + blue_hist_full_frame_masked_ram_read_data;
            
            end else if (color_system == 3) begin
                gray_hist_cum_var =  gray_hist_cum_var    + gray_hist_full_frame_masked_ram_read_data;
            // $display("gray_hist_cum_var=%d", gray_hist_cum_var);

            end


        end else if (lagger_E4 == 4) begin

            // $display ("%d, %d", red_hist_cum_var , (basepoint_cap_red >> q_half));


            if (color_system == 0) begin
                
                if (
                    (red_hist_cum_var >= (basepoint_cap_red >> q_half))
                    &&
                    (base_point_count_red < max_base_point_count_red)
                    &&
                    (remaining_pixels_count_red_hist > 0)
                    ) begin
                    // $display("picked: r %d", counter_E4);

                    red_base_points[counter_E4] = 1'b1;

                    base_point_count_red = base_point_count_red + 1;
                    red_hist_cum_var = 0;
                end 
                
                if (
                    (green_hist_cum_var >= (basepoint_cap_green >> q_half))
                    &&
                    (base_point_count_green < max_base_point_count_green)
                    &&
                    (remaining_pixels_count_green_hist > 0)
                    ) begin
                    // $display("picked: \t\t\t\tg %d", counter_E4);
                   
                    green_base_points[counter_E4] = 1'b1;

                    // green_base_points = green_base_points + (256'd1 << counter_E4);
                    base_point_count_green = base_point_count_green + 1;
                    green_hist_cum_var = 0;
                end 

                if (
                    (blue_hist_cum_var >= (basepoint_cap_blue >> q_half))
                    &&
                    (base_point_count_blue < max_base_point_count_blue)
                    &&
                    (remaining_pixels_count_blue_hist > 0)
                    ) begin
                    // $display("picked: \t\t\t\t\t\t\t\t\t\tb %d", counter_E4);

                    blue_base_points[counter_E4] = 1'b1;

                    // blue_base_points = blue_base_points + (256'd1 << counter_E4);
                    base_point_count_blue = base_point_count_blue + 1;
                    blue_hist_cum_var = 0;
                end 

            end else if (color_system == 3) begin
                
                
                if (
                    (gray_hist_cum_var >= (basepoint_cap_gray >> q_half))
                    &&
                    (base_point_count_gray < max_base_point_count_gray)
                    &&
                    (remaining_pixels_count_gray_hist > 0)
                    ) begin
                    // $display("picked: \t\t\t\t\t\t\t\t\t\tb %d", counter_E4);

                    gray_base_points[counter_E4] = 1'b1;
                    // gray_base_points = gray_base_points + (256'd1 << counter_E4);
                    base_point_count_gray = base_point_count_gray + 1;
                    gray_hist_cum_var = 0;
                end

            end


        end else if (lagger_E4 == 5) begin

            if (counter_E4 < full_color_range - 1) begin
                counter_E4 = counter_E4 + 1;

            end else begin
                counter_E4 = 0;

                if (color_system == 0) begin
                    $display("E4: red_base_points: %b",     red_base_points);
                    $display("E4: base_point_count_red: %d    max_base_point_count_red: %d",     base_point_count_red, max_base_point_count_red);

                    $display("E4: green_base_points: %b",   green_base_points);
                    $display("E4: base_point_count_green: %d    max_base_point_count_green: %d",     base_point_count_green, max_base_point_count_green);


                    $display("E4: blue_base_points: %b",    blue_base_points);
                    $display("E4: base_point_count_blue: %d    max_base_point_count_blue: %d",     base_point_count_blue, max_base_point_count_blue);
                
                end else if (color_system == 3) begin
                    $display("E4: gray_base_points: %b",    gray_base_points);
                    $display("E4: base_point_count_gray: %d    max_base_point_count_gray: %d",     base_point_count_gray, max_base_point_count_gray);
                
                end
                
                get_base_points_flag = 0;

                finalize_base_points_flag = 1;


            end
            lagger_E4 = 0;

        end 
    end
end



/*
there can be certain cases where we may be better off with equally spaced basepoints.
when there are too few pixels (of certain color) is left in the masked frame
for example if there are only 
*/

// finalize_base_points_flag
//E5
always @(negedge clk) begin
    if (finalize_base_points_flag == 1) begin

        lagger_E5 = lagger_E5 + 1;

        if (lagger_E5 == 1) begin

            if (color_system == 0) begin

                if(
                    (base_point_count_red < max_base_point_count_red)
                    &&
                    (red_base_points[counter_E5] == 1'b0)
                    &&
                    (remaining_pixels_count_red_hist > 0)
                ) begin
                    red_base_points = red_base_points + (256'd1 << counter_E5);
                    base_point_count_red = base_point_count_red + 1;
                end

            end else if (color_system == 3) begin


                if(
                    (base_point_count_gray < max_base_point_count_gray)
                    &&
                    (gray_base_points[counter_E5] == 1'b0)
                    &&
                    (remaining_pixels_count_gray_hist > 0)
                ) begin
                    gray_base_points = gray_base_points + (256'd1 << counter_E5);
                    base_point_count_gray = base_point_count_gray + 1;
                end

            end


        end else if (lagger_E5 == 2) begin
            if (color_system == 0) begin

                if(
                    (base_point_count_green < max_base_point_count_green) 
                    &&
                    (green_base_points[counter_E5] == 1'b0)
                    &&
                    (remaining_pixels_count_green_hist > 0)
                ) begin
                    green_base_points = green_base_points + (256'd1 << counter_E5);
                    base_point_count_green = base_point_count_green + 1;
                end
            end
        end else if (lagger_E5 == 3) begin
            if (color_system == 0) begin

                if(
                    (base_point_count_blue < max_base_point_count_blue) 
                    &&
                    (blue_base_points[counter_E5] == 1'b0)
                    &&
                    (remaining_pixels_count_blue_hist > 0)
                ) begin
                    blue_base_points = blue_base_points + (256'd1 << counter_E5);
                    base_point_count_blue = base_point_count_blue + 1;
                end
            end


        end else if (lagger_E5 == 4) begin

            if (counter_E5 < full_color_range - 1) begin
                counter_E5 = counter_E5 + 1;

            end else begin
                counter_E5 = 0;

                if (color_system == 0) begin

                    // the last bit is always 1 because we need to cap the full range with 255
                    red_base_points = red_base_points       | (256'd1 << 255);
                    green_base_points = green_base_points   | (256'd1 << 255);
                    blue_base_points = blue_base_points     | (256'd1 << 255);


                    $display("---------------------------------------------------");
                    $display("E5: red_base_points: %b",     red_base_points);
                    $display("E5: base_point_count_red: %d    max_base_point_count_red: %d",     base_point_count_red, max_base_point_count_red);

                    $display("E5: green_base_points: %b",   green_base_points);
                    $display("E5: base_point_count_green: %d    max_base_point_count_green: %d",     base_point_count_green, max_base_point_count_green);


                    $display("E5: blue_base_points: %b",    blue_base_points);
                    $display("E5: base_point_count_blue: %d    max_base_point_count_blue: %d",     base_point_count_blue, max_base_point_count_blue);
                

                    if (remaining_pixels_count_red_hist == 0) begin
                        red_base_points = 0;
                        base_point_count_red = 0;
                    end
                    if (remaining_pixels_count_green_hist == 0) begin
                        green_base_points = 0;
                        base_point_count_green = 0;
                    end
                    if (remaining_pixels_count_blue_hist == 0) begin
                        blue_base_points = 0;
                        base_point_count_blue = 0;
                    end
                end else if(color_system == 3) begin
                    
                    gray_base_points = gray_base_points       | (256'd1 << 255);



                    $display("E5: gray_base_points: %b",     gray_base_points);
                    $display("E5: base_point_count_gray: %d    max_base_point_count_gray: %d",     base_point_count_gray, max_base_point_count_gray);

                    if (remaining_pixels_count_gray_hist == 0) begin
                        gray_base_points = 0;
                        base_point_count_gray = 0;
                    end

                end

                finalize_base_points_flag = 0;

                um_base_points_are_populated_milestone = 1;

                // umapper_stage =  umapper_stage_controller; // series

            end
            lagger_E5 = 0;

        end 
    end
end


































