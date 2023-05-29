reg                 [q_full - 1 : 0]                    counter_A0;
reg                 [laggers_len - 1 : 0]               lagger_A0;

reg                 [q_full - 1 : 0]                    r_full_q_A0;
reg                 [q_full - 1 : 0]                    g_full_q_A0;
reg                 [q_full - 1 : 0]                    b_full_q_A0;

reg                 [24 - 1 : 0]                        gray_to_rgb_dump_A0;



reg                 [q_full - 1 : 0]                    counter_A1;
reg                 [laggers_len - 1 : 0]               lagger_A1;

reg                 [q_full - 1 : 0]                    r_full_q_A1;
reg                 [q_full - 1 : 0]                    g_full_q_A1;
reg                 [q_full - 1 : 0]                    b_full_q_A1;


reg                 [sum_bpu_full - 1 : 0]              hsv_value_A1;



// RGB to HSV Module
reg                                                     rgb_to_hsv_go;

reg                 [q_full - 1 : 0]                    rgb_to_hsv_r;
reg                 [q_full - 1 : 0]                    rgb_to_hsv_g;
reg                 [q_full - 1 : 0]                    rgb_to_hsv_b;

wire                [q_full - 1 : 0]                    rgb_to_hsv_h;
wire                [q_full - 1 : 0]                    rgb_to_hsv_s;
wire                [q_full - 1 : 0]                    rgb_to_hsv_v;

wire                                                    rgb_to_hsv_finished_flag;


rgb_to_hsv #(
    .q_full(q_full),
    .q_half(q_half),
    .SF(SF),
    .verbose(0)
)
rgb_to_hsv_instance (
    .clk(clk),
    .go(rgb_to_hsv_go),
    .r(rgb_to_hsv_r),
    .g(rgb_to_hsv_g),
    .b(rgb_to_hsv_b),
    .h(rgb_to_hsv_h),
    .s(rgb_to_hsv_s),
    .v(rgb_to_hsv_v),
    .rgb_to_hsv_finished_flag(rgb_to_hsv_finished_flag)
);











// build_um_aux_frame_flag
always @(negedge clk) begin
    if (build_um_aux_frame_flag == 1) begin

        // $display("lagger_A0: %d", lagger_A0);
        lagger_A0 = lagger_A0 + 1;

        if (lagger_A0 == 1) begin
            source_frame_rgb_mem_read_addr = counter_A0;
            
        end else if (lagger_A0 == 2) begin
            r_full_q_A0 = (source_frame_rgb_mem_read_data & full_r_mask) >> 16;
            g_full_q_A0 = (source_frame_rgb_mem_read_data & full_g_mask) >> 8;
            b_full_q_A0 = (source_frame_rgb_mem_read_data & full_b_mask);




        end else if (lagger_A0 == 4) begin

            if (color_system == 0) begin
                masked_rgb_frame_ram_write_addr     = counter_A0;

            end else if (color_system == 3) begin
                masked_gray_frame_ram_write_addr    = counter_A0;
                source_frame_gray_mem_write_addr    = counter_A0;
            end
            

        end else if (lagger_A0 == 5) begin

            if (color_system == 0) begin
                masked_rgb_frame_ram_write_data = source_frame_rgb_mem_read_data;
                
            end else if (color_system == 3) begin

                // writing 8-bit gray
                masked_gray_frame_ram_write_data = nt_aeb.rgb_to_y(r_full_q_A0, g_full_q_A0, b_full_q_A0);
                source_frame_gray_mem_write_data = masked_gray_frame_ram_write_data;
                
                // $display("counter_A0:%d   \nsource_frame_rgb_mem_read_data:\n   %b, \n r: %b %d \ng: %b %d\n b: %b %d\n,           gray: %d", 
                // counter_A0, source_frame_rgb_mem_read_data,
                //  r_full_q_A0,r_full_q_A0,
                //   g_full_q_A0,g_full_q_A0,
                //    b_full_q_A0,b_full_q_A0,
                //     masked_gray_frame_ram_write_data);
            

                gray_to_rgb_dump_A0 = (source_frame_gray_mem_write_data << 16) + (source_frame_gray_mem_write_data << 8) + (source_frame_gray_mem_write_data);
                
                // writing the gray 
                $fdisplayb(output_file_source_gray_frame, gray_to_rgb_dump_A0);     // Displays in binary  


            end



        end else if (lagger_A0 == 6) begin
            if (color_system == 0) begin
                masked_rgb_frame_ram_write_enable = 1;

            end else if (color_system == 3) begin
                masked_gray_frame_ram_write_enable = 1;
                source_frame_gray_mem_write_enable = 1;

            end



        end else if (lagger_A0 == 7) begin
            if (color_system == 0) begin
                masked_rgb_frame_ram_write_enable = 0;

            end else if (color_system == 3) begin
                masked_gray_frame_ram_write_enable = 0;
                source_frame_gray_mem_write_enable = 0;

            end





        end else if (lagger_A0 == 15) begin

            if (counter_A0 < (width * height - 1)) begin
                counter_A0 = counter_A0 + 1;

            end else begin
                // reseting used variables



                counter_A0 = 0;


                build_um_aux_frame_flag = 0;
                $display("A1: finished building aux frame for umapper");

                um_aux_frame_is_populated_milestone          = 1;

                $fclose(output_file_source_gray_frame);  

            end

            lagger_A0 = 0;
            
        end 
    end
end












// rgb_to_hsv_finished_flag collector
always @(posedge rgb_to_hsv_finished_flag) begin
    // $display("pixel counter: %d   rgb(%f,%f,%f) -> hsv(%f,%f,%f)",
    // counter_A1,
    //  SF*rgb_to_hsv_r, SF*rgb_to_hsv_g, SF*rgb_to_hsv_b,
    //  SF*rgb_to_hsv_h, SF*rgb_to_hsv_s, SF*rgb_to_hsv_v
    //  );

     convert_source_rgb_to_hsv_flag = 1;
     rgb_to_hsv_go = 0;
end

// convert_source_rgb_to_hsv_flag
always @(negedge clk) begin
    if (convert_source_rgb_to_hsv_flag == 1) begin

        // $display("lagger_A1: %d", lagger_A1);
        lagger_A1 = lagger_A1 + 1;

        if (lagger_A1 == 1) begin
            source_frame_rgb_mem_read_addr = counter_A1;
            
        end else if (lagger_A1 == 2) begin
            r_full_q_A1 = (source_frame_rgb_mem_read_data & full_r_mask) >> 16;
            g_full_q_A1 = (source_frame_rgb_mem_read_data & full_g_mask) >> 8;
            b_full_q_A1 = (source_frame_rgb_mem_read_data & full_b_mask);


        end else if (lagger_A1 == 3) begin
            rgb_to_hsv_r = r_full_q_A1 << q_half;
            rgb_to_hsv_g = g_full_q_A1 << q_half;
            rgb_to_hsv_b = b_full_q_A1  << q_half;

            // rgb_to_hsv_r = 48'b000000000000000001000101000000000000000000000000;
            // rgb_to_hsv_g = 48'b000000000000000000001110000000000000000000000000;
            // rgb_to_hsv_b = 48'b000000000000000000000000000000000000000000000000;


        end else if (lagger_A1 == 8) begin
            rgb_to_hsv_go = 1;
            convert_source_rgb_to_hsv_flag = 0;

        end else if (lagger_A1 == 9) begin
            source_frame_hsv_mem_write_addr = counter_A1;

            // convert_source_rgb_to_hsv_flag = 0;

        end else if (lagger_A1 == 10) begin
            hsv_value_A1 =             ( rgb_to_hsv_h >> q_half) << 16;
            hsv_value_A1 = hsv_value_A1 + ((rgb_to_hsv_s >> q_half) << 8);
            hsv_value_A1 = hsv_value_A1 + ( rgb_to_hsv_v >> q_half);

            

            $fdisplay(output_file_source_hue_frame, rgb_to_hsv_h >> q_half);

            // if (counter_A1 == 8115) begin

            //     $display("source_frame_rgb_mem_read_data: %b , r:%b, g:%b, b:%b",
            //     source_frame_rgb_mem_read_data,
            //     rgb_to_hsv_r,
            //     rgb_to_hsv_g,
            //     rgb_to_hsv_b
            //     );


            //     $display("counter_A1=%d r=%f, g=%f, b=%f,        h:%d, s:%d, v:%d     hsv_value_A1:%b",
            //     counter_A1, 
            //     SF*rgb_to_hsv_r,
            //     SF*rgb_to_hsv_g,
            //     SF*rgb_to_hsv_b,
            //     SF*rgb_to_hsv_h,
            //     SF*rgb_to_hsv_s,
            //     SF*rgb_to_hsv_v,
            //     hsv_value_A1
            //     );
            // end


        end else if (lagger_A1 == 11) begin
            source_frame_hsv_mem_write_data = hsv_value_A1;

        end else if (lagger_A1 == 12) begin
            source_frame_hsv_mem_write_enable = 1;


        end else if (lagger_A1 == 13) begin
            source_frame_hsv_mem_write_enable = 0;

        end else if (lagger_A1 == 14) begin
            $fdisplay(output_file_source_hsv_frame, hsv_value_A1);


        end else if (lagger_A1 == 15) begin

            if (counter_A1 < (width * height - 1)) begin
                counter_A1 = counter_A1 + 1;

            end else begin
                // reseting used variables
                source_frame_rgb_mem_read_addr = 0;
                source_frame_hsv_mem_write_addr = 0;
                rgb_to_hsv_r = 0;
                rgb_to_hsv_g = 0;
                rgb_to_hsv_b = 0;
                counter_A1 = 0;
                hsv_value_A1 = 0;

                convert_source_rgb_to_hsv_flag = 0;
                $display("A1: finished converting from rgb to hsv..");

                $fclose(output_file_source_hsv_frame);  
                $fclose(output_file_source_hue_frame);  
                $display("A1:also dumped to output_file_source_hsv_frame.");


                build_hsv_frame_is_finished_milestone           = 1;
                calculate_hue_histogram_flag                    = 1;

            end

            lagger_A1 = 0;
            
        end 
    end
end


