reg                                                     generate_dct_frame_flag = 0;
reg                                                     loop_over_uv_to_generate_dct_flag = 0;
reg                                                     dump_dtc_frames_flag = 0;
reg                                                     dump_jpeg_serialized_mem_flag = 0;

reg                 [q_full - 1 : 0]                    counter_N0;
reg                 [laggers_len - 1 : 0]               lagger_N0;

reg                 [q_full - 1 : 0]                    counter_N1;
reg                 [laggers_len - 1 : 0]               lagger_N1;

reg       signed    [q_full - 1 : 0]                    group_pixel_counter_N0;
reg                 [q_full - 1 : 0]                    group_counter_N0;
reg                 [q_full - 1 : 0]                    sig_group_counter_N0;

reg       signed    [q_full - 1 : 0]                    qt_factor_reg_N0;


reg                 [address_len - 1 : 0]               u_N1;
reg                 [address_len - 1 : 0]               v_N1;

reg                 [address_len - 1 : 0]               depth_N1;


reg                 [6 - 1: 0]                          zig_zag_uvs_N0      [64 - 1: 0]  ;
reg                 [6 - 1: 0]                          zig_zag_index_N1    [64 - 1: 0]  ;

reg                 [64 * 24 - 1 	: 0]                selected_eight_by_eight_group_N0;


reg                 [6 - 1: 0]                          max_dct_depth_N1;
reg                                                     dct_y_active;
reg                                                     dct_c_active;

reg                                                     group_is_inside_a_significant_block;


reg     signed      [8 - 1 : 0]                         dct_y_quantized_N1;
reg     signed      [8 - 1 : 0]                         dct_cb_quantized_N1;
reg     signed      [8 - 1 : 0]                         dct_cr_quantized_N1;

reg     signed      [q_full - 1 : 0]                    dct_y_quantized_full_q_N1;
reg     signed      [q_full - 1 : 0]                    dct_cb_quantized_full_q_N1;
reg     signed      [q_full - 1 : 0]                    dct_cr_quantized_full_q_N1;

/*
we will be populating y_dct_mem


--- N0
it reads 64 pixels
if there is an intersection between the 64 pixels the non-significant blocks:
    cancel and move to the next 64 pixels
it stores them on 64 flip-flops
it calls N1


--- N1
it loops over (u, v) respecting the max depth
for each u and v
    it calls dct module

when dct module responds, N1 places the dct value y_dct_mem with regards to 
    - group counter from N0
    - u, v values

--- dct module
it takes in a pair of (u, v) and 64 input pixels
it loops over x, and y
it uses the dct precalculated constants to calculate the dct value
it returns one single value for the given 8 by 8 group and u,v
*/

reg                                                     dct_go_N1;

wire    signed      [q_full - 1 : 0]                    dct_y_N1;
wire    signed      [q_full - 1 : 0]                    dct_cb_N1;
wire    signed      [q_full - 1 : 0]                    dct_cr_N1;
wire                                                    dct_finished_flag_N1;

dct #(
    .q_full(q_full),
    .q_half(q_half),
    .SF(SF),
    .address_len(address_len),
    .laggers_len(laggers_len),
    .verbose(0)
) my_dct (
    .clk(clk),
    .go(dct_go_N1),
    .dct_y_active(dct_y_active),
    .dct_c_active(dct_c_active),

    .u(u_N1),
    .v(v_N1),
    .group_colors_in(selected_eight_by_eight_group_N0),

    .dct_y(dct_y_N1),
    .dct_cb(dct_cb_N1),
    .dct_cr(dct_cr_N1),

    .dct_finished_flag(dct_finished_flag_N1)
);





// generate_dct_frame_flag
always @(negedge clk) begin
    if (generate_dct_frame_flag == 1) begin

        lagger_N0 = lagger_N0 + 1;

        if (lagger_N0 == 1) begin
            eight_by_eight_grouped_mem_read_addr = counter_N0;

            // $display("N0: counter_N0:%d, group_pixel_counter_N0:%d", counter_N0, group_pixel_counter_N0);

        end else if (lagger_N0 == 2) begin
            // $display("N0: counter_N0:%d, eight_by_eight_grouped_mem_read_data: %b", counter_N0, eight_by_eight_grouped_mem_read_data);
            selected_eight_by_eight_group_N0 = selected_eight_by_eight_group_N0 + (eight_by_eight_grouped_mem_read_data << ((64 - group_pixel_counter_N0 - 1) * 24));
            // $display("N0: counter_N0:%d, selected_eight_by_eight_group_N0:     %b", counter_N0, selected_eight_by_eight_group_N0);


        end else if (lagger_N0 == 3) begin

            if (group_pixel_counter_N0 == 63) begin
                group_block_idx_mem_read_addr = group_counter_N0;
            end

        end else if (lagger_N0 == 4) begin

            if (group_pixel_counter_N0 == 63) begin
                if(most_significant_block_idxs[group_block_idx_mem_read_data] == 1'b1) begin
                    group_is_inside_a_significant_block = 1;
                end else begin
                    group_is_inside_a_significant_block = 0;
                end
            end


        end else if (lagger_N0 == 5) begin

            if (group_pixel_counter_N0 == 63) begin

                $display("N0: group_counter_N0:%d. group_is_inside_a_significant_block: %b, sig_group_counter_N0: %d", group_counter_N0, group_is_inside_a_significant_block, sig_group_counter_N0);

                if (group_is_inside_a_significant_block) begin
                    generate_dct_frame_flag = 0;

                    loop_over_uv_to_generate_dct_flag = 1;

                    sig_group_counter_N0 = sig_group_counter_N0 + 1;
                end

                group_counter_N0 = group_counter_N0 + 1;

                group_pixel_counter_N0 = -1;
            end

        end else if (lagger_N0 == 6) begin

            if (counter_N0 < (width * height -1)) begin
                counter_N0 = counter_N0 + 1;

                group_pixel_counter_N0 = group_pixel_counter_N0 + 1;



            end else begin

                generate_dct_frame_flag = 0;
                $display("K0: finished generating dct frame");

                dump_dtc_frames_flag = 1;


                // dump_eight_by_eight_grouped_mem_flag = 1;


            end

            lagger_N0 = 0;
            
        end 
    end
end



















always @(posedge dct_finished_flag_N1) begin
    // $display("pixel counter: %d   rgb(%f,%f,%f) -> hsv(%f,%f,%f)",
    // counter_A1,
    //  SF*rgb_to_hsv_r, SF*rgb_to_hsv_g, SF*rgb_to_hsv_b,
    //  SF*rgb_to_hsv_h, SF*rgb_to_hsv_s, SF*rgb_to_hsv_v
    //  );

     loop_over_uv_to_generate_dct_flag = 1;
     dct_go_N1 = 0;
end



// N1
// loop_over_uv_to_generate_dct_flag
always @(negedge clk) begin
    if (loop_over_uv_to_generate_dct_flag == 1) begin

        lagger_N1 = lagger_N1 + 1;

        if (lagger_N1 == 1) begin
            u_N1 = (zig_zag_uvs_N0[counter_N1] & 6'b111000)>>3;
            v_N1 = zig_zag_uvs_N0[counter_N1] & 6'b000111;

            
            dct_y_active = (counter_N1 < dct_depth_y) ? 1 : 0;
            dct_c_active = (counter_N1 < dct_depth_c) ? 1 : 0;


            jpeg_y_quantization_table_mem_read_addr = zig_zag_index_N1[counter_N1];
            jpeg_c_quantization_table_mem_read_addr = zig_zag_index_N1[counter_N1];


            // $display("\nN1: counter_N1:%d\t u:%d\t v:%d\tdct_y_active:%d, dct_c_active:%d", counter_N1, u_N1, v_N1, dct_y_active, dct_c_active);

        end else if (lagger_N1 == 2) begin


            dct_go_N1 = 1;
            loop_over_uv_to_generate_dct_flag = 0;


        end else if (lagger_N1 == 3) begin
            // $display("N1: Collected dct for (u:%d, v:%d):\t dct_y_N1:%f, dct_cb_N1:%f, dct_cr_N1:%f",u_N1, v_N1, SF*dct_y_N1, SF*dct_cb_N1, SF*dct_cr_N1);
            dct_go_N1 = 0;

            if (dct_y_active) begin
                // y_dct_mem_write_data =  nt_aeb.signed_round_to_int(nt_aeb.signed_mult(dct_y_N1,  nt_aeb.signed_mult(jpeg_y_quantization_table_mem_read_data, qt_factor_reg_N0)));
                dct_y_quantized_full_q_N1   =  nt_aeb.signed_round_to_int(nt_aeb.signed_mult(dct_y_N1,  nt_aeb.signed_mult(jpeg_y_quantization_table_mem_read_data, qt_factor_reg_N0)));
                y_dct_mem_write_data        = dct_y_quantized_full_q_N1;
                dct_y_quantized_N1          = nt_aeb.to_8_bits_signed(dct_y_quantized_full_q_N1);

        

            end

            if (dct_c_active) begin
                dct_cb_quantized_full_q_N1  = nt_aeb.signed_round_to_int(nt_aeb.signed_mult(dct_cb_N1, nt_aeb.signed_mult(jpeg_c_quantization_table_mem_read_data, qt_factor_reg_N0)));
                cb_dct_mem_write_data       = dct_cb_quantized_full_q_N1;
                dct_cb_quantized_N1          = nt_aeb.to_8_bits_signed(dct_cb_quantized_full_q_N1);

                dct_cr_quantized_full_q_N1  = nt_aeb.signed_round_to_int(nt_aeb.signed_mult(dct_cr_N1, nt_aeb.signed_mult(jpeg_c_quantization_table_mem_read_data, qt_factor_reg_N0)));
                cr_dct_mem_write_data       = dct_cr_quantized_full_q_N1;
                dct_cr_quantized_N1          = nt_aeb.to_8_bits_signed(dct_cr_quantized_full_q_N1);
            end


        // Wrintg Y into jpeg_serialized_mem
        end else if (lagger_N1 == 4) begin
            if (dct_y_active) begin
                jpeg_serialized_mem_write_data = dct_y_quantized_N1;
                // jpeg_serialized_mem_write_addr = (sig_group_counter_N0 - 1) * dct_depth_y + counter_N1; // per block
                jpeg_serialized_mem_write_addr = counter_N1 * sig_groups_count + (sig_group_counter_N0 - 1); // per depth
            end

        end else if (lagger_N1 == 5) begin
            if (dct_y_active) begin
                jpeg_serialized_mem_write_enable = 1;
            end

        end else if (lagger_N1 == 6) begin
            if (dct_y_active) begin
                jpeg_serialized_mem_write_enable = 0;
            end


        // Wrintg Cb into jpeg_serialized_mem
        end else if (lagger_N1 == 7) begin
            if (dct_c_active) begin
                jpeg_serialized_mem_write_data = dct_cb_quantized_N1;
                // jpeg_serialized_mem_write_addr = (sig_groups_count * dct_depth_y) + (sig_group_counter_N0 - 1) * dct_depth_c + counter_N1;// per block
                jpeg_serialized_mem_write_addr = (sig_groups_count * dct_depth_y) + counter_N1 * sig_groups_count + (sig_group_counter_N0 - 1); // per depth
            end

        end else if (lagger_N1 == 8) begin
            if (dct_c_active) begin
                jpeg_serialized_mem_write_enable = 1;
            end

        end else if (lagger_N1 == 9) begin
            if (dct_c_active) begin
                jpeg_serialized_mem_write_enable = 0;
            end


        // Wrintg Cr into jpeg_serialized_mem
        end else if (lagger_N1 == 10) begin
            if (dct_c_active) begin
                jpeg_serialized_mem_write_data = dct_cr_quantized_N1;
                // jpeg_serialized_mem_write_addr = (sig_groups_count * (dct_depth_y + dct_depth_c)) + (sig_group_counter_N0 - 1) * dct_depth_c + counter_N1;// per block
                jpeg_serialized_mem_write_addr = (sig_groups_count * (dct_depth_y + dct_depth_c)) + counter_N1 * sig_groups_count + (sig_group_counter_N0 - 1); // per depth
            end
            
        end else if (lagger_N1 == 11) begin
            if (dct_c_active) begin
                jpeg_serialized_mem_write_enable = 1;
            end

        end else if (lagger_N1 == 12) begin
            if (dct_c_active) begin
                jpeg_serialized_mem_write_enable = 0;
            end



        end else if (lagger_N1 == 13) begin
            if (dct_y_active) begin
                y_dct_mem_write_addr = (group_counter_N0 - 1) * 64 + counter_N1;
            end

            if (dct_c_active) begin
                cb_dct_mem_write_addr = (group_counter_N0 - 1) * 64 + counter_N1;
                cr_dct_mem_write_addr = (group_counter_N0 - 1) * 64 + counter_N1;
            end

            // $display("N1: mem_write_addr: %d, data:%f", y_dct_mem_write_addr, SF*y_dct_mem_write_data);

        end else if (lagger_N1 == 14) begin
            if (dct_y_active) begin
                y_dct_mem_write_enable = 1;
            end

            if (dct_c_active) begin
                cb_dct_mem_write_enable = 1;
                cr_dct_mem_write_enable = 1;
            end


        end else if (lagger_N1 == 15) begin
            if (dct_y_active) begin
                y_dct_mem_write_enable = 0;
            end

            if (dct_c_active) begin
                cb_dct_mem_write_enable = 0;
                cr_dct_mem_write_enable = 0;
            end


        end else if (lagger_N1 == 16) begin

            if (counter_N1 < (max_dct_depth_N1 -1)) begin
                counter_N1 = counter_N1 + 1;



            end else begin
                counter_N1 = 0;

                loop_over_uv_to_generate_dct_flag = 0;
                // $display("N1: finished looping over all uv pairs.");

                // $display("N1: going back to N0");
                selected_eight_by_eight_group_N0 = 0;
                generate_dct_frame_flag = 1;
                
            end

            lagger_N1 = 0;
            
        end 
    end
end








reg                 [q_full - 1 : 0]                    dumper_counter_N0            = 0;
reg                 [q_full - 1 : 0]                    dumper_lagger_N0    = 0;


// dump_dtc_frames_flag
always @(negedge clk) begin
    if (dump_dtc_frames_flag == 1) begin
        dumper_lagger_N0 = dumper_lagger_N0 + 1;

        if (dumper_lagger_N0 == 1) begin
            y_dct_mem_read_addr       = dumper_counter_N0;
            cb_dct_mem_read_addr      = dumper_counter_N0;
            cr_dct_mem_read_addr      = dumper_counter_N0;

            
        end else if (dumper_lagger_N0 == 2) begin

            $fdisplay(output_file_y_dct,  SF*y_dct_mem_read_data);
            $fdisplay(output_file_cb_dct, SF*cb_dct_mem_read_data);
            $fdisplay(output_file_cr_dct, SF*cr_dct_mem_read_data);

            


        end else if (dumper_lagger_N0 == 3) begin

            if (dumper_counter_N0 < width * height - 1) begin
                dumper_counter_N0 = dumper_counter_N0 + 1;

            end else begin
                dumper_counter_N0 = 0;
                dump_dtc_frames_flag = 0;


                $fclose(output_file_y_dct);  
                $fclose(output_file_cb_dct);  
                $fclose(output_file_cr_dct);  
                $display("dumped dct values");

                dump_jpeg_serialized_mem_flag = 1;


            end


            dumper_lagger_N0 = 0;

        end 
    end
end







reg                 [q_full - 1 : 0]                    dumper_counter_N1            = 0;
reg                 [q_full - 1 : 0]                    dumper_lagger_N1    = 0;


// dump_jpeg_serialized_mem_flag
always @(negedge clk) begin
    if (dump_jpeg_serialized_mem_flag == 1) begin
        dumper_lagger_N1 = dumper_lagger_N1 + 1;

        if (dumper_lagger_N1 == 1) begin
            jpeg_serialized_mem_read_addr       = dumper_counter_N1;

            
        end else if (dumper_lagger_N1 == 2) begin

            $fdisplayb(output_file_jpeg_serialized,  jpeg_serialized_mem_read_data);

            


        end else if (dumper_lagger_N1 == 3) begin

            if (dumper_counter_N1 < jpeg_serializable_values_count - 1) begin
                dumper_counter_N1 = dumper_counter_N1 + 1;

            end else begin
                dumper_counter_N1 = 0;
                dump_jpeg_serialized_mem_flag = 0;

                $fclose(output_file_jpeg_serialized);  
                $display("dumped dct values");


                $display("FINISHED_________________________ at %d", $time);

            end


            dumper_lagger_N1 = 0;

        end 
    end
end

