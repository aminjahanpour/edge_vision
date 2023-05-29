`timescale 1ns/1ns
`default_nettype none
`define DUMPSTR(x) `"x.vcd`"


module aeb_tb ();



    reg                                                     clk;
    reg                                                     reset;


    aeb aeb_inst (
        .clk(clk),
        .reset(reset)
    );




    integer i;

    always #1 clk = ~clk;



    // parameter DURATION = 40_500_000;
    // parameter DURATION = 10_000_000;
    parameter DURATION = 1_500_000;
    // parameter DURATION = 1_000;

reg                 [24 - 1 : 0]               pixel_counter                   = 'd41 ;

    initial begin
        clk = 0;



        #1;
        $display("\n running...");

        // $display(nt_aeb.SF*nt_aeb.signed_round_to_int(nt_aeb.minus_one_point2));

        $display("%b",                          nt_aeb.minus45p25);
        $display("%d",  nt_aeb.to_8_bits_signed(nt_aeb.minus45p25));
        $display("%b",  nt_aeb.to_8_bits_signed(nt_aeb.minus45p25));

        // for (i = 0; i < 256; i = i+1) begin
        //     $display("%b", i);
        // end


    //    pixel_counter =  nt_aeb.mult_high_precision(pixel_counter, nt_aeb.one_over_width_cropped_hp);





        reset = 0;
        #1;
        reset = 1;
        
    end


    

    initial begin

        // $dumpfile(`DUMPSTR(`VCD_OUTPUT));
        // $dumpvars(0, ln_tb);

        #(DURATION) $display("End of simulation");
        $finish;

    end


endmodule


