`include "../division/division.v"

module rgb_to_hsv #(
    parameter                                           q_full                          = 0,
    parameter                                           q_half                          = 0,
    parameter                                           SF                              = 0,
    parameter                                           verbose                         = 0

)(
    input                                               clk,
    input                                               go,

    input                   [q_full - 1 : 0]            r,
    input                   [q_full - 1 : 0]            g,
    input                   [q_full - 1 : 0]            b,

    output     reg          [q_full - 1 : 0]            h,
    output     reg          [q_full - 1 : 0]            s,
    output     reg          [q_full - 1 : 0]            v,

    output     reg                                      rgb_to_hsv_finished_flag

);

reg                                                     working;

localparam                                              address_len                     = 24;





reg                         [address_len - 1 : 0]       counter;

reg                         [q_full - 1 : 0]            maxc;
reg                         [q_full - 1 : 0]            minc;
reg                         [q_full - 1 : 0]            delta;
reg                         [q_full - 1 : 0]            rc;
reg                         [q_full - 1 : 0]            gc;
reg                         [q_full - 1 : 0]            bc;


// Division
reg                                                     rgb_to_hsv_division_start;             // start signal
wire                                                    rgb_to_hsv_division_busy;              // calculation in progress
wire                                                    rgb_to_hsv_division_valid;             // quotient and remainder are valid
wire                                                    rgb_to_hsv_division_dbz;               // divide by zero flag
wire                                                    rgb_to_hsv_division_ovf;               // overflow flag (fixed-point only)
reg                         [q_full - 1 : 0]            rgb_to_hsv_division_x;                 // dividend
reg                         [q_full - 1 : 0]            rgb_to_hsv_division_y;                 // divisor
wire                        [q_full - 1 : 0]            rgb_to_hsv_division_q;                 // quotient
wire                        [q_full - 1 : 0]            rgb_to_hsv_division_r;                 // remainder

division #(
    .width(q_full),
    .floating_bits(q_half)
    ) division_instance (
        .clk(   clk),
        .start( rgb_to_hsv_division_start),
        .busy(  rgb_to_hsv_division_busy),
        .valid( rgb_to_hsv_division_valid),
        .dbz(   rgb_to_hsv_division_dbz),
        .ovf(   rgb_to_hsv_division_ovf),
        .x(     rgb_to_hsv_division_x),
        .y(     rgb_to_hsv_division_y),
        .q(     rgb_to_hsv_division_q),
        .r(     rgb_to_hsv_division_r)
    );



always @(posedge go) begin

    if (verbose) $display("%d\trgb_to_hsv go... r=%f, g=%f, b=%f", $time, SF*r, SF*g, SF*b);

    working = 1;
    rgb_to_hsv_finished_flag = 0;
    counter = 0;
end

// Division Collector
always @(negedge rgb_to_hsv_division_busy) begin
    working = 1;

    if (verbose) begin
        $display("%d:\t%f / %f = (%f)  (V=%b) (DBZ=%b) (OVF=%b)",
        $time, rgb_to_hsv_division_x*SF, rgb_to_hsv_division_y*SF, rgb_to_hsv_division_q*SF, 
        rgb_to_hsv_division_valid, rgb_to_hsv_division_dbz, rgb_to_hsv_division_ovf);
    end

    if ((rgb_to_hsv_division_valid == 0)  || (rgb_to_hsv_division_ovf == 1)) begin
        $display("\n\n----------DIVISION ERROR---------\n\n\n");
    end

end



always @(posedge clk) begin
    if ((working == 1) && (rgb_to_hsv_finished_flag == 0)) begin
        counter = counter + 1;


        if (counter == 1) begin
                     if ((r >= g) && (r >= b)) begin
                maxc = r;
            end else if ((g >= r) && (g >= b)) begin
                maxc = g;
            end else if ((b >= r) && (b >= g)) begin
                maxc = b;
            end else begin
                $display("sanity ERROR, have you loaded the correct rgb");
            end


        end else if (counter == 2) begin
                     if ((r <= g) && (r <= b)) begin
                minc = r;
            end else if ((g <= r) && (g <= b)) begin
                minc = g;
            end else if ((b <= r) && (b <= g)) begin
                minc = b;
            end else begin
                $display("sanity ERROR, have you loaded the correct rgb");
            end

        end else if (counter == 3) begin
            v = maxc;
            s=0;

        end else if (counter == 4) begin
            if (minc == maxc) begin
                h = 0;
                s = 0;
                rgb_to_hsv_finished_flag = 1;;
            end

        end else if (counter == 5) begin
            delta = maxc - minc;





        // end else if (counter == 6) begin
        //     rgb_to_hsv_division_x = delta;
        //     rgb_to_hsv_division_y = maxc;

        // end else if (counter == 7) begin
        //     if (verbose) $display("divising for s");
        //     rgb_to_hsv_division_start = 1;
        //     working = 0;

        // end else if (counter == 17) begin
        //     // you'll be here only when the first division is finished.
        //     rgb_to_hsv_division_start = 0;

        //     s = rgb_to_hsv_division_q;










        end else if (counter == 6) begin
            rgb_to_hsv_division_x = maxc - r;
            rgb_to_hsv_division_y = delta;

        end else if (counter == 7) begin
            if (verbose) $display("divising for rc");
            rgb_to_hsv_division_start = 1;
            working = 0;

        end else if (counter == 8) begin

            rc = rgb_to_hsv_division_q;
            if (verbose) $display("rc = %f", SF*rc);

            rgb_to_hsv_division_start = 0;









        end else if (counter == 9) begin
            rgb_to_hsv_division_x = maxc - g;
            rgb_to_hsv_division_y = delta;

        end else if (counter == 10) begin
            if (verbose) $display("divising for gc");
            rgb_to_hsv_division_start = 1;
            working = 0;

        end else if (counter == 11) begin
            rgb_to_hsv_division_start = 0;

            gc = rgb_to_hsv_division_q;
            if (verbose) $display("--gc = %f / %f =  %f",SF*rgb_to_hsv_division_x, SF*rgb_to_hsv_division_y, SF*gc);







        end else if (counter == 12) begin
            rgb_to_hsv_division_x = maxc - b;
            rgb_to_hsv_division_y = delta;

        end else if (counter == 13) begin
            rgb_to_hsv_division_start = 1;
            if (verbose) $display("divising for bc");
            working = 0;

        end else if (counter == 14) begin
            rgb_to_hsv_division_start = 0;

            bc = rgb_to_hsv_division_q;
            if (verbose) $display("bc = %f", SF*bc);








        end else if (counter == 15) begin
            if (r == maxc) begin
                if (verbose) $display("r == maxc");
                if (verbose) $display("h = bc%f -gc%f", SF*bc, SF*gc);
                h = bc -gc;

            end else if (g == maxc) begin
                if (verbose) $display("g == maxc");
                h = nt_aeb.two + rc - bc;

            end else begin
                if (verbose) $display("else");
                if (verbose) $display("h = nt_aeb.four%f + gc%f - rc%f",SF*nt_aeb.four , SF*gc, SF*rc);

                h = nt_aeb.four + gc - rc;
            end

            if (verbose) $display("--> h: %f" , SF * h);

        end else if (counter == 16) begin
            h = nt_aeb.mult(h, nt_aeb.one_over_six);
            if (verbose) $display("h1: %f" , SF * h);

        end else if (counter == 17) begin
            h = h & nt_aeb.floating_part_mask;
            if (verbose) $display("h2: %f" , SF * h);

        end else if (counter == 18) begin
            // h = nt_aeb.mult(h, nt_aeb.one_eighty);
            h = nt_aeb.round_to_int(nt_aeb.mult(h, nt_aeb.one_eighty));
            if (verbose) $display("h3: %f" , SF * h);

        end else if (counter == 19) begin
            // $display("s: %f" , SF * s);

            // s = nt_aeb.mult(s, nt_aeb.two_fifty_five);
            // s = nt_aeb.round_to_int(nt_aeb.mult(s, nt_aeb.two_fifty_five));

        end else if (counter == 20) begin
            if (verbose) $display("_________output h: %d" , h >> q_half);
            rgb_to_hsv_finished_flag = 1;;

        end

    end
end


endmodule