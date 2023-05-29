
module dct #(
    parameter                                           q_full                          = 0,
    parameter                                           q_half                          = 0,
    parameter                                           SF                              = 0,
    parameter                                           address_len                     = 0,
    parameter                                           laggers_len                     = 0,
    parameter                                           verbose                         = 0

)(
    input                                               clk,
    input                                               go,
    input                                               dct_y_active,
    input                                               dct_c_active,

    input                   [address_len - 1 : 0]       u,
    input                   [address_len - 1 : 0]       v,
    input                   [64 * 24 - 1 : 0]           group_colors_in,

    output     reg   signed [q_full - 1 : 0]            dct_y,
    output     reg   signed [q_full - 1 : 0]            dct_cb,
    output     reg   signed [q_full - 1 : 0]            dct_cr,

    output     reg                                      dct_finished_flag

);

reg                                                     working;


reg                         [address_len - 1 : 0]       counter;
reg                         [laggers_len - 1 : 0]       lagger;

reg                         [address_len - 1 : 0]       x;
reg                         [address_len - 1 : 0]       y;
reg             signed      [q_full - 1 : 0]            cu;
reg             signed      [q_full - 1 : 0]            cv;
reg             signed      [q_full - 1 : 0]            sum_y;
reg             signed      [q_full - 1 : 0]            sum_cb;
reg             signed      [q_full - 1 : 0]            sum_cr;
reg                         [q_full - 1 : 0]            y_full_q;
reg                         [q_full - 1 : 0]            cr_full_q;
reg                         [q_full - 1 : 0]            cb_full_q;

reg                         [24 - 1 : 0]                group_colors      [64 - 1 : 0];

integer i;


// dct constants
reg                                                     dct_constants_mem_read_enable    = 1 ;
reg                        [address_len - 1 : 0]        dct_constants_mem_read_addr      ;
wire            signed     [q_full - 1 	: 0]            dct_constants_mem_read_data      ;

memory_list_signed #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(4096),
    .initial_file("./dct_constants.mem")
) dct_constants_mem(
    .clk(clk),
    .r_en(     dct_constants_mem_read_enable),
    .r_addr(   dct_constants_mem_read_addr),
    .r_data(   dct_constants_mem_read_data)
);



always @(posedge go) begin

    if (verbose) $display("DCT Module: %d\tdct go... u=%f, v=%f", $time, u, v);

    working = 1;
    dct_finished_flag = 0;
    counter = 0;
    lagger = 0;
    x = 0;
    y = 0;
    cu = 0;
    cv = 0;
    sum_y = 0;
    sum_cb = 0;
    sum_cr = 0;
    y_full_q = 0;
    cb_full_q = 0;
    cr_full_q = 0;


    if (verbose) $display("DCT Module: collected pixels:");

    for (i = 0; i < 64; i = i + 1) begin
        group_colors[i] = group_colors_in[(63-i) * 24 +: 24];
        if (verbose) $display("%d---------- %b", i, group_colors[i]);

    end
    if (verbose) $display("\n");


end


always @(negedge clk) begin
    if ((working == 1) && (dct_finished_flag == 0)) begin

        lagger = lagger + 1;

        if (lagger == 1) begin
            dct_constants_mem_read_addr = (u * 512) + (v * 64) + (x * 8) + (y);
            if (verbose) $display("DCT Module: x:%d, y:%d, dct_constants_mem_read_addr=%d", x,y, dct_constants_mem_read_addr);

        end else if (lagger == 2) begin
            if (dct_y_active) begin
                y_full_q  = (group_colors[x * 8 + y] & 24'b111111110000000000000000)>>16;
            end
    
            if (dct_c_active) begin
                cb_full_q = (group_colors[x * 8 + y] & 24'b000000001111111100000000)>>8 ;
                cr_full_q = (group_colors[x * 8 + y] & 24'b000000000000000011111111)    ;
            end
            
            if (verbose) $display("DCT Module:\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t y_full_q=%d, cb_full_q=%d, cr_full_q=%d, ",y_full_q, cb_full_q,  cr_full_q);


        end else if (lagger == 3) begin
            if (verbose) $display("DCT Module: before multipication: sum_y=%f", SF*sum_y);
            
            
            if (verbose) $display("DCT Module: the multipication: ans=%f, $signed(y_full_q  << q_half)=%f * dct_constants_mem_read_data=%f",
            SF*nt_aeb.signed_mult($signed(y_full_q  << q_half), dct_constants_mem_read_data),
            SF*$signed(y_full_q  << q_half),
            SF*dct_constants_mem_read_data);

            if (dct_y_active) begin
                sum_y  = sum_y  + nt_aeb.signed_mult($signed(y_full_q  << q_half), dct_constants_mem_read_data);
            end
            
            if (dct_c_active) begin
                sum_cb = sum_cb + nt_aeb.signed_mult($signed(cb_full_q << q_half), dct_constants_mem_read_data);
                sum_cr = sum_cr + nt_aeb.signed_mult($signed(cr_full_q << q_half), dct_constants_mem_read_data);
            end

            if (verbose) $display("DCT Module: after multipication: sum_y=%f", SF*sum_y);

        end else if (lagger == 4) begin

            if (counter < (64 - 1)) begin
                counter = counter + 1;

                y = y + 1;

                if (y == 8) begin
                    x = x + 1;
                    y = 0;
                end

            end else begin

                if (u == 0) begin
                    cu = nt_aeb.one_over_sqrt_2;
                end else begin
                    cu = nt_aeb.one;
                end

                if (v == 0) begin
                    cv = nt_aeb.one_over_sqrt_2;
                end else begin
                    cv = nt_aeb.one;
                end

                // if (verbose) $display("DCT Module: cu: %f", SF*cu);
                // if (verbose) $display("DCT Module: cv: %f", SF*cv);


                // if (verbose) $display("DCT Module: sum_y: %f", SF*sum_y);

                // dct_y = nt_aeb.signed_mult(sum_y,  cu);
                // if (verbose) $display("DCT Module: dct_y= sum_y * cu: %f", SF*dct_y);

                // dct_y = nt_aeb.signed_mult(dct_y, cv);
                // if (verbose) $display("DCT Module: dct_y= dct_y * cv: %f", SF*dct_y);

                // dct_y = nt_aeb.signed_mult(dct_y, nt_aeb.one_over_4_signed);
                // if (verbose) $display("DCT Module: dct_y = dct_y * 0.25 (final): %f", SF*dct_y);
                
                if (dct_y_active) begin
                    dct_y  = nt_aeb.signed_mult(nt_aeb.signed_mult(nt_aeb.signed_mult(sum_y , cu), cv), nt_aeb.one_over_4_signed);
                end
                
                if (dct_c_active) begin
                    dct_cb = nt_aeb.signed_mult(nt_aeb.signed_mult(nt_aeb.signed_mult(sum_cb, cu), cv), nt_aeb.one_over_4_signed);
                    dct_cr = nt_aeb.signed_mult(nt_aeb.signed_mult(nt_aeb.signed_mult(sum_cr, cu), cv), nt_aeb.one_over_4_signed);
                end


                working = 0;
                dct_finished_flag = 1;
                if (verbose)  $display("DCT Module: finished calculating dct values");

            end

            lagger = 0;
            
        end 
    end
end




endmodule