
module aeb (
    input                                               clk,
    input                                               reset
);
    

// Options
localparam                                              exclude_insignificant_blocks_option = 0;
localparam                                              use_jpeg_compression = 1;



// Paramters

localparam                                              width                            = 112;
localparam                                              height                           = 80;
// localparam                                              width                            = 320;
// localparam                                              height                           = 240;

localparam                                              crop_count                       = 2;
localparam                                              top_blocks_count                 = 4;

localparam                                              dct_depth_y                      = 5;
localparam                                              dct_depth_c                      = 1;
localparam                                              qt_factor                        = 1;

localparam                                              sum_bpu                          = 24;
localparam                                              color_system                     = 0;



// infered parameters



localparam                                              groups_per_block                 = block_width * block_height / 64;
localparam                                              sig_groups_count                 = top_blocks_count * groups_per_block;

localparam                                              jpeg_serializable_values_count   = top_blocks_count * groups_per_block * (dct_depth_y + 2 * dct_depth_c);


localparam                                              block_pixels_count               = (width * height) / (crop_count * crop_count);
localparam                                              groups_count                     = (width * height) / (8 * 8);


localparam                                              width_over_eight                 = width / 8;
localparam                                              width_over_two                   = width / 2;

localparam                                              block_width                      = width / crop_count;
localparam                                              block_height                     = height / crop_count;

localparam                                              hue_bins_to_remove               = 0.95 * width * height;




// Constants
localparam                                              full_color_range                 = 256;
localparam                                              full_hue_range                   = 180;

localparam                                              sum_bpu_full                     = 24;

localparam                                              address_len                      = 24;
localparam                                              laggers_len                      = 8 ;

localparam                                              q_full                           = 48;
localparam                                              q_half                           = 24;
localparam                                              SF                               = 2.0 ** -24.0;  

localparam                                              q_full_hp                        = 64;
localparam                                              q_half_hp                        = 32;
localparam                                              SF_hp                            = 2.0**-32.0;  


localparam                                              hue_color_range_count           = 6;




// Output Files

// first
integer                                                 output_file_source_rgb_frame        ;  
integer                                                 output_file_source_hsv_frame        ;  
integer                                                 output_file_source_hue_frame        ; 
integer                                                 output_file_obtained_hue            ;
integer                                                 output_file_source_gray_frame        ;  
integer                                                 output_file_aeb_frame               ;  
integer                                                 output_file_hue_hist_full_frame     ;  
integer                                                 output_file_hue_hist_blocks         ;  
integer                                                 output_file_union_mags         ;  
integer                                                 output_file_ss                      ;  

// second
integer                                                 output_file_red_hist_full_frame_masked;
integer                                                 output_file_green_hist_full_frame_masked;
integer                                                 output_file_blue_hist_full_frame_masked;
integer                                                 output_file_gray_hist_full_frame_masked;
integer                                                 output_file_masked_rgb_frame;
integer                                                 output_file_masked_gray_frame;

// third
integer                                                 output_file_decoded_rgb;

integer                                                 output_file_source_ycbcr_frame        ;  
integer                                                 output_file_eight_by_eight_grouped ;
integer                                                 output_file_two_by_two_grouped ;
integer                                                 output_file_y_dct ;
integer                                                 output_file_cb_dct ;
integer                                                 output_file_cr_dct ;
integer                                                 output_file_jpeg_serialized;

// Basic variables

reg                                                     ranger_is_activated;

reg                 [sum_bpu_full - 1 : 0 ]             bpu_r;    
reg                 [sum_bpu_full - 1 : 0 ]             bpu_g;    
reg                 [sum_bpu_full - 1 : 0 ]             bpu_b;    

reg                 [sum_bpu_full - 1 : 0]              r_mask;
reg                 [sum_bpu_full - 1 : 0]              g_mask;
reg                 [sum_bpu_full - 1 : 0]              b_mask;

reg                 [sum_bpu_full - 1 : 0]              full_r_mask;
reg                 [sum_bpu_full - 1 : 0]              full_g_mask;
reg                 [sum_bpu_full - 1 : 0]              full_b_mask;
reg                 [sum_bpu_full - 1 : 0]              full_h_mask;

reg                 [q_full - 1 : 0]                    two_to_bpu_r_minus_one              ;
reg                 [q_full - 1 : 0]                    two_to_bpu_g_minus_one              ;
reg                 [q_full - 1 : 0]                    two_to_bpu_b_minus_one              ;


reg                 [q_full - 1 : 0]                    full_q_crop_count;


reg                 [q_full_hp - 1 : 0]     one_over_crop_count;




















// ########################################################################################################################################################################################
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################

// Memory Arrays------------------------------------------------------------------------------------------------

// Source Full Frame ROM (24-bit RGB)
reg                                                     source_frame_rgb_mem_read_enable    = 1 ;
reg                 [address_len - 1 : 0]               source_frame_rgb_mem_read_addr      ;
wire                [sum_bpu_full - 1 	: 0]            source_frame_rgb_mem_read_data      ;
reg                                                     source_frame_rgb_mem_write_enable   ;
reg                 [address_len - 1 : 0]               source_frame_rgb_mem_write_addr     ;
reg                 [sum_bpu_full - 1 	: 0]            source_frame_rgb_mem_write_data     ;

memory_list #(
    .mem_width(sum_bpu_full),
    .address_len(address_len),
    .mem_depth(width * height),
    // .initial_file("./frame_320_240_rgb_888_shuttle.mem")
    // .initial_file("./frame_320_240_rgb_888_truck.mem")
    // .initial_file("./frame_112_80_rgb_888_truck.mem")
    .initial_file("./frame_112_80_rgb_888_shuttle.mem")
) source_frame_rgb(
    .clk(clk),
    .r_addr(source_frame_rgb_mem_read_addr),
    .r_data(source_frame_rgb_mem_read_data),
    .r_en(  source_frame_rgb_mem_read_enable)
);





// Source Full Frame RAM (8-bit Gray)
reg                                                     source_frame_gray_mem_read_enable    = 1 ;
reg                 [address_len - 1 : 0]               source_frame_gray_mem_read_addr      ;
wire                [8 - 1 	: 0]                        source_frame_gray_mem_read_data      ;
reg                                                     source_frame_gray_mem_write_enable   ;
reg                 [address_len - 1 : 0]               source_frame_gray_mem_write_addr     ;
reg                 [8 - 1 	: 0]                        source_frame_gray_mem_write_data     ;

memory_list #(
    .mem_width(8),
    .address_len(address_len),
    .mem_depth(width * height)
    // .initial_file("./frame_320_240_gray_8.mem")
) source_frame_gray(
    .clk(clk),
    .r_addr(source_frame_gray_mem_read_addr),
    .r_data(source_frame_gray_mem_read_data),
    .r_en(  source_frame_gray_mem_read_enable),
    .w_addr(source_frame_gray_mem_write_addr),
    .w_data(source_frame_gray_mem_write_data),
    .w_en(  source_frame_gray_mem_write_enable)
);



// HSV Source Full Frame RAM (24-bit HSV)

reg                                                     source_frame_hsv_mem_read_enable    = 1 ;
reg                 [address_len - 1 : 0]               source_frame_hsv_mem_read_addr      ;
wire                [sum_bpu_full - 1 	: 0]            source_frame_hsv_mem_read_data      ;
reg                                                     source_frame_hsv_mem_write_enable   ;
reg                 [address_len - 1 : 0]               source_frame_hsv_mem_write_addr     ;
reg                 [sum_bpu_full - 1 	: 0]            source_frame_hsv_mem_write_data     ;

memory_list #(
    .mem_width(sum_bpu_full),
    .address_len(address_len),
    .mem_depth(width * height)
    // .initial_file("./frame_112_80_hsv_888_shuttle.mem")
    // .initial_file("./frame_320_240_hsv_888_shuttle.mem")
) source_frame_hsv(
    .clk(clk),
    .r_addr(source_frame_hsv_mem_read_addr),
    .r_data(source_frame_hsv_mem_read_data),
    .r_en(  source_frame_hsv_mem_read_enable),
    .w_addr(source_frame_hsv_mem_write_addr),
    .w_data(source_frame_hsv_mem_write_data),
    .w_en(  source_frame_hsv_mem_write_enable)
);







// AEB Full Frame RAM

reg                                                     aeb_frame_mem_read_enable       = 1 ;
reg                 [address_len - 1 : 0]               aeb_frame_mem_read_addr             ;
wire                [sum_bpu - 1 	: 0]                aeb_frame_mem_read_data             ;
reg                                                     aeb_frame_mem_write_enable          ;
reg                 [address_len - 1 : 0]               aeb_frame_mem_write_addr            ;
reg                 [sum_bpu - 1 	: 0]                aeb_frame_mem_write_data            ;

memory_list #(
    .mem_width(sum_bpu),
    .address_len(address_len),
    .mem_depth(block_width * block_height * top_blocks_count)

    // .initial_file("./aeb_encoded_frame_grey_bpu_8.mem")
    // .initial_file("./aeb_encoded_frame_bpu_24.mem")
    // .initial_file("./aeb_encoded_frame_grey_8_2_blocks.mem")

) aeb_frame(
    .clk(clk),
    .r_addr(aeb_frame_mem_read_addr),
    .r_data(aeb_frame_mem_read_data),
    .r_en(  aeb_frame_mem_read_enable),
    .w_addr(aeb_frame_mem_write_addr),
    .w_data(aeb_frame_mem_write_data),
    .w_en(  aeb_frame_mem_write_enable)
);






// Decoded Full Frame ROM (24-bit RGB)
reg                                                     decoded_frame_rgb_mem_read_enable    = 1 ;
reg                 [address_len - 1 : 0]               decoded_frame_rgb_mem_read_addr      ;
wire                [sum_bpu_full - 1 	: 0]            decoded_frame_rgb_mem_read_data      ;
reg                                                     decoded_frame_rgb_mem_write_enable   ;
reg                 [address_len - 1 : 0]               decoded_frame_rgb_mem_write_addr     ;
reg                 [sum_bpu_full - 1 	: 0]            decoded_frame_rgb_mem_write_data     ;

memory_list #(
    .mem_width(sum_bpu_full),
    .address_len(address_len),
    .mem_depth(width * height)
) target_frame_decoded_rgb(
    .clk(clk),
    .r_en(     decoded_frame_rgb_mem_read_enable),
    .r_addr(   decoded_frame_rgb_mem_read_addr),
    .r_data(   decoded_frame_rgb_mem_read_data),
    .w_en(     decoded_frame_rgb_mem_write_enable),
    .w_addr(   decoded_frame_rgb_mem_write_addr),
    .w_data(   decoded_frame_rgb_mem_write_data)

);







// Block Idx Ram
reg                                                     block_idx_mem_read_enable    = 1 ;
reg                 [address_len - 1 : 0]               block_idx_mem_read_addr      ;
wire                [q_full - 1 	: 0]            block_idx_mem_read_data      ;
reg                                                     block_idx_mem_write_enable   ;
reg                 [address_len - 1 : 0]               block_idx_mem_write_addr     ;
reg                 [q_full - 1 	: 0]            block_idx_mem_write_data     ;

memory_list #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(width * height)
) block_idx_mem(
    .clk(clk),
    .r_en(     block_idx_mem_read_enable),
    .r_addr(   block_idx_mem_read_addr),
    .r_data(   block_idx_mem_read_data),
    .w_en(     block_idx_mem_write_enable),
    .w_addr(   block_idx_mem_write_addr),
    .w_data(   block_idx_mem_write_data)

);


























// RGB Full Frame Masked RAM (24-bit RGB)
reg                                                     masked_rgb_frame_ram_read_enable    = 1 ;
reg                 [address_len - 1 : 0]               masked_rgb_frame_ram_read_addr      ;
wire                [sum_bpu_full - 1 	: 0]            masked_rgb_frame_ram_read_data      ;
reg                                                     masked_rgb_frame_ram_write_enable   ;
reg                 [address_len - 1 : 0]               masked_rgb_frame_ram_write_addr     ;
reg                 [sum_bpu_full - 1 	: 0]            masked_rgb_frame_ram_write_data     ;

memory_list #(
    .mem_width(sum_bpu_full),
    .address_len(address_len),
    .mem_depth(width * height)
    // .initial_file("./frame_320_240_rgb_888.mem")
    // .initial_file("./frame_112_80_rgb_888.mem")

) source_frame_rgb_masked(
    .clk(clk),
    .r_addr(   masked_rgb_frame_ram_read_addr),
    .r_data(   masked_rgb_frame_ram_read_data),
    .r_en(     masked_rgb_frame_ram_read_enable),
    .w_addr(   masked_rgb_frame_ram_write_addr     ),
    .w_data(   masked_rgb_frame_ram_write_data     ),
    .w_en(     masked_rgb_frame_ram_write_enable   )
);



// GRAY Full Frame Masked RAM (8-bit RGB)
reg                                                     masked_gray_frame_ram_read_enable    = 1 ;
reg                 [address_len - 1 : 0]               masked_gray_frame_ram_read_addr      ;
wire                [8 - 1 	: 0]            masked_gray_frame_ram_read_data      ;
reg                                                     masked_gray_frame_ram_write_enable   ;
reg                 [address_len - 1 : 0]               masked_gray_frame_ram_write_addr     ;
reg                 [8 - 1 	: 0]            masked_gray_frame_ram_write_data     ;

memory_list #(
    .mem_width(8),
    .address_len(address_len),
    .mem_depth(width * height)
    // .initial_file("./frame_320_240_gray_8.mem")
) source_frame_gray_masked(
    .clk(clk),
    .r_addr(   masked_gray_frame_ram_read_addr),
    .r_data(   masked_gray_frame_ram_read_data),
    .r_en(     masked_gray_frame_ram_read_enable),
    .w_addr(   masked_gray_frame_ram_write_addr     ),
    .w_data(   masked_gray_frame_ram_write_data     ),
    .w_en(     masked_gray_frame_ram_write_enable   )
);















































// Full Frame Hue Histogram
/*
this array has 256 row for each hue value [0 : 255], so the address len is 8
ytt we go with address_len, to be conpatible
every row can take value from 0 to width*height = 320 * 240.
so width needs to be at least [clog2(320*240)] + 1 = 17
we go with sum_bpu_full to be safe.
*/
reg                                                     hue_hist_full_frame_mem_read_enable       = 1 ;
reg                 [address_len - 1 : 0]               hue_hist_full_frame_mem_read_addr             ;
wire                [q_full - 1 : 0]                    hue_hist_full_frame_mem_read_data             ;
reg                                                     hue_hist_full_frame_mem_write_enable          ;
reg                 [address_len - 1 : 0]               hue_hist_full_frame_mem_write_addr            ;
reg                 [q_full - 1 : 0     ]               hue_hist_full_frame_mem_write_data            ;


memory_list #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(full_hue_range)
    // .initial_file("./zeros_24_256.mem")
    // .initial_file("./hue_hist_full_frame_deducted_normalized.mem")
) hue_hist(
    .clk(clk),
    .r_addr(hue_hist_full_frame_mem_read_addr      ),
    .r_data(hue_hist_full_frame_mem_read_data      ),
    .r_en(  hue_hist_full_frame_mem_read_enable    ),
    .w_addr(hue_hist_full_frame_mem_write_addr     ),
    .w_data(hue_hist_full_frame_mem_write_data     ),
    .w_en(  hue_hist_full_frame_mem_write_enable   )
);




// Full Frame Hue Values
/*
this array simply stores 0 to 255. These represent hue values.
we go with address_len, to be conpatible
every row can take value from 0 to 255.
we go with sum_bpu_full to be safe.
*/
reg                                                     hue_values_full_frame_mem_read_enable       = 1 ;
reg                 [address_len - 1 : 0]               hue_values_full_frame_mem_read_addr             ;
wire                [q_full - 1 : 0]                    hue_values_full_frame_mem_read_data             ;
reg                                                     hue_values_full_frame_mem_write_enable          ;
reg                 [address_len - 1 : 0]               hue_values_full_frame_mem_write_addr            ;
reg                 [q_full - 1 : 0]                    hue_values_full_frame_mem_write_data            ;


memory_list #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(full_hue_range)
    // .initial_file("./hue_values_0_to_255.mem")
) hues(
    .clk(clk),
    .r_addr(hue_values_full_frame_mem_read_addr      ),
    .r_data(hue_values_full_frame_mem_read_data      ),
    .r_en(  hue_values_full_frame_mem_read_enable    ),
    .w_addr(hue_values_full_frame_mem_write_addr     ),
    .w_data(hue_values_full_frame_mem_write_data     ),
    .w_en(  hue_values_full_frame_mem_write_enable   )
);




// Block Frame Hue Histogram
/*
this array has 256*8*8 row for each hue value [0 : 255] and for 8*8 blocks,
 so the address len is 8 [clog2(256*8*8)] = 14
yet we go with address_len, to be conpatible
every row can take value from 0 to (width/ 8)*(height/8) = 320 * 240 / 64 = 1200
so width needs to be at least [clog2(1200)] + 1 = 11
we go with sum_bpu_full to be safe.
*/

reg                                                     hue_hist_blocks_mem_read_enable       = 1 ;
reg                 [address_len - 1 : 0]               hue_hist_blocks_mem_read_addr             ;
wire                [q_full - 1 : 0]                    hue_hist_blocks_mem_read_data             ;
reg                                                     hue_hist_blocks_mem_write_enable          ;
reg                 [address_len - 1 : 0]               hue_hist_blocks_mem_write_addr            ;
reg                 [q_full - 1 : 0]                    hue_hist_blocks_mem_write_data            ;


memory_list #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(full_hue_range * crop_count * crop_count)
    // .initial_file("./zeros_16384_48.mem")
    // .initial_file("./union_mags.mem")
) hue_hist_blocks_ram(
    .clk(clk),
    .r_addr(hue_hist_blocks_mem_read_addr      ),
    .r_data(hue_hist_blocks_mem_read_data      ),
    .r_en(  hue_hist_blocks_mem_read_enable    ),
    .w_addr(hue_hist_blocks_mem_write_addr     ),
    .w_data(hue_hist_blocks_mem_write_data     ),
    .w_en(  hue_hist_blocks_mem_write_enable   )
);














// Union Mag Squared Sum Per Hue Color Range
/*
every row is the sum of union_mag ^2 for a given hur_color_range
we have 6 hue_color_ranges
we have 64 blocks
so the memory depth needs to be 6 * 64 = 384
the value itself would fit in q_full
*/



reg                                                     ss_ram_read_enable       = 1 ;
reg                 [address_len - 1 : 0]               ss_ram_read_addr             ;
wire                [q_full - 1 : 0]                    ss_ram_read_data             ;
reg                                                     ss_ram_write_enable          ;
reg                 [address_len - 1 : 0]               ss_ram_write_addr            ;
reg                 [q_full - 1 : 0]                    ss_ram_write_data            ;


memory_list #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(hue_color_range_count * crop_count * crop_count)
    // .initial_file("./zeros_384_48.mem")
) ss_ram(
    .clk(clk),
    .r_addr(ss_ram_read_addr      ),
    .r_data(ss_ram_read_data      ),
    .r_en(  ss_ram_read_enable    ),
    .w_addr(ss_ram_write_addr     ),
    .w_data(ss_ram_write_data     ),
    .w_en(  ss_ram_write_enable   )
);





// Union Mag SH Per Hue Color Range


reg                                                     sh_ram_read_enable       = 1 ;
reg                 [address_len - 1 : 0]               sh_ram_read_addr             ;
wire                [q_full - 1 : 0]                    sh_ram_read_data             ;
reg                                                     sh_ram_write_enable          ;
reg                 [address_len - 1 : 0]               sh_ram_write_addr            ;
reg                 [q_full - 1 : 0]                    sh_ram_write_data            ;


memory_list #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(hue_color_range_count * crop_count * crop_count)
    // .initial_file("./zeros_384_48.mem")
) sh_ram(
    .clk(clk),
    .r_addr(sh_ram_read_addr      ),
    .r_data(sh_ram_read_data      ),
    .r_en(  sh_ram_read_enable    ),
    .w_addr(sh_ram_write_addr     ),
    .w_data(sh_ram_write_data     ),
    .w_en(  sh_ram_write_enable   )
);






// Union Mag S Per Hue Color Range


reg                                                     s_ram_read_enable       = 1 ;
reg                 [address_len - 1 : 0]               s_ram_read_addr             ;
wire                [q_full - 1 : 0]                    s_ram_read_data             ;
reg                                                     s_ram_write_enable          ;
reg                 [address_len - 1 : 0]               s_ram_write_addr            ;
reg                 [q_full - 1 : 0]                    s_ram_write_data            ;


memory_list #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(hue_color_range_count * crop_count * crop_count)
    // .initial_file("./zeros_384_48.mem")
) s_ram(
    .clk(clk),
    .r_addr(s_ram_read_addr      ),
    .r_data(s_ram_read_data      ),
    .r_en(  s_ram_read_enable    ),
    .w_addr(s_ram_write_addr     ),
    .w_data(s_ram_write_data     ),
    .w_en(  s_ram_write_enable   )
);





// Union Mag XB Per Hue Color Range


reg                                                     xb_ram_read_enable       = 1 ;
reg                 [address_len - 1 : 0]               xb_ram_read_addr             ;
wire                [q_full - 1 : 0]                    xb_ram_read_data             ;
reg                                                     xb_ram_write_enable          ;
reg                 [address_len - 1 : 0]               xb_ram_write_addr            ;
reg                 [q_full - 1 : 0]                    xb_ram_write_data            ;


memory_list #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(hue_color_range_count * crop_count * crop_count)
    // .initial_file("./zeros_384_48.mem")
) xb_ram(
    .clk(clk),
    .r_addr(xb_ram_read_addr      ),
    .r_data(xb_ram_read_data      ),
    .r_en(  xb_ram_read_enable    ),
    .w_addr(xb_ram_write_addr     ),
    .w_data(xb_ram_write_data     ),
    .w_en(  xb_ram_write_enable   )
);




// Union Mag Var Per Hue Color Range


reg                                                     var_ram_read_enable       = 1 ;
reg                 [address_len - 1 : 0]               var_ram_read_addr             ;
wire                [q_full - 1 : 0]                    var_ram_read_data             ;
reg                                                     var_ram_write_enable          ;
reg                 [address_len - 1 : 0]               var_ram_write_addr            ;
reg                 [q_full - 1 : 0]                    var_ram_write_data            ;


memory_list #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(hue_color_range_count * crop_count * crop_count)
    // .initial_file("./zeros_384_48.mem")
) var_ram(
    .clk(clk),
    .r_addr(var_ram_read_addr      ),
    .r_data(var_ram_read_data      ),
    .r_en(  var_ram_read_enable    ),
    .w_addr(var_ram_write_addr     ),
    .w_data(var_ram_write_data     ),
    .w_en(  var_ram_write_enable   )
);




// SS_SUM RAM


reg                                                     ss_sum_ram_read_enable       = 1 ;
reg                 [address_len - 1 : 0]               ss_sum_ram_read_addr             ;
wire                [q_full - 1 : 0]                    ss_sum_ram_read_data             ;
reg                                                     ss_sum_ram_write_enable          ;
reg                 [address_len - 1 : 0]               ss_sum_ram_write_addr            ;
reg                 [q_full - 1 : 0]                    ss_sum_ram_write_data            ;


memory_list #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(crop_count * crop_count)
) ss_sum_ram(
    .clk(clk),
    .r_addr(ss_sum_ram_read_addr      ),
    .r_data(ss_sum_ram_read_data      ),
    .r_en(  ss_sum_ram_read_enable    ),
    .w_addr(ss_sum_ram_write_addr     ),
    .w_data(ss_sum_ram_write_data     ),
    .w_en(  ss_sum_ram_write_enable   )
);






// VAR_SUM RAM


reg                                                     var_sum_ram_read_enable       = 1 ;
reg                 [address_len - 1 : 0]               var_sum_ram_read_addr             ;
wire                [q_full - 1 : 0]                    var_sum_ram_read_data             ;
reg                                                     var_sum_ram_write_enable          ;
reg                 [address_len - 1 : 0]               var_sum_ram_write_addr            ;
reg                 [q_full - 1 : 0]                    var_sum_ram_write_data            ;


memory_list #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(crop_count * crop_count)
) var_sum_ram(
    .clk(clk),
    .r_addr(var_sum_ram_read_addr      ),
    .r_data(var_sum_ram_read_data      ),
    .r_en(  var_sum_ram_read_enable    ),
    .w_addr(var_sum_ram_write_addr     ),
    .w_data(var_sum_ram_write_data     ),
    .w_en(  var_sum_ram_write_enable   )
);







// SS_SUM_ARG_SORT RAM
// this array contains the argsort results for the var_summ ram

reg                                                     ss_sum_arg_sort_ram_read_enable       = 1 ;
reg                 [address_len - 1 : 0]               ss_sum_arg_sort_ram_read_addr             ;
wire                [q_full - 1 : 0]                    ss_sum_arg_sort_ram_read_data             ;
reg                                                     ss_sum_arg_sort_ram_write_enable          ;
reg                 [address_len - 1 : 0]               ss_sum_arg_sort_ram_write_addr            ;
reg                 [q_full - 1 : 0]                    ss_sum_arg_sort_ram_write_data            ;


memory_list #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(crop_count * crop_count)
    // .initial_file("./enum_64_48.mem")
) var_sum_arg_sort_ram(
    .clk(clk),
    .r_addr(ss_sum_arg_sort_ram_read_addr      ),
    .r_data(ss_sum_arg_sort_ram_read_data      ),
    .r_en(  ss_sum_arg_sort_ram_read_enable    ),
    .w_addr(ss_sum_arg_sort_ram_write_addr     ),
    .w_data(ss_sum_arg_sort_ram_write_data     ),
    .w_en(  ss_sum_arg_sort_ram_write_enable   )
);



// Process 2 RAMs



// red_hist_full_frame_masked_ram
reg                                                     red_hist_full_frame_masked_ram_read_enable       = 1 ;
reg                 [address_len - 1 : 0]               red_hist_full_frame_masked_ram_read_addr             ;
wire                [q_full - 1 : 0]                    red_hist_full_frame_masked_ram_read_data             ;
reg                                                     red_hist_full_frame_masked_ram_write_enable          ;
reg                 [address_len - 1 : 0]               red_hist_full_frame_masked_ram_write_addr            ;
reg                 [q_full - 1 : 0     ]               red_hist_full_frame_masked_ram_write_data            ;


memory_list #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(full_color_range)
    // .initial_file("./zeros_256_48.mem")
    // .initial_file("./red_hist_full_frame_masked.mem")
) red_hist_full_frame_masked_ram(
    .clk(clk),
    .r_addr(   red_hist_full_frame_masked_ram_read_addr      ),
    .r_data(   red_hist_full_frame_masked_ram_read_data      ),
    .r_en(     red_hist_full_frame_masked_ram_read_enable    ),
    .w_addr(   red_hist_full_frame_masked_ram_write_addr     ),
    .w_data(   red_hist_full_frame_masked_ram_write_data     ),
    .w_en(     red_hist_full_frame_masked_ram_write_enable   )
);



// green_hist_full_frame_masked_ram
reg                                                     green_hist_full_frame_masked_ram_read_enable       = 1 ;
reg                 [address_len - 1 : 0]               green_hist_full_frame_masked_ram_read_addr             ;
wire                [q_full - 1 : 0]                    green_hist_full_frame_masked_ram_read_data             ;
reg                                                     green_hist_full_frame_masked_ram_write_enable          ;
reg                 [address_len - 1 : 0]               green_hist_full_frame_masked_ram_write_addr            ;
reg                 [q_full - 1 : 0     ]               green_hist_full_frame_masked_ram_write_data            ;


memory_list #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(full_color_range)
    // .initial_file("./zeros_256_48.mem")
    // .initial_file("./green_hist_full_frame_masked.mem")
) green_hist_full_frame_masked_ram(
    .clk(clk),
    .r_addr(   green_hist_full_frame_masked_ram_read_addr      ),
    .r_data(   green_hist_full_frame_masked_ram_read_data      ),
    .r_en(     green_hist_full_frame_masked_ram_read_enable    ),
    .w_addr(   green_hist_full_frame_masked_ram_write_addr     ),
    .w_data(   green_hist_full_frame_masked_ram_write_data     ),
    .w_en(     green_hist_full_frame_masked_ram_write_enable   )
);



// blue_hist_full_frame_masked_ram
reg                                                     blue_hist_full_frame_masked_ram_read_enable       = 1 ;
reg                 [address_len - 1 : 0]               blue_hist_full_frame_masked_ram_read_addr             ;
wire                [q_full - 1 : 0]                    blue_hist_full_frame_masked_ram_read_data             ;
reg                                                     blue_hist_full_frame_masked_ram_write_enable          ;
reg                 [address_len - 1 : 0]               blue_hist_full_frame_masked_ram_write_addr            ;
reg                 [q_full - 1 : 0     ]               blue_hist_full_frame_masked_ram_write_data            ;


memory_list #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(full_color_range)
    // .initial_file("./zeros_256_48.mem")
    // .initial_file("./blue_hist_full_frame_masked.mem")
) blue_hist_full_frame_masked_ram(
    .clk(clk),
    .r_addr(   blue_hist_full_frame_masked_ram_read_addr      ),
    .r_data(   blue_hist_full_frame_masked_ram_read_data      ),
    .r_en(     blue_hist_full_frame_masked_ram_read_enable    ),
    .w_addr(   blue_hist_full_frame_masked_ram_write_addr     ),
    .w_data(   blue_hist_full_frame_masked_ram_write_data     ),
    .w_en(     blue_hist_full_frame_masked_ram_write_enable   )
);






// grayhist_full_frame_masked_ram

reg                                                     gray_hist_full_frame_masked_ram_read_enable       = 1 ;
reg                 [address_len - 1 : 0]               gray_hist_full_frame_masked_ram_read_addr             ;
wire                [q_full - 1 : 0]                    gray_hist_full_frame_masked_ram_read_data             ;
reg                                                     gray_hist_full_frame_masked_ram_write_enable          ;
reg                 [address_len - 1 : 0]               gray_hist_full_frame_masked_ram_write_addr            ;
reg                 [q_full - 1 : 0     ]               gray_hist_full_frame_masked_ram_write_data            ;


memory_list #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(full_color_range)
    // .initial_file("./zeros_256_48.mem")
    // .initial_file("./gray_hist_full_frame_masked.mem")
) gray_hist_full_frame_masked_ram(
    .clk(clk),
    .r_addr(   gray_hist_full_frame_masked_ram_read_addr      ),
    .r_data(   gray_hist_full_frame_masked_ram_read_data      ),
    .r_en(     gray_hist_full_frame_masked_ram_read_enable    ),
    .w_addr(   gray_hist_full_frame_masked_ram_write_addr     ),
    .w_data(   gray_hist_full_frame_masked_ram_write_data     ),
    .w_en(     gray_hist_full_frame_masked_ram_write_enable   )
);






































// YCRCB Source Full Frame RAM (24-bit HSV)

reg                                                     source_frame_ycbcr_mem_read_enable    = 1 ;
reg                 [address_len - 1 : 0]               source_frame_ycbcr_mem_read_addr      ;
wire                [sum_bpu_full - 1 	: 0]            source_frame_ycbcr_mem_read_data      ;
reg                                                     source_frame_ycbcr_mem_write_enable   ;
reg                 [address_len - 1 : 0]               source_frame_ycbcr_mem_write_addr     ;
reg                 [sum_bpu_full - 1 	: 0]            source_frame_ycbcr_mem_write_data     ;

memory_list #(
    .mem_width(sum_bpu_full),
    .address_len(address_len),
    .mem_depth(width * height)
    // .initial_file("./frame_112_80_hsv_888_shuttle.mem")
    // .initial_file("./frame_320_240_hsv_888_shuttle.mem")
) source_frame_ycbcr(
    .clk(clk),
    .r_addr(source_frame_ycbcr_mem_read_addr),
    .r_data(source_frame_ycbcr_mem_read_data),
    .r_en(  source_frame_ycbcr_mem_read_enable),
    .w_addr(source_frame_ycbcr_mem_write_addr),
    .w_data(source_frame_ycbcr_mem_write_data),
    .w_en(  source_frame_ycbcr_mem_write_enable)
);




// group Idx Ram
reg                                                     group_idx_mem_read_enable    = 1 ;
reg                 [address_len - 1 : 0]               group_idx_mem_read_addr      ;
wire                [q_full - 1 	: 0]                group_idx_mem_read_data      ;
reg                                                     group_idx_mem_write_enable   ;
reg                 [address_len - 1 : 0]               group_idx_mem_write_addr     ;
reg                 [q_full - 1 	: 0]                group_idx_mem_write_data     ;

memory_list #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(width * height)
) group_idx_mem(
    .clk(clk),
    .r_en(     group_idx_mem_read_enable),
    .r_addr(   group_idx_mem_read_addr),
    .r_data(   group_idx_mem_read_data),
    .w_en(     group_idx_mem_write_enable),
    .w_addr(   group_idx_mem_write_addr),
    .w_data(   group_idx_mem_write_data)

);


/*
this ram masps (A) to (B)
(A), which is also the index of the ram, is the index of the 8 by 8 group
(count: number of 8*8 groups in the frame)
this index is also known as group_counter_N0 

(B): the index of the block

essentially, this rams show to which block, each 8 by 8 group belongs.
*/

reg                                                     group_block_idx_mem_read_enable    = 1 ;
reg                 [address_len - 1 : 0]               group_block_idx_mem_read_addr      ;
wire                [q_full - 1 	: 0]                group_block_idx_mem_read_data      ;
reg                                                     group_block_idx_mem_write_enable   ;
reg                 [address_len - 1 : 0]               group_block_idx_mem_write_addr     ;
reg                 [q_full - 1 	: 0]                group_block_idx_mem_write_data     ;

memory_list #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(groups_count)
) group_block_idx_mem(
    .clk(clk),
    .r_en(     group_block_idx_mem_read_enable),
    .r_addr(   group_block_idx_mem_read_addr),
    .r_data(   group_block_idx_mem_read_data),
    .w_en(     group_block_idx_mem_write_enable),
    .w_addr(   group_block_idx_mem_write_addr),
    .w_data(   group_block_idx_mem_write_data)
);




// 8*8 grouped pixels Ram
reg                                                     eight_by_eight_grouped_mem_read_enable    = 1 ;
reg                 [address_len - 1 : 0]               eight_by_eight_grouped_mem_read_addr      ;
wire                [sum_bpu_full - 1 	: 0]            eight_by_eight_grouped_mem_read_data      ;
reg                                                     eight_by_eight_grouped_mem_write_enable   ;
reg                 [address_len - 1 : 0]               eight_by_eight_grouped_mem_write_addr     ;
reg                 [sum_bpu_full - 1 	: 0]            eight_by_eight_grouped_mem_write_data     ;

memory_list #(
    .mem_width(sum_bpu_full),
    .address_len(address_len),
    .mem_depth(width * height)
) eight_by_eight_grouped_mem(
    .clk(clk),
    .r_en(     eight_by_eight_grouped_mem_read_enable),
    .r_addr(   eight_by_eight_grouped_mem_read_addr),
    .r_data(   eight_by_eight_grouped_mem_read_data),
    .w_en(     eight_by_eight_grouped_mem_write_enable),
    .w_addr(   eight_by_eight_grouped_mem_write_addr),
    .w_data(   eight_by_eight_grouped_mem_write_data)

);






// 2*2 grouped pixels Ram
reg                                                     two_by_two_grouped_mem_read_enable    = 1 ;
reg                 [address_len - 1 : 0]               two_by_two_grouped_mem_read_addr      ;
wire                [sum_bpu_full - 1 	: 0]            two_by_two_grouped_mem_read_data      ;
reg                                                     two_by_two_grouped_mem_write_enable   ;
reg                 [address_len - 1 : 0]               two_by_two_grouped_mem_write_addr     ;
reg                 [sum_bpu_full - 1 	: 0]            two_by_two_grouped_mem_write_data     ;

memory_list #(
    .mem_width(sum_bpu_full),
    .address_len(address_len),
    .mem_depth(width * height)
) two_by_two_grouped_mem(
    .clk(clk),
    .r_en(     two_by_two_grouped_mem_read_enable),
    .r_addr(   two_by_two_grouped_mem_read_addr),
    .r_data(   two_by_two_grouped_mem_read_data),
    .w_en(     two_by_two_grouped_mem_write_enable),
    .w_addr(   two_by_two_grouped_mem_write_addr),
    .w_data(   two_by_two_grouped_mem_write_data)

);





// y dct 8 by 8 Ram
reg                                                     y_dct_mem_read_enable    = 1 ;
reg                 [address_len - 1 : 0]               y_dct_mem_read_addr      ;
wire     signed     [q_full - 1 	: 0]                y_dct_mem_read_data      ;
reg                                                     y_dct_mem_write_enable   ;
reg                 [address_len - 1 : 0]               y_dct_mem_write_addr     ;
reg      signed     [q_full - 1 	: 0]                y_dct_mem_write_data     ;

memory_list_signed #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(width * height)
) y_dct_mem(
    .clk(clk),
    .r_en(     y_dct_mem_read_enable),
    .r_addr(   y_dct_mem_read_addr),
    .r_data(   y_dct_mem_read_data),
    .w_en(     y_dct_mem_write_enable),
    .w_addr(   y_dct_mem_write_addr),
    .w_data(   y_dct_mem_write_data)
);





// cb dct 8 by 8 Ram
reg                                                     cb_dct_mem_read_enable    = 1 ;
reg                 [address_len - 1 : 0]               cb_dct_mem_read_addr      ;
wire     signed     [q_full - 1 	: 0]                cb_dct_mem_read_data      ;
reg                                                     cb_dct_mem_write_enable   ;
reg                 [address_len - 1 : 0]               cb_dct_mem_write_addr     ;
reg      signed     [q_full - 1 	: 0]                cb_dct_mem_write_data     ;

memory_list_signed #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(width * height)
) cb_dct_mem(
    .clk(clk),
    .r_en(     cb_dct_mem_read_enable),
    .r_addr(   cb_dct_mem_read_addr),
    .r_data(   cb_dct_mem_read_data),
    .w_en(     cb_dct_mem_write_enable),
    .w_addr(   cb_dct_mem_write_addr),
    .w_data(   cb_dct_mem_write_data)
);




// cr dct 8 by 8 Ram
reg                                                     cr_dct_mem_read_enable    = 1 ;
reg                 [address_len - 1 : 0]               cr_dct_mem_read_addr      ;
wire     signed     [q_full - 1 	: 0]                cr_dct_mem_read_data      ;
reg                                                     cr_dct_mem_write_enable   ;
reg                 [address_len - 1 : 0]               cr_dct_mem_write_addr     ;
reg      signed     [q_full - 1 	: 0]                cr_dct_mem_write_data     ;

memory_list_signed #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(width * height)
) cr_dct_mem(
    .clk(clk),
    .r_en(     cr_dct_mem_read_enable),
    .r_addr(   cr_dct_mem_read_addr),
    .r_data(   cr_dct_mem_read_data),
    .w_en(     cr_dct_mem_write_enable),
    .w_addr(   cr_dct_mem_write_addr),
    .w_data(   cr_dct_mem_write_data)
);







// jpeg y quantization table : it has to signed because it will be used in mixed expressions
reg                                                     jpeg_y_quantization_table_mem_read_enable    = 1 ;
reg                        [address_len - 1 : 0]        jpeg_y_quantization_table_mem_read_addr      ;
wire            signed     [q_full - 1 	: 0]            jpeg_y_quantization_table_mem_read_data      ;

memory_list_signed #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(64),
    .initial_file("./jpeg_y_quantization_table.mem")
) jpeg_y_quantization_table_mem(
    .clk(clk),
    .r_en(     jpeg_y_quantization_table_mem_read_enable),
    .r_addr(   jpeg_y_quantization_table_mem_read_addr),
    .r_data(   jpeg_y_quantization_table_mem_read_data)
);




// jpeg c quantization table
reg                                                     jpeg_c_quantization_table_mem_read_enable    = 1 ;
reg                        [address_len - 1 : 0]        jpeg_c_quantization_table_mem_read_addr      ;
wire            signed     [q_full - 1 	: 0]            jpeg_c_quantization_table_mem_read_data      ;

memory_list_signed #(
    .mem_width(q_full),
    .address_len(address_len),
    .mem_depth(64),
    .initial_file("./jpeg_c_quantization_table.mem")
) jpeg_c_quantization_table_mem(
    .clk(clk),
    .r_en(     jpeg_c_quantization_table_mem_read_enable),
    .r_addr(   jpeg_c_quantization_table_mem_read_addr),
    .r_data(   jpeg_c_quantization_table_mem_read_data)
);







/*
this memory contains uncompressed bitstream resulted from jpeg quantization and serialization
first goes the y and then cb and cr
each of the three take as many rows with respects to their depth.

sig_group_counts = top_blocks_count * groups_per_block
jpeg_serializable_values_count   = sig_group_counts * (dct_depth_y + 2 * dct_depth_c);

*/
// jpeg uncompressed bitstream
reg                                                     jpeg_serialized_mem_read_enable    = 1 ;
reg                 [address_len - 1 : 0]               jpeg_serialized_mem_read_addr      ;
wire     signed     [8 - 1 	: 0]                jpeg_serialized_mem_read_data      ;
reg                                                     jpeg_serialized_mem_write_enable   ;
reg                 [address_len - 1 : 0]               jpeg_serialized_mem_write_addr     ;
reg      signed     [8 - 1 	: 0]                jpeg_serialized_mem_write_data     ;

memory_list_signed #(
    .mem_width(8),
    .address_len(address_len),
    .mem_depth(jpeg_serializable_values_count)
) jpeg_serialized_mem(
    .clk(clk),
    .r_en(     jpeg_serialized_mem_read_enable),
    .r_addr(   jpeg_serialized_mem_read_addr),
    .r_data(   jpeg_serialized_mem_read_data),
    .w_en(     jpeg_serialized_mem_write_enable),
    .w_addr(   jpeg_serialized_mem_write_addr),
    .w_data(   jpeg_serialized_mem_write_data)
);



// Flags

// process 1 flags:
reg                                                     reset_rams_flag  = 0 ;
reg                                                     build_um_aux_frame_flag = 0;
reg                                                     populate_block_idx_flag = 0;
reg                                                     dump_source_frame_rgb_to_file_flag  = 0 ;
reg                                                     dump_aeb_frame_to_file_flag     = 0 ;
reg                                                     dump_hue_hist_full_frame_mem_to_file_flag = 0 ; 

reg                                                     compress_aeb_flag               = 0 ;
reg                                                     generate_aux_frame_flag              = 0 ;
reg                                                     convert_source_rgb_to_hsv_flag  = 0 ; // to convert 24 bit RGB values to 24 bit HSV values
reg                                                     convert_source_rgb_to_grey_flag  = 0 ; // to convert 24 bit RGB values to 24 bit HSV values

reg                                                     calculate_hue_histogram_flag    = 0 ; 
reg                                                     sort_hue_hist_flag     = 0 ;
reg                                                     find_excluded_hues_flag         = 0 ;
reg                                                     build_hue_hist_for_masked_full_frame_flag = 0 ;
reg                                                     normalize_hue_hist_for_masked_full_frame_flag = 0 ;
reg                                                     print_hue_hist_sorted_by_count_flag = 0;


reg                                                     build_hue_hist_blocks_flag      = 0 ;
reg                                                     build_union_mags_flag      = 0 ;
reg                                                     dump_hue_hist_blocks_mem_to_file_flag = 0 ; 
reg                                                     dump_union_mags_to_file_flag = 0 ; 

// the below two flags need go high together
reg                                                     process_union_mag_per_hue_color_range_for_all_blocks_flag = 0;


reg                                                     dump_ss_mem_to_file_flag=0;

reg                                                     calculate_xb_mem_flag=0;
reg                                                     calculate_var_nominator_flag=0;
reg                                                     calculate_var_flag=0;



reg                                                     populate_ss_sum_and_var_sum_flag=0;
reg                                                     build_arg_sort_of_ss_sum_ram_flag=0;

reg                                                     print_arg_sort_of_ss_sum_ram_flag=0;
reg                                                     get_most_significant_block_idxs_flag = 0;

// Process 2 flags
reg                                                     build_frame_ram_with_hue_included_mask_flag = 0;
reg                                                     get_color_hists_for_masked_full_frame = 0;
reg                                                     get_remaining_pixels_count_for_rgb_hists_flag = 0;
reg                                                     get_base_points_caps_flag = 0;
reg                                                     get_base_points_flag = 0;
reg                                                     finalize_base_points_flag = 0;

// Process 3 flags
reg                                                     umapper_decoder_active_flag = 0;
reg                                                     dump_decoded_rgb_to_file_flag = 0;







// ########################################################################################################################################################################################
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################

// Reset
always @(posedge reset) begin

    // full parallel run
    reset_rams_flag                         = 1;
    populate_block_idx_flag                 = 1;

    gray_base_points                        = 256'd1;
    red_base_points                         = 256'd1;
    green_base_points                       = 256'd1;
    blue_base_points                        = 256'd1;


    // excluded hue
    // 0011011001010010000101000000100000000000001000000000000001000000101001100110011101111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111101100011110010111111111111111111111111111101
    
    // red_base_points = 256'b1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111;
    // green_base_points = 256'b1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111;
    // blue_base_points = 256'b1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111;
    // gray_base_points = 256'b1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111;
    // // most_significant_block_idxs = 64'b1111111111111111111110100111000000110000000100000011000000000000;
    // most_significant_block_idxs =    64'b0000000000000000000000000000000000000000000100000010000000000000;
    // decoder_stage = decoder_stage_controller;



    if (top_blocks_count == crop_count * crop_count) begin
        ranger_is_activated = 0;

    end else begin
        ranger_is_activated = 1;

    end



    if ((width * height) > (full_color_range * crop_count * crop_count)) begin
        ram_reset_counter_cap = width * height;

    end else begin
        ram_reset_counter_cap = full_color_range * crop_count * crop_count;
        
    end




    if (crop_count == 8) begin
        one_over_crop_count = nt_aeb.one_over_eight_hp;

    end else if (crop_count == 4) begin
        one_over_crop_count = nt_aeb.one_over_four_hp;

    end else if (crop_count == 2) begin
        one_over_crop_count = nt_aeb.one_over_two_hp;

    end else if (crop_count == 10) begin
        one_over_crop_count = nt_aeb.one_over_ten_hp;

    end





    // task manager parameters

    ram_reset_is_done_milestone                     = 0;
    block_idx_mem_is_populated_milestone            = 0;
    group_idx_mem_is_populated_milestone            = 0;
    excluded_hues_is_populated_milestone            = 0;
    um_aux_frame_is_populated_milestone             = 0;
    build_hsv_frame_is_finished_milestone           = 0;
    most_significant_block_idxs_populated_milestone = 0;
    um_base_points_are_populated_milestone          = 0;


    task_manager_aux_flag_0            = 1;
    task_manager_aux_flag_1            = 1;
    task_manager_aux_flag_2            = 1;
    task_manager_aux_flag_3            = 1;
    task_manager_aux_flag_4            = 1;
    task_manager_aux_flag_5            = 1;
    task_manager_aux_flag_6            = 1;
    task_manager_aux_flag_7            = 1;










    // process 1
    output_file_source_gray_frame               =   $fopen("./um_dumps/output_file_source_gray_frame.txt",  "w");
    output_file_source_hsv_frame                =   $fopen("./um_dumps/output_file_source_hsv_frame.txt",  "w");
    output_file_source_hue_frame                =   $fopen("./um_dumps/output_file_source_hue_frame.txt",  "w");
    output_file_obtained_hue                    =   $fopen("./um_dumps/output_file_obtained_hue.txt",  "w");
    output_file_aeb_frame                       =   $fopen("./um_dumps/output_file_aeb_frame.txt",         "w");
    output_file_hue_hist_full_frame             =   $fopen("./um_dumps/output_file_hue_hist_full_frame.txt","w");
    output_file_hue_hist_blocks                 =   $fopen("./um_dumps/output_file_hue_hist_blocks.txt",   "w");
    output_file_union_mags                      =   $fopen("./um_dumps/output_file_union_mags.txt",   "w");
    output_file_ss                              =   $fopen("./um_dumps/output_file_ss.txt",   "w");

    // process 2
    output_file_masked_rgb_frame                =   $fopen("./um_dumps/output_file_masked_rgb_frame.txt",  "w");
    output_file_masked_gray_frame               =   $fopen("./um_dumps/output_file_masked_gray_frame.txt",  "w");
    output_file_red_hist_full_frame_masked      =   $fopen("./um_dumps/output_file_red_hist_full_frame_masked.txt","w");
    output_file_green_hist_full_frame_masked    =   $fopen("./um_dumps/output_file_green_hist_full_frame_masked.txt","w");
    output_file_blue_hist_full_frame_masked     =   $fopen("./um_dumps/output_file_blue_hist_full_frame_masked.txt","w");
    output_file_gray_hist_full_frame_masked     =   $fopen("./um_dumps/output_file_gray_hist_full_frame_masked.txt","w");

    // process 3
    output_file_decoded_rgb                     =   $fopen("./um_dumps/output_file_decoded_rgb.txt","w");

    output_file_source_ycbcr_frame              =   $fopen("./jpeg_dumps/output_file_source_ycbcr_frame.txt","w");
    output_file_eight_by_eight_grouped          =   $fopen("./jpeg_dumps/output_file_eight_by_eight_grouped.txt","w");
    output_file_two_by_two_grouped              =   $fopen("./jpeg_dumps/output_file_two_by_two_grouped.txt","w");
    output_file_y_dct                           =   $fopen("./jpeg_dumps/output_file_y_dct.txt","w");
    output_file_cb_dct                          =   $fopen("./jpeg_dumps/output_file_cb_dct.txt","w");
    output_file_cr_dct                          =   $fopen("./jpeg_dumps/output_file_cr_dct.txt","w");
    output_file_jpeg_serialized                 =   $fopen("./jpeg_dumps/output_file_jpeg_serialized.txt","w");
                                                 

    // excluded_hues = 256'010110100100001000000000000001000000000000000100101101111111111111111111000000000000000000000000000000000000000000000000000000000000000000001111111111100111111111111111111111111111;
                        // 011100010000001000000000000001000000000000000100101011111111111111111111000000000000000000000000000000000000000000000000000000000000000000001111111111100111111111111111111111111111


    // A --------------

    counter_A0                      = 0;
    lagger_A0                       = 0;

    r_full_q_A0                     = 0;
    g_full_q_A0                     = 0;
    b_full_q_A0                     = 0;

    gray_to_rgb_dump_A0             = 0;


    counter_A1                      = 0;
    lagger_A1                       = 0;

    r_full_q_A1                     = 0;
    g_full_q_A1                     = 0;
    b_full_q_A1                     = 0;

    hsv_value_A1                       = 0;


    rgb_to_hsv_go                   = 0;
    rgb_to_hsv_r                    = 0;
    rgb_to_hsv_g                    = 0;
    rgb_to_hsv_b                    = 0;



    // B --------------

    hue_hist_full_frame_sum_B2    = 0;
    sum_of_remaining_pixels_B3         = 0;
    hue_hist_full_frame_norm_sum_B4      = 0;

    lagger_B0                       = 0;
    lagger_B2                       = 0;
    lagger_B3                       = 0;
    lagger_B4                       = 0;

    counter_B0                      = 0;
    counter_B2                      = 0;
    counter_B3                      = 0;
    counter_B4                      = 0;

    hue_B0                          = 0;
    hue_B3                          = 0;

    hue_hist_sorter_stage                   = hue_hist_sorter_stage_looping;

    hue_hist_sorter_counter                 = 0;
    hue_hist_sorter_read_lag_counter        = 0;
    hue_hist_sorter_write_lag_counter       = 0;
    hue_hist_sorter_temp_var_count_1        = 0;
    hue_hist_sorter_temp_var_count_2        = 0;
    hue_hist_sorter_temp_var_hue_value_1    = 0;
    hue_hist_sorter_temp_var_hue_value_2    = 0;
    hue_hist_sorter_bump_flag               = 0;
    hue_hist_sorter_total_counter           = 0;

    excluded_hues                   = 0;


    // C --------------

    counter_C0                      = 0;
    lagger_C0                       = 0;

    counter_C1                      = 0;
    counter_C1_hue                  = 0;
    lagger_C1                       = 0;

    block_counter_C0                = 0;

    width_full_q_C0                 = width << q_half;

    hue_C0 = 0;

    hue_hist_blocks_sum_C           = 0;
    hue_hist_blocks_norm_sum_C      = 0;
    normalized_hue_of_blocks_C      = 0;
    union_mag_C                     = 0;
    union_mag_sum_C                 = 0;

    full_hue_range_full_q           = full_hue_range;

    // D --------------

    lagger_D0                       = 0;
    block_counter_D0                = 0;
    all_blocks_hue_counter_D0       = 0;
    hue_counter_D0                  = 0;

    lagger_D1                       = 0;
    counter_D1                      = 0;

    lagger_D2                       = 0;
    all_blocks_hue_counter_D2       = 0;
    hue_counter_D2                  = 0;
    block_counter_D2                = 0;

    lagger_D3                       = 0;
    counter_D3                      = 0;

    lagger_D4                       = 0;
    counter_D4                      = 0;



    demeaned                        = 0;
    hue_full_q                      = 0;
    ss_sum                          = 0;
    var_sum                         = 0;
    ss_sum_counter                  = 0;


    updater_stage = updater_stage_disactive;

    ss_sum_sorter_counter           = 0;
    ss_sum_sorter_read_lag_counter  = 0;
    ss_sum_sorter_write_lag_counter = 0;

    ss_sum_sorter_var_idx_1         = 0;
    ss_sum_sorter_var_idx_2         = 0;

    ss_sum_sorter_var_ss_sum_1      = 0;
    ss_sum_sorter_var_ss_sum_2      = 0;

    ss_sum_sorter_bump_flag         = 0;
    ss_sum_sorter_total_counter     = 0;
    ss_sum_sorter_stage             = ss_sum_sorter_stage_looping;


    lagger_D5_1                     = 0;
    lagger_D5_2                     = 0;
    block_counter_D5                = 0;
    sub_block_counter_D5            = 0;


    lagger_D7                       = 0;
    counter_D7                      = 0;


    nondominated_blocks             = {(crop_count * crop_count) {1'b1}};
    nondominated_blocks_zero_mask   = 0;
    most_significant_block_idxs     = 0;

    candidate_block_ss_sum          = 0;
    candidate_block_var_sum         = 0;
    dominion_status_results         = 0;

    none_dominated_blocks_count = crop_count * crop_count; 
    total_blocks_needed             = 0;
    dominated_blocks_needed         = 0;




    // E --------------

    lagger_E0                       = 0;
    counter_E0                      = 0;
    hue_E0                          = 0;
    lagger_E1                       = 0;
    counter_E1                      = 0;

    red_E1                          = 0;
    green_E1                        = 0;
    blue_E1                         = 0;
    gray_E1                         = 0;

    lagger_E2                       = 0;
    counter_E2                      = 0;
    lagger_E3                       = 0;
    lagger_E4                       = 0;
    counter_E4                      = 0;
    lagger_E5                       = 0;
    counter_E5                      = 0;



    remaining_pixels_count_red_hist =   0;
    remaining_pixels_count_green_hist = 0;
    remaining_pixels_count_blue_hist =  0;
    remaining_pixels_count_gray_hist =  0;

    basepoint_cap_red               = 0;
    basepoint_cap_green             = 0;
    basepoint_cap_blue              = 0;
    basepoint_cap_gray              = 0;

    red_hist_cum_var                = 0;
    green_hist_cum_var              = 0;
    blue_hist_cum_var               = 0;
    gray_hist_cum_var               = 0;


    base_point_count_red            = 1;
    base_point_count_green          = 1;
    base_point_count_blue           = 1;
    base_point_count_gray           = 1;


    // ENCODER --------------
    umapper_stage                               = umapper_stage_finished;
    encoder_aeb                                 = 0;
    umapper_lagger_1                            = 0;
    umapper_lagger_2                            = 0;
    encoder_start_pixel_address                 = 0;
    encoder_end_pixel_address                   = 0;
    encoder_block_position                      = 0;
    encoder_block_row                           = 0;
    encoder_block_col                           = 0;
    encoder_pixel_block_column_counter          = 0;
    encoder_pixel_block_counter                 = 0;
    encoder_total_pixel_counter                 = 0;
    encoder_block_counter                       = 0;
    encoder_pixel_counter                       = 0;

    encoder_r_full_q                            = 0;
    encoder_g_full_q                            = 0;
    encoder_b_full_q                            = 0;
    encoder_gray_full_q                         = 0;



    // DECODER --------------
    decoder_stage                               = decoder_stage_finished;
    decoder_lagger_1                            = 0;
    decoder_lagger_2                            = 0;
    decoder_start_pixel_address                 = 0;
    decoder_end_pixel_address                   = 0;
    decoder_block_position                      = 0;
    decoder_block_row                           = 0;
    decoder_block_col                           = 0;
    decoder_pixel_block_column_counter          = 0;
    decoder_pixel_block_counter                 = 0;
    decoder_total_pixel_counter                 = 0;
    decoder_aeb_counter                         = 0;
    decoder_pixel_counter                       = 0;
    decoder_block_counter                       = 0;

    decoder_r_full_q                            = 0;
    decoder_g_full_q                            = 0;
    decoder_b_full_q                            = 0;
    decoder_gray_full_q                         = 0;





    // K --------------
    counter_K0                                  = 0;
    lagger_K0                                   = 0;
    r_full_q_K0                                 = 0;
    g_full_q_K0                                 = 0;
    b_full_q_K0                                 = 0;
    gray_to_rgb_dump_K0                         = 0;


    // L --------------
    counter_L0                                  = 0;
    lagger_L0                                   = 0;
    pixel_in_group_counter_L0                   = 0;
    group_counter_L0                            = 0 ;
    y_full_q_L0                                 = 0;
    cb_full_q_L0                                = 0;
    cr_full_q_L0                                = 0;
    cb_sum_L0                                   = 0;
    cr_sum_L0                                   = 0;
    over_writting_L0                            = 0;


    // M --------------
    counter_M0                                  = 0;
    lagger_M0                                   = 0;
    target_address_in_two_by_two_M0             = 0;


    h_eight_counter_M0                          = 0;
    v_eight_counter_M0                          = 0;

    group_col_idx_M0                            = 0;
    group_row_idx_M0                            = 0;

    anchor_M0                                   = 0;
    top_anchor_M0                               = 0;

    steps_horizental_from_anchor_M0[0] = 0;
    steps_horizental_from_anchor_M0[1] = steps_horizental_from_anchor_M0[0] + 1;
    steps_horizental_from_anchor_M0[2] = steps_horizental_from_anchor_M0[1] + 3;
    steps_horizental_from_anchor_M0[3] = steps_horizental_from_anchor_M0[2] + 1;
    steps_horizental_from_anchor_M0[4] = steps_horizental_from_anchor_M0[3] + 3;
    steps_horizental_from_anchor_M0[5] = steps_horizental_from_anchor_M0[4] + 1;
    steps_horizental_from_anchor_M0[6] = steps_horizental_from_anchor_M0[5] + 3;
    steps_horizental_from_anchor_M0[7] = steps_horizental_from_anchor_M0[6] + 1;

    steps_vertical_from_top_anchor_M0[0] = 0;
    steps_vertical_from_top_anchor_M0[1] = steps_vertical_from_top_anchor_M0[0] + 2;
    steps_vertical_from_top_anchor_M0[2] = steps_vertical_from_top_anchor_M0[1] + 2 * width - 2;
    steps_vertical_from_top_anchor_M0[3] = steps_vertical_from_top_anchor_M0[2] + 2;
    steps_vertical_from_top_anchor_M0[4] = steps_vertical_from_top_anchor_M0[3] + 2 * width - 2;
    steps_vertical_from_top_anchor_M0[5] = steps_vertical_from_top_anchor_M0[4] + 2;
    steps_vertical_from_top_anchor_M0[6] = steps_vertical_from_top_anchor_M0[5] + 2 * width - 2;
    steps_vertical_from_top_anchor_M0[7] = steps_vertical_from_top_anchor_M0[6] + 2;



    // N --------------
    zig_zag_uvs_N0[0] = 6'b000000;
    zig_zag_uvs_N0[1] = 6'b000001;
    zig_zag_uvs_N0[2] = 6'b001000;
    zig_zag_uvs_N0[3] = 6'b010000;
    zig_zag_uvs_N0[4] = 6'b001001;
    zig_zag_uvs_N0[5] = 6'b000010;
    zig_zag_uvs_N0[6] = 6'b000011;
    zig_zag_uvs_N0[7] = 6'b001010;
    zig_zag_uvs_N0[8] = 6'b010001;
    zig_zag_uvs_N0[9] = 6'b011000;
    zig_zag_uvs_N0[10] = 6'b100000;
    zig_zag_uvs_N0[11] = 6'b011001;
    zig_zag_uvs_N0[12] = 6'b010010;
    zig_zag_uvs_N0[13] = 6'b001011;
    zig_zag_uvs_N0[14] = 6'b000100;
    zig_zag_uvs_N0[15] = 6'b000101;
    zig_zag_uvs_N0[16] = 6'b001100;
    zig_zag_uvs_N0[17] = 6'b010011;
    zig_zag_uvs_N0[18] = 6'b011010;
    zig_zag_uvs_N0[19] = 6'b100001;
    zig_zag_uvs_N0[20] = 6'b101000;
    zig_zag_uvs_N0[21] = 6'b110000;
    zig_zag_uvs_N0[22] = 6'b101001;
    zig_zag_uvs_N0[23] = 6'b100010;
    zig_zag_uvs_N0[24] = 6'b011011;
    zig_zag_uvs_N0[25] = 6'b010100;
    zig_zag_uvs_N0[26] = 6'b001101;
    zig_zag_uvs_N0[27] = 6'b000110;
    zig_zag_uvs_N0[28] = 6'b000111;
    zig_zag_uvs_N0[29] = 6'b001110;
    zig_zag_uvs_N0[30] = 6'b010101;
    zig_zag_uvs_N0[31] = 6'b011100;
    zig_zag_uvs_N0[32] = 6'b100011;
    zig_zag_uvs_N0[33] = 6'b101010;
    zig_zag_uvs_N0[34] = 6'b110001;
    zig_zag_uvs_N0[35] = 6'b111000;
    zig_zag_uvs_N0[36] = 6'b111001;
    zig_zag_uvs_N0[37] = 6'b110010;
    zig_zag_uvs_N0[38] = 6'b101011;
    zig_zag_uvs_N0[39] = 6'b100100;
    zig_zag_uvs_N0[40] = 6'b011101;
    zig_zag_uvs_N0[41] = 6'b010110;
    zig_zag_uvs_N0[42] = 6'b001111;
    zig_zag_uvs_N0[43] = 6'b010111;
    zig_zag_uvs_N0[44] = 6'b011110;
    zig_zag_uvs_N0[45] = 6'b100101;
    zig_zag_uvs_N0[46] = 6'b101100;
    zig_zag_uvs_N0[47] = 6'b110011;
    zig_zag_uvs_N0[48] = 6'b111010;
    zig_zag_uvs_N0[49] = 6'b111011;
    zig_zag_uvs_N0[50] = 6'b110100;
    zig_zag_uvs_N0[51] = 6'b101101;
    zig_zag_uvs_N0[52] = 6'b100110;
    zig_zag_uvs_N0[53] = 6'b011111;
    zig_zag_uvs_N0[54] = 6'b100111;
    zig_zag_uvs_N0[55] = 6'b101110;
    zig_zag_uvs_N0[56] = 6'b110101;
    zig_zag_uvs_N0[57] = 6'b111100;
    zig_zag_uvs_N0[58] = 6'b111101;
    zig_zag_uvs_N0[59] = 6'b110110;
    zig_zag_uvs_N0[60] = 6'b101111;
    zig_zag_uvs_N0[61] = 6'b110111;
    zig_zag_uvs_N0[62] = 6'b111110;
    zig_zag_uvs_N0[63] = 6'b111111;

    zig_zag_index_N1[0] = 0;
    zig_zag_index_N1[1] = 1;
    zig_zag_index_N1[2] = 8;
    zig_zag_index_N1[3] = 16;
    zig_zag_index_N1[4] = 9;
    zig_zag_index_N1[5] = 2;
    zig_zag_index_N1[6] = 3;
    zig_zag_index_N1[7] = 10;
    zig_zag_index_N1[8] = 17;
    zig_zag_index_N1[9] = 24;
    zig_zag_index_N1[10] = 32;
    zig_zag_index_N1[11] = 25;
    zig_zag_index_N1[12] = 18;
    zig_zag_index_N1[13] = 11;
    zig_zag_index_N1[14] = 4;
    zig_zag_index_N1[15] = 5;
    zig_zag_index_N1[16] = 12;
    zig_zag_index_N1[17] = 19;
    zig_zag_index_N1[18] = 26;
    zig_zag_index_N1[19] = 33;
    zig_zag_index_N1[20] = 40;
    zig_zag_index_N1[21] = 48;
    zig_zag_index_N1[22] = 41;
    zig_zag_index_N1[23] = 34;
    zig_zag_index_N1[24] = 27;
    zig_zag_index_N1[25] = 20;
    zig_zag_index_N1[26] = 13;
    zig_zag_index_N1[27] = 6;
    zig_zag_index_N1[28] = 7;
    zig_zag_index_N1[29] = 14;
    zig_zag_index_N1[30] = 21;
    zig_zag_index_N1[31] = 28;
    zig_zag_index_N1[32] = 35;
    zig_zag_index_N1[33] = 42;
    zig_zag_index_N1[34] = 49;
    zig_zag_index_N1[35] = 56;
    zig_zag_index_N1[36] = 57;
    zig_zag_index_N1[37] = 50;
    zig_zag_index_N1[38] = 43;
    zig_zag_index_N1[39] = 36;
    zig_zag_index_N1[40] = 29;
    zig_zag_index_N1[41] = 22;
    zig_zag_index_N1[42] = 15;
    zig_zag_index_N1[43] = 23;
    zig_zag_index_N1[44] = 30;
    zig_zag_index_N1[45] = 37;
    zig_zag_index_N1[46] = 44;
    zig_zag_index_N1[47] = 51;
    zig_zag_index_N1[48] = 58;
    zig_zag_index_N1[49] = 59;
    zig_zag_index_N1[50] = 52;
    zig_zag_index_N1[51] = 45;
    zig_zag_index_N1[52] = 38;
    zig_zag_index_N1[53] = 31;
    zig_zag_index_N1[54] = 39;
    zig_zag_index_N1[55] = 46;
    zig_zag_index_N1[56] = 53;
    zig_zag_index_N1[57] = 60;
    zig_zag_index_N1[58] = 61;
    zig_zag_index_N1[59] = 54;
    zig_zag_index_N1[60] = 47;
    zig_zag_index_N1[61] = 55;
    zig_zag_index_N1[62] = 62;
    zig_zag_index_N1[63] = 63;

    counter_N0                                  = 0;
    lagger_N0                                   = 0;
    counter_N1                                  = 0;
    lagger_N1                                   = 0;
    group_pixel_counter_N0                      = 0;
    group_counter_N0                            = 0;
    sig_group_counter_N0                        = 0;
    u_N1                                        = 0;
    v_N1                                        = 0;
    selected_eight_by_eight_group_N0            = 0;

    if (dct_depth_y > dct_depth_c) begin
        max_dct_depth_N1 = dct_depth_y;
    end else begin
        max_dct_depth_N1 = dct_depth_c;
    end



    if (qt_factor == 1) begin
        qt_factor_reg_N0 = nt_aeb.one_signed;
    end else if (qt_factor == 2) begin
        qt_factor_reg_N0 = nt_aeb.one_over_2_signed;
    end else if (qt_factor == 3) begin
        qt_factor_reg_N0 = nt_aeb.one_over_3_signed;
    end else if (qt_factor == 4) begin
        qt_factor_reg_N0 = nt_aeb.one_over_4_signed;
    end else if (qt_factor == 5) begin
        qt_factor_reg_N0 = nt_aeb.one_over_5_signed;
    end else begin
        qt_factor_reg_N0 = nt_aeb.one_signed;
    end

    $display("qt_factor_reg_N0: %f", SF * qt_factor_reg_N0);
    $display("jpeg_serializable_values_count: %d", jpeg_serializable_values_count);
    $display("sig_groups_count: %d", sig_groups_count);




             if (sum_bpu == 3)  begin bpu_r = 1;   bpu_g = 1;   bpu_b = 1;
    end else if (sum_bpu == 4)  begin bpu_r = 2;   bpu_g = 1;   bpu_b = 1;
    end else if (sum_bpu == 5)  begin bpu_r = 2;   bpu_g = 2;   bpu_b = 1;
    end else if (sum_bpu == 6)  begin bpu_r = 2;   bpu_g = 2;   bpu_b = 2;
    end else if (sum_bpu == 7)  begin bpu_r = 3;   bpu_g = 2;   bpu_b = 2;
    end else if (sum_bpu == 8)  begin bpu_r = 3;   bpu_g = 3;   bpu_b = 2;
    end else if (sum_bpu == 9)  begin bpu_r = 3;   bpu_g = 3;   bpu_b = 3;
    end else if (sum_bpu == 10) begin bpu_r = 4;   bpu_g = 3;   bpu_b = 3;
    end else if (sum_bpu == 11) begin bpu_r = 4;   bpu_g = 4;   bpu_b = 3;
    end else if (sum_bpu == 12) begin bpu_r = 4;   bpu_g = 4;   bpu_b = 4;
    end else if (sum_bpu == 13) begin bpu_r = 5;   bpu_g = 4;   bpu_b = 4;
    end else if (sum_bpu == 14) begin bpu_r = 5;   bpu_g = 5;   bpu_b = 4;
    end else if (sum_bpu == 15) begin bpu_r = 5;   bpu_g = 5;   bpu_b = 5;
    end else if (sum_bpu == 16) begin bpu_r = 6;   bpu_g = 5;   bpu_b = 5;
    end else if (sum_bpu == 17) begin bpu_r = 6;   bpu_g = 6;   bpu_b = 5;
    end else if (sum_bpu == 18) begin bpu_r = 6;   bpu_g = 6;   bpu_b = 6;
    end else if (sum_bpu == 19) begin bpu_r = 7;   bpu_g = 6;   bpu_b = 6;
    end else if (sum_bpu == 20) begin bpu_r = 7;   bpu_g = 7;   bpu_b = 6;
    end else if (sum_bpu == 21) begin bpu_r = 7;   bpu_g = 7;   bpu_b = 7;
    end else if (sum_bpu == 22) begin bpu_r = 8;   bpu_g = 7;   bpu_b = 7;
    end else if (sum_bpu == 23) begin bpu_r = 8;   bpu_g = 8;   bpu_b = 7;
    end else if (sum_bpu == 24) begin bpu_r = 8;   bpu_g = 8;   bpu_b = 8;
    end

    // $display("sum_bpu:%d, bpu_r:%d, bpu_g:%d, bpu_b:%d", sum_bpu, bpu_r, bpu_g, bpu_b);


    full_q_crop_count = crop_count << q_half;


    two_to_bpu_r_minus_one = ('d2 << (bpu_r - 'd1)) << q_half;
    two_to_bpu_g_minus_one = ('d2 << (bpu_g - 'd1)) << q_half;
    two_to_bpu_b_minus_one = ('d2 << (bpu_b - 'd1)) << q_half;


    max_base_point_count_red    = 2 << (bpu_r - 1);
    max_base_point_count_green  = 2 << (bpu_g - 1);
    max_base_point_count_blue   = 2 << (bpu_b - 1);
    max_base_point_count_gray   = 2 << (sum_bpu - 1);


    r_mask = ((1 << bpu_r) - 1) << (bpu_g + bpu_b);
    g_mask = ((1 << bpu_g) - 1) << (bpu_b);
    b_mask = ((1 << bpu_b) - 1);

    full_r_mask = ((1 << 8) - 1) << (16);
    full_g_mask = ((1 << 8) - 1) << (8);
    full_b_mask = ((1 << 8) - 1);
    full_h_mask = ((1 << 8) - 1) << (16);


    // $display("r_mask: %b", r_mask);
    // $display("g_mask: %b", g_mask);
    // $display("b_mask: %b", b_mask);

    // $display("full_r_mask: %b", full_r_mask);
    // $display("full_g_mask: %b", full_g_mask);
    // $display("full_b_mask: %b", full_b_mask);


    $display("\n__________________\n");




        // 24'b001001110000000100000000




    // r_full_q = 'd165;
    // g_full_q = 'd196;
    // b_full_q = 'd251;

    // gray = nt_aeb.rgb_to_y(r_full_q, g_full_q, b_full_q);

    // $display("%b", gray);


    // r_full_q = nt_aeb.get_aeb(red_base_points, r_full_q);
    // aeb =       r_full_q << (bpu_g + bpu_b);
    // g_full_q = nt_aeb.get_aeb(green_base_points, g_full_q);
    // aeb = aeb + (g_full_q << bpu_b);
    // b_full_q = nt_aeb.get_aeb(blue_base_points, b_full_q);
    // aeb = aeb + b_full_q;

    // $display("r_full_q:%b, g_full_q:%b, b_full_q:%b", r_full_q, g_full_q, b_full_q);
    // $display("aeb:%b", aeb);





    // r_full_q = 24'b001101100110100011001001 & r_mask;
    // g_full_q = 24'b001101100110100011001001 & g_mask;
    // b_full_q = 24'b001101100110100011001001 & b_mask;

    // r_full_q = r_full_q >> (bpu_g + bpu_b);
    // g_full_q = g_full_q >> bpu_b;

 
    // $display("r_full_q:%d, g_full_q:%d, b_full_q:%d", r_full_q, g_full_q, b_full_q);

    // r_full_q = nt_aeb.aeb_to_basepoint(red_base_points, r_full_q);
    // g_full_q = nt_aeb.aeb_to_basepoint(green_base_points, g_full_q);
    // b_full_q = nt_aeb.aeb_to_basepoint(blue_base_points, b_full_q);

    // $display("extracted ----------r_full_q:%d, g_full_q:%d, b_full_q:%d", r_full_q, g_full_q, b_full_q);

    // decoded_frame_rgb_mem_write_data =   (r_full_q << 16) + (g_full_q << 8) + (b_full_q);
    
    // $display("decoded_frame_rgb_mem_write_data:%d", decoded_frame_rgb_mem_write_data);

end


reg    [5 : 0]     task_manager_counter = 0;


// milestones

reg     ram_reset_is_done_milestone;
reg     block_idx_mem_is_populated_milestone;
reg     group_idx_mem_is_populated_milestone;
reg     excluded_hues_is_populated_milestone;
reg     um_aux_frame_is_populated_milestone;
reg     build_hsv_frame_is_finished_milestone;
reg     most_significant_block_idxs_populated_milestone;
reg     um_base_points_are_populated_milestone;

reg     task_manager_aux_flag_0;
reg     task_manager_aux_flag_1;
reg     task_manager_aux_flag_2;
reg     task_manager_aux_flag_3;
reg     task_manager_aux_flag_4;
reg     task_manager_aux_flag_5;
reg     task_manager_aux_flag_6;
reg     task_manager_aux_flag_7;



always @(negedge clk) begin
    
    task_manager_counter = task_manager_counter + 1;

    if (task_manager_counter == 1) begin
        if (ram_reset_is_done_milestone && block_idx_mem_is_populated_milestone && task_manager_aux_flag_0) begin
            $display("---------------- colected two milestones: ram_reset_is_done_milestone and block_idx_mem_is_populated_milestone");
            


            if (exclude_insignificant_blocks_option == 0) begin
                // top_blocks_count = crop_count * crop_count;


                most_significant_block_idxs = (2 << (crop_count * crop_count - 1)) - 1;
                // most_significant_block_idxs = 4'b1010;
                $display("no need to calculate significant blocks. it is set to %b", most_significant_block_idxs);
                most_significant_block_idxs_populated_milestone = 1;

                
                excluded_hues = 0;
                excluded_hues_is_populated_milestone = 1;


                if (use_jpeg_compression == 0) begin
                    build_um_aux_frame_flag = 1;
                end else begin
                    $display("strating jpeg");
                    convert_source_rgb_to_ycbcr_flag = 1;
                end

            end
            else begin

                $display("going ahead with convert_source_rgb_to_hsv_flag");
                convert_source_rgb_to_hsv_flag = 1;


            end


            task_manager_aux_flag_0 = 0;

        end



    end else if (task_manager_counter == 2) begin
        if (build_hsv_frame_is_finished_milestone && task_manager_aux_flag_1) begin
            $display("---------------- build_hsv_frame_is_finished_milestone");

            if (use_jpeg_compression == 0) begin
                build_um_aux_frame_flag = 1;
            end

            task_manager_aux_flag_1 = 0;

        end




    // start finding the most significant blocks
    // end else if (task_manager_counter == 3) begin
    //     if (um_aux_frame_is_populated_milestone && ( exclude_insignificant_blocks_option == 1) && task_manager_aux_flag_2) begin

    //         calculate_hue_histogram_flag = 1;

    //         task_manager_aux_flag_2 = 0;
    //     end


    // going ahead with umapper
    end else if (task_manager_counter == 5) begin
        if (um_aux_frame_is_populated_milestone && excluded_hues_is_populated_milestone && (use_jpeg_compression==0) && task_manager_aux_flag_3) begin
            $display("---------------- colected two milestones: excluded_hues_is_populated_milestone and um_aux_frame_is_populated_milestone and we  not doing jpeg");
            $display("go ahead with umapper. start to calculate masked aux frame and eventually calculate the basepoints for umapper");
            build_frame_ram_with_hue_included_mask_flag = 1;
            task_manager_aux_flag_3 = 0;

        end

    end else if (task_manager_counter == 6) begin
        if (most_significant_block_idxs_populated_milestone && um_base_points_are_populated_milestone && (use_jpeg_compression==0) && task_manager_aux_flag_4) begin
            $display("---------------- colected two milestones: most_significant_block_idxs_populated_milestone and um_base_points_are_populated_milestone");
            $display("go ahead to run the umapper");
            umapper_stage =  umapper_stage_controller;
            task_manager_aux_flag_4 = 0;

        end

    end else if (task_manager_counter == 10) begin
        task_manager_counter = 0;

    end

end










reg                 [q_full - 1 : 0]                    ram_reset_counter_cap;

reg                 [q_full - 1 : 0]                    pixel_counter_ram_reset                 = 0;
reg                 [q_full - 1 : 0]                    pixel_reader_lag_counter_ram_reset      = 0;


always @(negedge clk) begin
    if (reset_rams_flag == 1) begin
        pixel_reader_lag_counter_ram_reset = pixel_reader_lag_counter_ram_reset + 1;

        if (pixel_reader_lag_counter_ram_reset == 1) begin



            if (pixel_counter_ram_reset < (width * height)) begin
                decoded_frame_rgb_mem_write_addr            = pixel_counter_ram_reset;
                y_dct_mem_write_addr                        = pixel_counter_ram_reset;
                cb_dct_mem_write_addr                       = pixel_counter_ram_reset;
                cr_dct_mem_write_addr                       = pixel_counter_ram_reset;
            
            end

            if (pixel_counter_ram_reset < (hue_color_range_count * crop_count * crop_count)) begin
                ss_ram_write_addr                           = pixel_counter_ram_reset;
                sh_ram_write_addr                           = pixel_counter_ram_reset;
                s_ram_write_addr                            = pixel_counter_ram_reset;
                xb_ram_write_addr                           = pixel_counter_ram_reset;
                var_ram_write_addr                          = pixel_counter_ram_reset;
            end


            if (pixel_counter_ram_reset < (crop_count * crop_count)) begin
                ss_sum_ram_write_addr                       = pixel_counter_ram_reset;
                var_sum_ram_write_addr                      = pixel_counter_ram_reset;
                ss_sum_arg_sort_ram_write_addr              = pixel_counter_ram_reset; // counter
            end


            if (pixel_counter_ram_reset < full_color_range) begin
                red_hist_full_frame_masked_ram_write_addr   = pixel_counter_ram_reset;
                green_hist_full_frame_masked_ram_write_addr = pixel_counter_ram_reset;
                blue_hist_full_frame_masked_ram_write_addr  = pixel_counter_ram_reset;
                gray_hist_full_frame_masked_ram_write_addr  = pixel_counter_ram_reset;
            end


            if (pixel_counter_ram_reset < full_hue_range) begin
                hue_hist_full_frame_mem_write_addr          = pixel_counter_ram_reset;
                hue_values_full_frame_mem_write_addr        = pixel_counter_ram_reset; // counter
            end

            if (pixel_counter_ram_reset < (full_hue_range * crop_count * crop_count)) begin
                hue_hist_blocks_mem_write_addr              = pixel_counter_ram_reset;
            end


            

















        end else if (pixel_reader_lag_counter_ram_reset == 2) begin



            if (pixel_counter_ram_reset < (width * height)) begin
                decoded_frame_rgb_mem_write_data            = 0;
                y_dct_mem_write_data                        = 0;
                cb_dct_mem_write_data                       = 0;
                cr_dct_mem_write_data                       = 0;
            
            end

            if (pixel_counter_ram_reset < (hue_color_range_count * crop_count * crop_count)) begin
                ss_ram_write_data                           = 0;
                sh_ram_write_data                           = 0;
                s_ram_write_data                            = 0;
                xb_ram_write_data                           = 0;
                var_ram_write_data                          = 0;
            end


            if (pixel_counter_ram_reset < (crop_count * crop_count)) begin
                ss_sum_ram_write_data                       = 0;
                var_sum_ram_write_data                      = 0;
                ss_sum_arg_sort_ram_write_data              = pixel_counter_ram_reset; // counter
            end


            if (pixel_counter_ram_reset < full_color_range) begin
                red_hist_full_frame_masked_ram_write_data   = 0;
                green_hist_full_frame_masked_ram_write_data = 0;
                blue_hist_full_frame_masked_ram_write_data  = 0;
                gray_hist_full_frame_masked_ram_write_data  = 0;
            end


            if (pixel_counter_ram_reset < full_hue_range) begin
                hue_hist_full_frame_mem_write_data          = 0;
                hue_values_full_frame_mem_write_data        = pixel_counter_ram_reset; // counter
            end

            if (pixel_counter_ram_reset < (full_hue_range * crop_count * crop_count)) begin
                hue_hist_blocks_mem_write_data              = 0;
            end


























        end else if (pixel_reader_lag_counter_ram_reset == 3) begin




            if (pixel_counter_ram_reset < (width * height)) begin
                decoded_frame_rgb_mem_write_enable            = 1;
                y_dct_mem_write_enable                        = 1;
                cb_dct_mem_write_enable                       = 1;
                cr_dct_mem_write_enable                       = 1;
            end

            if (pixel_counter_ram_reset < (hue_color_range_count * crop_count * crop_count)) begin
                ss_ram_write_enable                           = 1;
                sh_ram_write_enable                           = 1;
                s_ram_write_enable                            = 1;
                xb_ram_write_enable                           = 1;
                var_ram_write_enable                          = 1;
            end


            if (pixel_counter_ram_reset < (crop_count * crop_count)) begin
                ss_sum_ram_write_enable                       = 1;
                var_sum_ram_write_enable                      = 1;
                ss_sum_arg_sort_ram_write_enable              = 1; // counter
            end


            if (pixel_counter_ram_reset < full_color_range) begin
                red_hist_full_frame_masked_ram_write_enable   = 1;
                green_hist_full_frame_masked_ram_write_enable = 1;
                blue_hist_full_frame_masked_ram_write_enable  = 1;
                gray_hist_full_frame_masked_ram_write_enable  = 1;
            end


            if (pixel_counter_ram_reset < full_hue_range) begin
                hue_hist_full_frame_mem_write_enable          = 1;
                hue_values_full_frame_mem_write_enable        = 1; // counter
            end

            if (pixel_counter_ram_reset < (full_hue_range * crop_count * crop_count)) begin
                hue_hist_blocks_mem_write_enable              = 1;
            end




























        end else if (pixel_reader_lag_counter_ram_reset == 4) begin



            
            if (pixel_counter_ram_reset < (width * height)) begin
                decoded_frame_rgb_mem_write_enable            = 0;
                y_dct_mem_write_enable                        = 0;
                cb_dct_mem_write_enable                       = 0;
                cr_dct_mem_write_enable                       = 0;
            end

            if (pixel_counter_ram_reset < (hue_color_range_count * crop_count * crop_count)) begin
                ss_ram_write_enable                           = 0;
                sh_ram_write_enable                           = 0;
                s_ram_write_enable                            = 0;
                xb_ram_write_enable                           = 0;
                var_ram_write_enable                          = 0;
            end


            if (pixel_counter_ram_reset < (crop_count * crop_count)) begin
                ss_sum_ram_write_enable                       = 0;
                var_sum_ram_write_enable                      = 0;
                ss_sum_arg_sort_ram_write_enable              = 0; // counter
            end


            if (pixel_counter_ram_reset < full_color_range) begin
                red_hist_full_frame_masked_ram_write_enable   = 0;
                green_hist_full_frame_masked_ram_write_enable = 0;
                blue_hist_full_frame_masked_ram_write_enable  = 0;
                gray_hist_full_frame_masked_ram_write_enable  = 0;
            end


            if (pixel_counter_ram_reset < full_hue_range) begin
                hue_hist_full_frame_mem_write_enable          = 0;
                hue_values_full_frame_mem_write_enable        = 0; // counter
            end

            if (pixel_counter_ram_reset < (full_hue_range * crop_count * crop_count)) begin
                hue_hist_blocks_mem_write_enable              = 0;
            end







        end else if (pixel_reader_lag_counter_ram_reset == 5) begin

            if (pixel_counter_ram_reset < ram_reset_counter_cap - 1) begin
                pixel_counter_ram_reset = pixel_counter_ram_reset + 1;

            end else begin
                pixel_counter_ram_reset = 0;
                reset_rams_flag = 0;
                $display("finished reset_rams_flag");


                ram_reset_is_done_milestone = 1;
            end


            pixel_reader_lag_counter_ram_reset = 0;

        end 
    end
end











reg                 [q_full - 1 : 0]                    counter_populate_block_ram_idx_Z1                 = 0;
reg                 [q_full - 1 : 0]                    lagger_populate_block_ram_idx_Z1      = 0;


reg                 [q_full - 1 : 0]                    block_col_Z1      = 0;
reg                 [q_full - 1 : 0]                    block_row_Z1      = 0;
reg                 [q_full - 1 : 0]                    pixel_col_counter_Z1      = 0;
reg                 [q_full - 1 : 0]                    pixel_row_counter_Z1      = 0;


reg                 [q_full - 1 : 0]                    group_col_Z2      = 0;
reg                 [q_full - 1 : 0]                    group_row_Z2      = 0;
reg                 [q_full - 1 : 0]                    pixel_col_counter_Z2      = 0;
reg                 [q_full - 1 : 0]                    pixel_row_counter_Z2      = 0;


// this code is used to identify the block to which every pixel belongs
// results are stored in block_idx_mem
always @(negedge clk) begin
    if (populate_block_idx_flag == 1) begin
        lagger_populate_block_ram_idx_Z1 = lagger_populate_block_ram_idx_Z1 + 1;

        if (lagger_populate_block_ram_idx_Z1 == 1) begin

            block_idx_mem_write_addr = counter_populate_block_ram_idx_Z1;
            // group_idx_mem_write_addr = counter_populate_block_ram_idx_Z1;

        end else if (lagger_populate_block_ram_idx_Z1 == 2) begin

            if (pixel_col_counter_Z1 == block_width) begin
                block_col_Z1 = block_col_Z1 + 1;
                pixel_col_counter_Z1 = 0;
            end


            if (block_col_Z1 == crop_count) begin
                block_col_Z1 = 0;
                pixel_row_counter_Z1 = pixel_row_counter_Z1 + 1;
            end

            if (pixel_row_counter_Z1 == block_height) begin
                pixel_row_counter_Z1 = 0;
                block_row_Z1 = block_row_Z1 + 1;
            end

            pixel_col_counter_Z1 = pixel_col_counter_Z1 + 1;

            block_idx_mem_write_data = block_row_Z1 * crop_count + block_col_Z1;


            // $display("counter: %d, block_col_Z1:%d , block_row_Z1:%d, block_idx:%d", 
            // counter_populate_block_ram_idx_Z1,
            // block_col_Z1,
            // block_row_Z1,
            // block_idx_mem_write_data
            
            // );

        end else if (lagger_populate_block_ram_idx_Z1 == 3) begin
            block_idx_mem_write_enable = 1;

        end else if (lagger_populate_block_ram_idx_Z1 == 4) begin
            block_idx_mem_write_enable = 0;






        end else if (lagger_populate_block_ram_idx_Z1 == 5) begin
            
            if (pixel_col_counter_Z2 == 8) begin
                group_col_Z2 = group_col_Z2 + 1;
                pixel_col_counter_Z2 = 0;
            end


            if (group_col_Z2 == width_over_eight) begin // that's a row
                group_col_Z2 = 0;
                pixel_row_counter_Z2 = pixel_row_counter_Z2 + 1;
            end

            if (pixel_row_counter_Z2 == 8) begin
                pixel_row_counter_Z2 = 0;
                group_row_Z2 = group_row_Z2 + 1;
            end

            pixel_col_counter_Z2 = pixel_col_counter_Z2 + 1;

            group_idx_mem_write_data = group_row_Z2 * width_over_eight + group_col_Z2;


            // $display("counter: %d, group_col_Z2:%d , group_row_Z2:%d, group_idx:%d", 
            // counter_populate_block_ram_idx_Z1,
            // group_col_Z2,
            // group_row_Z2,
            // group_idx_mem_write_data
            
            // );

            // $display("counter: %d, group_idx_mem_write_data:%d , block_idx_mem_write_data:%d", 
            // counter_populate_block_ram_idx_Z1,
            // group_idx_mem_write_data,
            // block_idx_mem_write_data            
            // );


        end else if (lagger_populate_block_ram_idx_Z1 == 6) begin
            group_block_idx_mem_write_addr = group_idx_mem_write_data;

        end else if (lagger_populate_block_ram_idx_Z1 == 7) begin
            group_block_idx_mem_write_data = block_idx_mem_write_data;


        end else if (lagger_populate_block_ram_idx_Z1 == 8) begin
            group_block_idx_mem_write_enable = 1;

        end else if (lagger_populate_block_ram_idx_Z1 == 9) begin
            group_block_idx_mem_write_enable = 0;



        end else if (lagger_populate_block_ram_idx_Z1 == 10) begin
            group_idx_mem_write_enable = 1;

        end else if (lagger_populate_block_ram_idx_Z1 == 11) begin
            group_idx_mem_write_enable = 0;




        end else if (lagger_populate_block_ram_idx_Z1 == 12) begin
            if (counter_populate_block_ram_idx_Z1 < width * height - 1) begin
                counter_populate_block_ram_idx_Z1 = counter_populate_block_ram_idx_Z1 + 1;

            end else begin
                counter_populate_block_ram_idx_Z1 = 0;
                populate_block_idx_flag = 0;

                $display("finished populating block_idx ram");
                block_idx_mem_is_populated_milestone = 1;


                // $display("finished populating group_idx ram");
                // group_idx_mem_is_populated_milestone = 1;

            end

            lagger_populate_block_ram_idx_Z1 = 0;

        end 
    end
end










// reg                 [q_full - 1 : 0]                    counter_populate_group_ram_idx_Z2                 = 0;
// reg                 [q_full - 1 : 0]                    lagger_populate_group_ram_idx_Z2      = 0;


// reg                 [q_full - 1 : 0]                    group_col_Z2      = 0;
// reg                 [q_full - 1 : 0]                    group_row_Z2      = 0;
// reg                 [q_full - 1 : 0]                    pixel_col_counter_Z2      = 0;
// reg                 [q_full - 1 : 0]                    pixel_row_counter_Z2      = 0;


// // this code is used to identify the 8*8 pixel group to which every pixel belongs
// // results are stored in group_idx_mem
// always @(negedge clk) begin
//     if (populate_group_idx_flag == 1) begin
//         lagger_populate_group_ram_idx_Z2 = lagger_populate_group_ram_idx_Z2 + 1;

//         if (lagger_populate_group_ram_idx_Z2 == 1) begin

//             group_idx_mem_write_addr = counter_populate_group_ram_idx_Z2;

//         end else if (lagger_populate_group_ram_idx_Z2 == 2) begin

//             if (pixel_col_counter_Z2 == 8) begin
//                 group_col_Z2 = group_col_Z2 + 1;
//                 pixel_col_counter_Z2 = 0;
//             end


//             if (group_col_Z2 == width_over_eight) begin // that's a row
//                 group_col_Z2 = 0;
//                 pixel_row_counter_Z2 = pixel_row_counter_Z2 + 1;
//             end

//             if (pixel_row_counter_Z2 == 8) begin
//                 pixel_row_counter_Z2 = 0;
//                 group_row_Z2 = group_row_Z2 + 1;
//             end

//             pixel_col_counter_Z2 = pixel_col_counter_Z2 + 1;

//             group_idx_mem_write_data = group_row_Z2 * width_over_eight + group_col_Z2;


//             $display("counter: %d, group_col_Z2:%d , group_row_Z2:%d, group_idx:%d", 
//             counter_populate_group_ram_idx_Z2,
//             group_col_Z2,
//             group_row_Z2,
//             group_idx_mem_write_data
            
//             );

//         end else if (lagger_populate_group_ram_idx_Z2 == 3) begin
//             group_idx_mem_write_enable = 1;

//         end else if (lagger_populate_group_ram_idx_Z2 == 4) begin
//             group_idx_mem_write_enable = 0;

//         end else if (lagger_populate_group_ram_idx_Z2 == 5) begin
//             if (counter_populate_group_ram_idx_Z2 < width * height - 1) begin
//                 counter_populate_group_ram_idx_Z2 = counter_populate_group_ram_idx_Z2 + 1;

//             end else begin
//                 counter_populate_group_ram_idx_Z2 = 0;
//                 populate_group_idx_flag = 0;
//                 $display("finished populating group_idx ram");
                
//                 group_idx_mem_is_populated_milestone = 1;
//             end

//             lagger_populate_group_ram_idx_Z2 = 0;

//         end 
//     end
// end
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


reg                 [q_full - 1 : 0]                    counter_B0;
reg                 [laggers_len - 1 : 0]               lagger_B0;
reg                 [laggers_len - 1 : 0]               hue_B0;
reg                 [laggers_len - 1 : 0]               hue_B3;


// Hue Histogram Sorter by Counts
reg                 [address_len - 1 : 0]               hue_hist_sorter_counter                     ;
reg                 [address_len - 1 : 0]               hue_hist_sorter_read_lag_counter            ;
reg                 [address_len - 1 : 0]               hue_hist_sorter_write_lag_counter           ;

reg                 [q_full - 1 : 0]                    hue_hist_sorter_temp_var_count_1           ;
reg                 [q_full - 1 : 0]                    hue_hist_sorter_temp_var_count_2           ;
reg                 [q_full - 1 : 0 ]                   hue_hist_sorter_temp_var_hue_value_1       ;
reg                 [q_full - 1 : 0]                    hue_hist_sorter_temp_var_hue_value_2       ;


// Hue Histogram Sorter by Counts Stages
reg                                                     hue_hist_sorter_stage                       ;
localparam                                              hue_hist_sorter_stage_looping               = 0;
localparam                                              hue_hist_sorter_stage_swapping              = 1;

reg                                                     hue_hist_sorter_bump_flag                   ;
reg                 [ 31 : 0 ]                          hue_hist_sorter_total_counter               ;

reg                                                     hue_hist_sorter_sort_hue;


reg                 [full_hue_range - 1 : 0]            excluded_hues;



reg                 [q_full - 1 : 0]                    counter_B2;
reg                 [laggers_len - 1 : 0]               lagger_B2;

reg                 [q_full - 1 : 0]                    hue_hist_full_frame_sum_B2                        ;   
reg                 [q_full - 1 : 0]                    sum_of_remaining_pixels_B3                        ;   
reg                 [q_full - 1 : 0]                    hue_hist_full_frame_norm_sum_B4                   ;   

reg                 [q_full - 1 : 0]                    counter_B3;
reg                 [laggers_len - 1 : 0]               lagger_B3;

reg                 [q_full - 1 : 0]                    counter_B4;
reg                 [laggers_len - 1 : 0]               lagger_B4;









// Division B4
reg                                                     division_B4_start=0;
wire                                                    division_B4_busy;
wire                                                    division_B4_valid;
wire                                                    division_B4_dbz;
wire                                                    division_B4_ovf;
reg                         [q_full - 1 : 0]            division_B4_x;
reg                         [q_full - 1 : 0]            division_B4_y;
wire                        [q_full - 1 : 0]            division_B4_q;
wire                        [q_full - 1 : 0]            division_B4_r;

division #(
    .width(q_full),
    .floating_bits(q_half)
    ) division_B4 (
        .clk(   clk),
        .start( division_B4_start),
        .busy(  division_B4_busy),
        .valid( division_B4_valid),
        .dbz(   division_B4_dbz),
        .ovf(   division_B4_ovf),
        .x(     division_B4_x),
        .y(     division_B4_y),
        .q(     division_B4_q),
        .r(     division_B4_r)
    );


always @(negedge division_B4_busy) begin
    normalize_hue_hist_for_masked_full_frame_flag = 1;


    if ((division_B4_valid == 0) || (division_B4_ovf == 1)) begin
        $display("!!! diviosn error at B4");

        $display("%d:\t%f \t/ \t%f \t= \t(%f)\t\t(V=%b) (DBZ=%b) (OVF=%b)",
        $time, division_B4_x*SF, division_B4_y*SF, division_B4_q*SF, 
        division_B4_valid, division_B4_dbz, division_B4_ovf);

        $display("%d:\t%b \t/ \t%b \t= \t(%b)\t\t(V=%b) (DBZ=%b) (OVF=%b)",
        $time, division_B4_x, division_B4_y, division_B4_q, 
        division_B4_valid, division_B4_dbz, division_B4_ovf);
    end

end










// B0
// calculate_hue_histogram_flag
always @(negedge clk) begin
    if (calculate_hue_histogram_flag == 1) begin
        
        lagger_B0 = lagger_B0 + 1;

        if (lagger_B0 == 1) begin
            source_frame_hsv_mem_read_addr = counter_B0;

        end else if (lagger_B0 == 2) begin
            hue_B0 = (source_frame_hsv_mem_read_data & full_h_mask) >> 16;
            $fdisplay(output_file_obtained_hue, hue_B0);

        end else if (lagger_B0 == 3) begin
            hue_hist_full_frame_mem_read_addr = hue_B0;
            // $display("lagger_B0:%d,hue_hist_full_frame_mem_read_addr: %b, %d", lagger_B0, hue_hist_full_frame_mem_read_addr, hue_hist_full_frame_mem_read_addr);

        end else if (lagger_B0 == 4) begin
            hue_hist_full_frame_mem_write_addr = hue_B0;
            hue_hist_full_frame_mem_read_enable = 0;
            // $display("lagger_B0:%d,hue_hist_full_frame_mem_write_addr: %b, %d", lagger_B0, hue_hist_full_frame_mem_write_addr, hue_hist_full_frame_mem_write_addr);

        end else if (lagger_B0 == 5) begin
            hue_hist_full_frame_mem_write_data = hue_hist_full_frame_mem_read_data + 1;
            // $display("lagger_B0:%d,hue_hist_full_frame_mem_write_data: %b, %d", lagger_B0, hue_hist_full_frame_mem_write_data, hue_hist_full_frame_mem_write_data);

        end else if (lagger_B0 == 6) begin
            hue_hist_full_frame_mem_write_enable = 1;

        end else if (lagger_B0 == 7) begin
            hue_hist_full_frame_mem_write_enable = 0;


        end else if (lagger_B0 == 8) begin
            hue_hist_full_frame_mem_read_enable = 1;

            if (counter_B0 < (width * height - 1)) begin
                counter_B0 = counter_B0 + 1;

            end else begin
                counter_B0 = 0;

                $display("B0: finished calculate_hue_histogram_flag");
                calculate_hue_histogram_flag = 0;

                $display("starting to dump_hue_hist_full_frame_mem_to_file_flag");  
                dump_hue_hist_full_frame_mem_to_file_flag = 1; // output_file_hue_hist_full_frame.txt

                $fclose(output_file_obtained_hue);

                hue_hist_sorter_sort_hue =0;

            end

            lagger_B0 = 0;

        end 

    end
end






// B1
// Full Frame Hue Histogram Sorter By Counts
always @(negedge clk) begin

    if (sort_hue_hist_flag == 1) begin

        hue_hist_sorter_total_counter = hue_hist_sorter_total_counter + 1;

        if (hue_hist_sorter_stage == hue_hist_sorter_stage_looping) begin
            hue_hist_sorter_read_lag_counter = hue_hist_sorter_read_lag_counter + 1;
            // $display("hue_hist_sorter_read_lag_counter: %d", hue_hist_sorter_read_lag_counter);

            if (hue_hist_sorter_read_lag_counter == 1) begin
                hue_hist_full_frame_mem_read_addr      = hue_hist_sorter_counter;
                hue_values_full_frame_mem_read_addr    = hue_hist_sorter_counter;

            end else if (hue_hist_sorter_read_lag_counter == 2) begin
                hue_hist_sorter_temp_var_count_1       = hue_hist_full_frame_mem_read_data;
                hue_hist_sorter_temp_var_hue_value_1    = hue_values_full_frame_mem_read_data;
                // $display("hue_hist_full_frame_mem_read_addr:%d, hue_hist_full_frame_mem_read_data: %d", hue_hist_full_frame_mem_read_addr, hue_hist_full_frame_mem_read_data);

            end else if (hue_hist_sorter_read_lag_counter == 3) begin
                hue_hist_full_frame_mem_read_addr      = hue_hist_sorter_counter + 1;    
                hue_values_full_frame_mem_read_addr    = hue_hist_sorter_counter + 1;    

            end else if (hue_hist_sorter_read_lag_counter == 4) begin
                hue_hist_sorter_temp_var_count_2       = hue_hist_full_frame_mem_read_data;
                hue_hist_sorter_temp_var_hue_value_2    = hue_values_full_frame_mem_read_data;

            end else if (hue_hist_sorter_read_lag_counter == 5) begin
                // $display("counter:  [%d, %d], f1: %f     f2: %f", hue_hist_sorter_counter,hue_hist_sorter_counter + 1,SF_32 * nt.f_bitstream_to_f_pair_item(hue_hist_sorter_temp_var_count_1, 0),SF_32 * nt.f_bitstream_to_f_pair_item(hue_hist_sorter_temp_var_count_2, 0));

                if (hue_hist_sorter_sort_hue == 0) begin
                    if (hue_hist_sorter_temp_var_count_1 < hue_hist_sorter_temp_var_count_2) begin
                        // $display("bump");
                        hue_hist_sorter_bump_flag = 1;
                        hue_hist_sorter_stage = hue_hist_sorter_stage_swapping;
                    end 
                end else if (hue_hist_sorter_sort_hue == 1) begin
                    if (hue_hist_sorter_temp_var_hue_value_1 > hue_hist_sorter_temp_var_hue_value_2) begin
                        // $display("bump");
                        hue_hist_sorter_bump_flag = 1;
                        hue_hist_sorter_stage = hue_hist_sorter_stage_swapping;
                    end 
                end

                hue_hist_sorter_read_lag_counter = 0;

                if (hue_hist_sorter_counter < (full_hue_range - 2)) begin
                    hue_hist_sorter_counter = hue_hist_sorter_counter + 1;

                end else begin

                    hue_hist_sorter_counter = 0;

                    if (hue_hist_sorter_bump_flag == 0) begin
                        sort_hue_hist_flag = 0;

                        $display("B1: hue hist sorting done in %d clocks\n", hue_hist_sorter_total_counter);

                        hue_hist_sorter_stage = hue_hist_sorter_stage_looping;
                        hue_hist_sorter_total_counter = 0;
                        hue_hist_sorter_counter = 0;
                        hue_hist_sorter_read_lag_counter = 0;
                        hue_hist_sorter_write_lag_counter = 0;
                        hue_hist_sorter_temp_var_count_1 = 0;
                        hue_hist_sorter_temp_var_count_2 = 0;
                        hue_hist_sorter_temp_var_hue_value_1 = 0;
                        hue_hist_sorter_temp_var_hue_value_2 = 0;



                        if (hue_hist_sorter_sort_hue == 0) begin
                            $display("B1: let's print the sorted by count...");
                            print_hue_hist_sorted_by_count_flag = 1;
                            // $display("B1: going ahead with find_excluded_hues_flag...");
                            // find_excluded_hues_flag = 1; // B2

                        end else begin
                            $display("B1: normalizing full frame...");

                            normalize_hue_hist_for_masked_full_frame_flag = 1; // B4



                        end

                    end

                    hue_hist_sorter_bump_flag = 0;

                end

            end

        end else if (hue_hist_sorter_stage== hue_hist_sorter_stage_swapping) begin

            hue_hist_sorter_write_lag_counter = hue_hist_sorter_write_lag_counter + 1;

            if (hue_hist_sorter_write_lag_counter == 1) begin
                if (hue_hist_sorter_counter == 0) begin
                    hue_hist_full_frame_mem_write_addr     = (full_hue_range - 2);
                    hue_values_full_frame_mem_write_addr   = (full_hue_range - 2);

                end else begin
                    hue_hist_full_frame_mem_write_addr = hue_hist_sorter_counter - 1;
                    hue_values_full_frame_mem_write_addr = hue_hist_sorter_counter - 1;
                end
                // $display("writing %f on %d", SF_32 * nt.f_bitstream_to_f_pair_item(hue_hist_sorter_temp_var_count_2, 0), hue_hist_full_frame_mem_write_addr);

            end else if (hue_hist_sorter_write_lag_counter == 2) begin
                hue_hist_full_frame_mem_write_data     = hue_hist_sorter_temp_var_count_2;                
                hue_values_full_frame_mem_write_data   = hue_hist_sorter_temp_var_hue_value_2;                

            end else if (hue_hist_sorter_write_lag_counter == 3) begin
                hue_hist_full_frame_mem_write_enable   = 1;
                hue_values_full_frame_mem_write_enable = 1;

            end else if (hue_hist_sorter_write_lag_counter == 4) begin
                hue_hist_full_frame_mem_write_enable   = 0;
                hue_values_full_frame_mem_write_enable = 0;

            end else if (hue_hist_sorter_write_lag_counter == 5) begin
                if (hue_hist_sorter_counter == 0) begin
                    hue_hist_full_frame_mem_write_addr     = full_hue_range - 1;
                    hue_values_full_frame_mem_write_addr   = full_hue_range - 1;
                end else begin
                    hue_hist_full_frame_mem_write_addr     = hue_hist_sorter_counter;
                    hue_values_full_frame_mem_write_addr   = hue_hist_sorter_counter;
                end

                // $display("writing %f on %d", SF_32 * nt.f_bitstream_to_f_pair_item(hue_hist_sorter_temp_var_count_1, 0), hue_hist_full_frame_mem_write_addr);

            end else if (hue_hist_sorter_write_lag_counter == 6) begin
                hue_hist_full_frame_mem_write_data     = hue_hist_sorter_temp_var_count_1;
                hue_values_full_frame_mem_write_data   = hue_hist_sorter_temp_var_hue_value_1;                


            end else if (hue_hist_sorter_write_lag_counter == 7) begin
                hue_hist_full_frame_mem_write_enable   = 1;
                hue_values_full_frame_mem_write_enable = 1;

            end else if (hue_hist_sorter_write_lag_counter == 8) begin
                hue_hist_full_frame_mem_write_enable   = 0;
                hue_values_full_frame_mem_write_enable = 0;

            end else if (hue_hist_sorter_write_lag_counter == 9) begin
                hue_hist_sorter_write_lag_counter = 0;
                hue_hist_sorter_stage = hue_hist_sorter_stage_looping;
            end

        end
    end

end


// B2
// find_excluded_hues_flag
always @(negedge clk) begin
    if (find_excluded_hues_flag == 1) begin
        lagger_B2 = lagger_B2 + 1;

        if (lagger_B2 == 1) begin
            hue_hist_full_frame_mem_read_addr      = counter_B2;
            hue_values_full_frame_mem_read_addr    = counter_B2;
            
        end else if (lagger_B2 == 2) begin
            hue_hist_full_frame_sum_B2 = hue_hist_full_frame_sum_B2 + hue_hist_full_frame_mem_read_data;

        end else if (lagger_B2 == 3) begin
            // $display("hue_hist_full_frame_sum_B2: %d, hue_bins_to_remove: %d", hue_hist_full_frame_sum_B2, hue_bins_to_remove);
            if (hue_hist_full_frame_sum_B2 < hue_bins_to_remove) begin
                excluded_hues[hue_values_full_frame_mem_read_data] = 1'b1;

                // $display("%d: excluding hue: %d, sum:%d < bins:%d",
                // counter_B2+1,
                //  hue_values_full_frame_mem_read_data,
                //  hue_hist_full_frame_sum_B2,
                //  hue_bins_to_remove
                 
                //  );

            end else begin
                // reset
                find_excluded_hues_flag = 0;

                $display("finished find_excluded_hues_flag... %d hues were excluded", counter_B2);
                $display("excluded_hues: %b", excluded_hues);

                build_hue_hist_for_masked_full_frame_flag = 1;
                excluded_hues_is_populated_milestone = 1;


                // excluded_hues = 180'b010110100100001000000000000001000000000000000100101101111111111111111111000000000000000000000000000000000000000000000000000000000000000000001111111111100111111111111111111111111111;

            end

            

        end else if (lagger_B2 == 4) begin


            if (counter_B2 < full_hue_range - 1) begin
                // $display("counter_B2 + 1");

                counter_B2 = counter_B2 + 1;

            end else begin
                // reset
                find_excluded_hues_flag = 0;


                $display("!!!!!!!!!!! finished find_excluded_hues_flag but all hues were excluded !!!!");
                $display("finished find_excluded_hues_flag... %d hues were excluded. hue_hist_full_frame_sum_B2=%d", counter_B2, hue_hist_full_frame_sum_B2);
                $display("excluded_hues: %b", excluded_hues);

                excluded_hues_is_populated_milestone = 1;
                build_hue_hist_for_masked_full_frame_flag = 1;



            end

            lagger_B2 = 0;

        end 
    end
end


// B3
// build_hue_hist_for_masked_full_frame_flag
always @(negedge clk) begin
    if (build_hue_hist_for_masked_full_frame_flag == 1) begin
        lagger_B3 = lagger_B3 + 1;

        if (lagger_B3 == 1) begin
            hue_values_full_frame_mem_read_addr = counter_B3;

        end else if (lagger_B3 == 2) begin
            hue_B3 =   hue_values_full_frame_mem_read_data;


            hue_hist_full_frame_mem_write_addr      = counter_B3; // 
            /*
                this address does not necasarily is for hue = counter_B3. 
                you need to find the address for that hue. that's because hue values are sorted
                you don't know where your required hue is now.
                so first read the contents

            */

            hue_hist_full_frame_mem_write_data      = 0;

            hue_hist_full_frame_mem_read_addr      = counter_B3; //  just for the sake of summation

        end else if (lagger_B3 == 3) begin

            if (excluded_hues[hue_B3] == 1'b1) begin
                hue_hist_full_frame_mem_write_enable = 1;

            end else begin
                sum_of_remaining_pixels_B3 = sum_of_remaining_pixels_B3 + hue_hist_full_frame_mem_read_data;
            end 

        end else if (lagger_B3 == 4) begin
            hue_hist_full_frame_mem_write_enable = 0;


        end else if (lagger_B3 == 5) begin

            if (counter_B3 < full_hue_range - 1) begin

                counter_B3 = counter_B3 + 1;

            end else begin
                counter_B3 = 0;
                build_hue_hist_for_masked_full_frame_flag = 0;
                $display("B3: finished masking the hue hist full frame... sum of remaining pixels: %d", sum_of_remaining_pixels_B3);
                $display("B3: starting to sort by hue..");

                hue_hist_sorter_sort_hue =1;
                sort_hue_hist_flag = 1;

                // $display("going for  build_hue_hist_blocks_flag...");
                // build_hue_hist_blocks_flag = 1;
            end


            lagger_B3 = 0;

        end 
    end
end



// B4
// normalize_hue_hist_for_masked_full_frame_flag
always @(negedge clk) begin
    if (normalize_hue_hist_for_masked_full_frame_flag == 1) begin
        division_B4_start = 0;
        
        lagger_B4 = lagger_B4 + 1;

        if (lagger_B4 == 1) begin
            hue_hist_full_frame_mem_read_addr      = counter_B4;
            hue_hist_full_frame_mem_write_addr     = counter_B4;

            
        end else if (lagger_B4 == 2) begin
            division_B4_x = hue_hist_full_frame_mem_read_data << q_half;
            division_B4_y = sum_of_remaining_pixels_B3 << q_half;


        end else if (lagger_B4 == 3) begin
            division_B4_start = 1;
            normalize_hue_hist_for_masked_full_frame_flag = 0;

        end else if (lagger_B4 == 5) begin
            division_B4_start = 0;
            // hue_hist_full_frame_mem_write_data = nt_aeb.mult(division_B4_q, nt_aeb.one_over_hundared);
            hue_hist_full_frame_mem_write_data = division_B4_q;
            hue_hist_full_frame_norm_sum_B4 = hue_hist_full_frame_norm_sum_B4 + hue_hist_full_frame_mem_write_data;

            // $display("%d normalized hue hist full frame: %f", counter_B4, SF * hue_hist_full_frame_mem_write_data);


        end else if (lagger_B4 == 6) begin
            hue_hist_full_frame_mem_write_enable = 1;

        end else if (lagger_B4 == 7) begin
            hue_hist_full_frame_mem_write_enable = 0;

        end else if (lagger_B4 == 8) begin

            if (counter_B4 < full_hue_range - 1) begin

                counter_B4 = counter_B4 + 1;

            end else begin
                counter_B4 = 0;
                normalize_hue_hist_for_masked_full_frame_flag = 0;
                $display("finished normalizing...");
                $display("sum of masked and normalized hue hists: %f (needs to be close to 1)", SF*hue_hist_full_frame_norm_sum_B4);

                $display("dumping ...");

                build_hue_hist_blocks_flag = 1;
            end


            lagger_B4 = 0;

        end 

    end
end




reg                 [q_full - 1 : 0]                    pixel_counter_B            = 0;
reg                 [q_full - 1 : 0]                    pixel_reader_lag_counter_B    = 0;
reg                 [q_full - 1 : 0]                    hue_hist_dumper_sum    = 0;

// dump_hue_hist_full_frame_mem_to_file_flag
always @(negedge clk) begin
    if (dump_hue_hist_full_frame_mem_to_file_flag == 1) begin
        pixel_reader_lag_counter_B = pixel_reader_lag_counter_B + 1;

        if (pixel_reader_lag_counter_B == 1) begin
            hue_hist_full_frame_mem_read_addr      = pixel_counter_B;
            hue_values_full_frame_mem_read_addr    = pixel_counter_B;

            
        end else if (pixel_reader_lag_counter_B == 2) begin
            hue_hist_dumper_sum = hue_hist_dumper_sum + hue_hist_full_frame_mem_read_data;
            $fdisplay(output_file_hue_hist_full_frame, hue_hist_full_frame_mem_read_data);     // Displays in binary  

            


        end else if (pixel_reader_lag_counter_B == 3) begin

            if (pixel_counter_B < full_hue_range - 1) begin
                pixel_counter_B = pixel_counter_B + 1;

            end else begin
                pixel_counter_B = 0;
                dump_hue_hist_full_frame_mem_to_file_flag = 0;
                $fclose(output_file_hue_hist_full_frame);  
                $display("finished dumping... total pixels in the hue hist: %d", hue_hist_dumper_sum);
                $display("dumped output_file_gray_hist_full_frame_masked.txt");


                sort_hue_hist_flag = 1;

            end


            pixel_reader_lag_counter_B = 0;

        end 
    end
end





// print sorted hue hist


reg                 [q_full - 1 : 0]                    print_counter_B10            = 0;
reg                 [q_full - 1 : 0]                    pixel_reader_lag_counter_B10    = 0;


// print_hue_hist_sorted_by_count_flag
always @(negedge clk) begin
    if (print_hue_hist_sorted_by_count_flag == 1) begin
        pixel_reader_lag_counter_B10 = pixel_reader_lag_counter_B10 + 1;

        if (pixel_reader_lag_counter_B10 == 1) begin
            hue_hist_full_frame_mem_read_addr      = print_counter_B10;
            hue_values_full_frame_mem_read_addr    = print_counter_B10;

            
        // end else if (pixel_reader_lag_counter_B10 == 2) begin
        //     $display("hue_value: %d , hue_count: %d ", 
        //         hue_values_full_frame_mem_read_data,
        //         hue_hist_full_frame_mem_read_data
        //     );
            


        end else if (pixel_reader_lag_counter_B10 == 3) begin

            if (print_counter_B10 < full_hue_range - 1) begin
                print_counter_B10 = print_counter_B10 + 1;

            end else begin
                print_counter_B10 = 0;
                print_hue_hist_sorted_by_count_flag = 0;

                $display("B1: going ahead with find_excluded_hues_flag...");
                find_excluded_hues_flag = 1; // B2



            end


            pixel_reader_lag_counter_B10 = 0;

        end 
    end
end

// Generate Union Mags
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################


reg                 [q_full - 1 : 0]                    counter_C0;
reg                 [laggers_len - 1 : 0]               lagger_C0;

reg                 [q_full - 1 : 0]                    counter_C1;
reg                 [q_full - 1 : 0]                    counter_C1_hue;
reg                 [laggers_len - 1 : 0]               lagger_C1;

reg                 [q_full - 1 : 0]                    block_counter_C0;

reg                 [q_full - 1 : 0]                    width_full_q_C0;

reg                 [q_full - 1 : 0]                    hue_C0;

reg                 [q_full - 1 : 0]                    hue_hist_blocks_sum_C;   
reg                 [q_full - 1 : 0]                    hue_hist_blocks_norm_sum_C;   

reg                 [q_full - 1 : 0]                    normalized_hue_of_blocks_C;
reg                 [q_full - 1 : 0]                    union_mag_C;
reg                 [q_full - 1 : 0]                    union_mag_sum_C;

// reg                 [q_full - 1 : 0]                    pixel_position_C0;
// reg                 [q_full - 1 : 0]                    pixel_global_row_C0;
// reg                 [q_full - 1 : 0]                    pixel_global_col_C0;
// reg                 [q_full - 1 : 0]                    pixel_block_row_idx_C0;
// reg                 [q_full - 1 : 0]                    pixel_block_col_idx_C0;


reg                 [q_full - 1 : 0]                    full_hue_range_full_q;



// C0
// build_hue_hist_blocks_flag
always @(negedge clk) begin
    if (build_hue_hist_blocks_flag == 1) begin

        lagger_C0 = lagger_C0 + 1;

        if (lagger_C0 == 1) begin
            source_frame_hsv_mem_read_addr = counter_C0;

            block_idx_mem_read_addr = counter_C0;

        end else if (lagger_C0 == 2) begin

            block_counter_C0 = block_idx_mem_read_data;

            hue_C0 = (source_frame_hsv_mem_read_data & full_h_mask) >> 16;



        end else if (lagger_C0 == 3) begin

            hue_hist_blocks_mem_read_addr = (block_counter_C0  * full_hue_range_full_q ) +  hue_C0;



            // if (block_counter_C0 == 17) begin
                
            //     $display("counter_C0: %d, block_counter_C0: %d, hue: %d,  addr: %d", 
            //     counter_C0,
            //     block_counter_C0,
            //     hue_C0,
            //     hue_hist_blocks_mem_read_addr);

            // end



        end else if (lagger_C0 == 4) begin
            hue_hist_blocks_mem_write_addr = hue_hist_blocks_mem_read_addr;
            hue_hist_blocks_mem_read_enable = 0;

            // $display("lagger_C0:%d,hue_hist_blocks_mem_write_addr: %b, %d", lagger_C0, hue_hist_blocks_mem_write_addr, hue_hist_blocks_mem_write_addr);

        end else if (lagger_C0 == 5) begin
            hue_hist_blocks_mem_write_data = hue_hist_blocks_mem_read_data + 1;
            // $display("lagger_C0:%d, hue_hist_blocks_mem_write_addr:%d, hue_hist_blocks_mem_write_data: %b, %d",
            //  lagger_C0, hue_hist_blocks_mem_write_addr, hue_hist_blocks_mem_write_data, hue_hist_blocks_mem_write_data);

        end else if (lagger_C0 == 6) begin
            hue_hist_blocks_mem_write_enable = 1;

        end else if (lagger_C0 == 7) begin
            hue_hist_blocks_mem_write_enable = 0;


        end else if (lagger_C0 == 8) begin
            hue_hist_blocks_mem_read_enable = 1;

            if (counter_C0 < (width * height - 1)) begin
                counter_C0 = counter_C0 + 1;

            end else begin
                counter_C0 = 0;
                build_hue_hist_blocks_flag = 0;
                // pixel_position_C0 = 0;
                // pixel_global_row_C0 = 0;
                // pixel_global_col_C0 = 0;
                // pixel_block_row_idx_C0 = 0;
                // pixel_block_col_idx_C0 = 0;
                // block_counter_C0 = 0;

                $display("C0: finished build_hue_hist_blocks");  


                // $display("starting to normalize blocks histogram");  

                // $display("starting to dump_hue_hist_blocks_mem_to_file_flag");  
                // dump_hue_hist_blocks_mem_to_file_flag = 1;

                
                $display("dump_hue_hist_blocks_mem_to_file_flag");  
                dump_hue_hist_blocks_mem_to_file_flag = 1;
                hue_hist_blocks_sum_C = 0;


            end


            lagger_C0 = 0;

        end 

    end
end




/*
find union mag
*/
// C1
// counter here is all_blocks_hue_counter
// build_union_mags_flag
always @(negedge clk) begin
    if (build_union_mags_flag == 1) begin

        lagger_C1 = lagger_C1 + 1;

        if (lagger_C1 == 1) begin
            hue_hist_blocks_mem_read_addr      = counter_C1;
            hue_hist_blocks_mem_write_addr     = counter_C1;

        end else if (lagger_C1 == 2) begin
            // do we have to devide by block_width * block_height?
            // have we not zeroed hue == 0?

            // normalized_hue_of_blocks_C = nt_aeb.mult_hp(hue_hist_blocks_mem_read_data, nt_aeb.one_over_block_pixels_count_hp);
            
            normalized_hue_of_blocks_C = nt_aeb.mult(hue_hist_blocks_mem_read_data << q_half, nt_aeb.one_over_block_pixels_count);
            
            

            // normalized_hue_of_blocks_C = nt_aeb.mult(hue_hist_blocks_mem_read_data << q_half, nt_aeb.one_over_1200);
            
            // if (counter_C1 == 907) begin
            //     $display("\n\n\nblocks_mem data: %b    normalized_hue_of_blocks_C:%b\n\n\n",
            //      hue_hist_blocks_mem_read_data,
            //      normalized_hue_of_blocks_C
            //      );

            //                      $display("\n\n\nblocks_mem data: %f    normalized_hue_of_blocks_C:%f\n\n\n",
            //      SF*hue_hist_blocks_mem_read_data,
            //      SF*normalized_hue_of_blocks_C
            //      );
            // end





        end else if (lagger_C1 == 3) begin
            hue_hist_full_frame_mem_read_addr = counter_C1_hue;

        end else if (lagger_C1 == 4) begin

            if (normalized_hue_of_blocks_C < hue_hist_full_frame_mem_read_data) begin
                union_mag_C = normalized_hue_of_blocks_C;
            end else begin
                union_mag_C = hue_hist_full_frame_mem_read_data;
            end

            // if (
            //     (counter_C1 >= (21 * full_hue_range))
            //     &&
            //     (counter_C1 < (22 * full_hue_range))

            // ) begin


            //     $display("\ncounter_C1: %d  counter_C1_hue: %d  --> hue_hist_blocks_mem_read_data: %f , normalized_hue_of_blocks_C %f", 
            
            //     counter_C1,
            //     counter_C1_hue,

            //     SF*(hue_hist_blocks_mem_read_data << q_half),
            //     SF*normalized_hue_of_blocks_C
            //     );
   

            //     // $display("hue_hist_blocks: %b * one_over_block_pixels_count: %b  = normalized_hue_of_blocks_C %b", 
            
            //     // (hue_hist_blocks_mem_read_data << q_half),
            //     // normalized_hue_of_blocks_C
            //     // );
   
            // end
            
            // if (
            //     (counter_C1 >= (21 * full_hue_range))
            //     &&
            //     (counter_C1 < (22 * full_hue_range))

            // ) begin


            //     $display("counter_C1: %d  counter_C1_hue: %d  full_frame: %f block: %f  union_mag_C: %f", 
            
            //     counter_C1,
            //     counter_C1_hue,

            //     SF*hue_hist_full_frame_mem_read_data,
            //     SF*normalized_hue_of_blocks_C,
            //     SF*union_mag_C
            //     );
   
            // end

        end else if (lagger_C1 == 5) begin

            // $display("counter_C1: %d, counter_C1_hue= %d", counter_C1, counter_C1_hue);
            union_mag_sum_C = union_mag_sum_C + union_mag_C;

            hue_hist_blocks_mem_write_data = union_mag_C;
            hue_hist_blocks_norm_sum_C = hue_hist_blocks_norm_sum_C + normalized_hue_of_blocks_C;

            // $display("hue_hist_blocks_mem_write_data: %f, hue_hist_blocks_norm_sum_C: %f",SF*hue_hist_blocks_mem_write_data, SF*hue_hist_blocks_norm_sum_C);
                
        end else if (lagger_C1 == 6) begin
            hue_hist_blocks_mem_write_enable = 1;

        end else if (lagger_C1 == 7) begin
            hue_hist_blocks_mem_write_enable = 0;

        end else if (lagger_C1 == 8) begin

            if (counter_C1 < (full_hue_range * crop_count * crop_count) - 1) begin

                counter_C1 = counter_C1 + 1;

                counter_C1_hue = counter_C1_hue + 1;

                if (counter_C1_hue == full_hue_range) begin
                    counter_C1_hue = 0;
                end



            end else begin
                counter_C1 = 0;
                build_union_mags_flag = 0;
                $display("C1: finished normalizing blocks and building union mags...");
                $display("C1: hue_hist_blocks_norm_sum_C: %f (needs to be close to 64.0)", SF * hue_hist_blocks_norm_sum_C);
                $display("C1: union_mag_sum_C: %f", SF*union_mag_sum_C);


                $display("start to dump_union_mags_to_file_flag");  
                dump_union_mags_to_file_flag = 1;


                counter_C1 = 0;
                counter_C1_hue = 0;

            end


            lagger_C1 = 0;

        end 

    end
end






reg                 [q_full - 1 : 0]                    pixel_counter_C0            = 0;
reg                 [q_full - 1 : 0]                    pixel_reader_lag_counter_C0    = 0;


// dump_hue_hist_blocks_mem_to_file_flag
always @(negedge clk) begin
    if (dump_hue_hist_blocks_mem_to_file_flag == 1) begin
        pixel_reader_lag_counter_C0 = pixel_reader_lag_counter_C0 + 1;

        if (pixel_reader_lag_counter_C0 == 1) begin
            hue_hist_blocks_mem_read_addr      = pixel_counter_C0;
            
        end else if (pixel_reader_lag_counter_C0 == 2) begin
            hue_hist_blocks_sum_C = hue_hist_blocks_sum_C + hue_hist_blocks_mem_read_data;
            $fdisplay(output_file_hue_hist_blocks, hue_hist_blocks_mem_read_data);  // row integer values of the histogram


        end else if (pixel_reader_lag_counter_C0 == 3) begin


            if (pixel_counter_C0 < (full_hue_range * crop_count * crop_count) - 1) begin
                // $display("pixel_counter_C0 + 1");

                pixel_counter_C0 = pixel_counter_C0 + 1;

            end else begin
                pixel_counter_C0 = 0;
                dump_hue_hist_blocks_mem_to_file_flag = 0;
                $fclose(output_file_hue_hist_blocks);  
                $display("finished dumping blocks hue hists... hue_hist_blocks_sum_C:%d (should be exactly width*height)", hue_hist_blocks_sum_C);
                $display("dumped output_file_hue_hist_blocks.txt");
                hue_hist_blocks_sum_C = 0;

                // process_union_mag_per_hue_color_range_for_all_blocks_flag = 1;
                build_union_mags_flag = 1;

            end


            pixel_reader_lag_counter_C0 = 0;

        end 
    end
end




reg                 [q_full - 1 : 0]                    pixel_counter_C1            = 0;
reg                 [q_full - 1 : 0]                    pixel_reader_lag_counter_C1    = 0;


// dump_union_mags_to_file_flag
always @(negedge clk) begin
    if (dump_union_mags_to_file_flag == 1) begin
        pixel_reader_lag_counter_C1 = pixel_reader_lag_counter_C1 + 1;

        if (pixel_reader_lag_counter_C1 == 1) begin
            hue_hist_blocks_mem_read_addr      = pixel_counter_C1;
            
        end else if (pixel_reader_lag_counter_C1 == 2) begin
            hue_hist_blocks_sum_C = hue_hist_blocks_sum_C + hue_hist_blocks_mem_read_data;
            $fdisplay(output_file_union_mags, SF * hue_hist_blocks_mem_read_data);  // for float value of um - just for plotting and comparing with python


        end else if (pixel_reader_lag_counter_C1 == 3) begin


            if (pixel_counter_C1 < (full_hue_range * crop_count * crop_count) - 1) begin
                // $display("pixel_counter_C1 + 1");

                pixel_counter_C1 = pixel_counter_C1 + 1;

            end else begin
                pixel_counter_C1 = 0;
                dump_union_mags_to_file_flag = 0;
                $fclose(output_file_union_mags);  
                $display("finished dumping union mags... sum union_mags: %f", SF* hue_hist_blocks_sum_C);
                $display("dumped output_file_hue_hist_blocks.txt");
                hue_hist_blocks_sum_C = 0;

                $display("C1: starting to FIND SS and SD process_union_mag_per_hue_color_range_for_all_blocks_flag");  
                process_union_mag_per_hue_color_range_for_all_blocks_flag = 1;

            end


            pixel_reader_lag_counter_C1 = 0;

        end 
    end
end



































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



// BUILD NONDOMINATED ARCHIVE
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################


reg                 [5: 0]                              updater_stage;

localparam          [5: 0]                              updater_stage_disactive         = 0;
localparam          [5: 0]                              updater_stage_controller        = 1;
localparam          [5: 0]                              updater_stage_worker            = 2;


reg                 [laggers_len - 1 : 0]               lagger_D5_1;
reg                 [laggers_len - 1 : 0]               lagger_D5_2;

reg                 [q_full - 1 : 0]                    block_counter_D5;
reg                 [q_full - 1 : 0]                    sub_block_counter_D5;



reg                 [laggers_len - 1 : 0]               lagger_D7;
reg                 [q_full - 1 : 0]                    counter_D7;

// ss_sum Sorter by Counts
reg                 [address_len - 1 : 0]               ss_sum_sorter_counter;
reg                 [address_len - 1 : 0]               ss_sum_sorter_read_lag_counter;
reg                 [address_len - 1 : 0]               ss_sum_sorter_write_lag_counter;

reg                 [q_full - 1 : 0]                    ss_sum_sorter_var_idx_1;
reg                 [q_full - 1 : 0]                    ss_sum_sorter_var_idx_2;

reg                 [q_full - 1 : 0]                    ss_sum_sorter_var_ss_sum_1;
reg                 [q_full - 1 : 0]                    ss_sum_sorter_var_ss_sum_2;

reg                                                     ss_sum_sorter_bump_flag;
reg                 [ 31 : 0 ]                          ss_sum_sorter_total_counter;

reg                                                     ss_sum_sorter_stage;
localparam                                              ss_sum_sorter_stage_looping                 = 0;
localparam                                              ss_sum_sorter_stage_swapping                = 1;



reg                 [crop_count * crop_count - 1 : 0]   nondominated_blocks;
reg                 [crop_count * crop_count - 1 : 0]   nondominated_blocks_zero_mask;
reg                 [crop_count * crop_count - 1 : 0]   most_significant_block_idxs;



reg                 [q_full - 1 : 0]                    candidate_block_ss_sum;
reg                 [q_full - 1 : 0]                    candidate_block_var_sum;
reg                 [1 : 0]                             dominion_status_results;

reg                 [q_full - 1 : 0]                    none_dominated_blocks_count;

reg                 [q_full - 1 : 0]                    total_blocks_needed;
reg                 [q_full - 1 : 0]                    dominated_blocks_needed;




// Counting the Blocks
// D5
always @(negedge clk) begin

    if (updater_stage == updater_stage_controller) begin

            lagger_D5_1 = lagger_D5_1 + 1;

            if (lagger_D5_1 == 2)  begin
                ss_sum_ram_read_addr = block_counter_D5;
                var_sum_ram_read_addr = block_counter_D5;

            end else if (lagger_D5_1 == 5) begin
                candidate_block_ss_sum  =  ss_sum_ram_read_data;
                candidate_block_var_sum = var_sum_ram_read_data;

            end else if (lagger_D5_1 == 6) begin
                    
                
                // $display("%b", candidate_block_ss_sum);

                if (block_counter_D5 < 64) begin


                    sub_block_counter_D5 = 0;

                    updater_stage = updater_stage_worker;

                    lagger_D5_1 = 0;

                end else begin
                    $display("D5: fnished calculating nondominated_blocks bus");
                    $display("D5: nondominated_blocks: %b", nondominated_blocks);
                    $display("D5: going ahead to sort vv_sum_ram...");
                    
                    updater_stage = updater_stage_disactive;
                    build_arg_sort_of_ss_sum_ram_flag = 1;

                end

                lagger_D5_1 = 0;
            end 
        end
end



// Doing work on each Block to figure out the non-dominated blocks
//D5
always @(negedge clk) begin
    if (updater_stage == updater_stage_worker) begin

        lagger_D5_2 = lagger_D5_2 + 1;

        // if(lagger_D5_2 == 2) begin
        //     $display("dealing with candidate at block_counter_D5: %d", block_counter_D5);

        if(lagger_D5_2 == 3) begin
            // pick next block to compare with the candidate

            ss_sum_ram_read_addr    = sub_block_counter_D5;
            var_sum_ram_read_addr   = sub_block_counter_D5;

        end else if(lagger_D5_2 == 4) begin
            dominion_status_results = nt_aeb.dominion_status(
                candidate_block_ss_sum,
                candidate_block_var_sum,
                ss_sum_ram_read_data,
                var_sum_ram_read_data
            ) ;

            // $display("(%b,%b) (%b,%b)", 
            // candidate_block_ss_sum,
            // candidate_block_var_sum,
            // ss_sum_ram_read_data,
            // var_sum_ram_read_data
            // );

        end else if(lagger_D5_2 == 5) begin
            // $display("candidate block:%d\tblock:%d\tdominion_status_results:%d",
            // block_counter_D5,
            // sub_block_counter_D5,
            // dominion_status_results);


            if (dominion_status_results == 2) begin

                // $display("%b", nondominated_blocks);

                nondominated_blocks_zero_mask = ((2 << (crop_count * crop_count + 1)) - 1) - (1 << block_counter_D5);
                
                // $display("%d, %b", block_counter_D5, nondominated_blocks_zero_mask);

                nondominated_blocks = nondominated_blocks & nondominated_blocks_zero_mask;

                // $display("%b", nondominated_blocks);
                // $display("-------------------");
                none_dominated_blocks_count = none_dominated_blocks_count - 1;
                updater_stage = updater_stage_controller;
                block_counter_D5 = block_counter_D5 + 1;
                // 0000000001001000001000000000000000000000000100000000000000000000
            end

        end else if(lagger_D5_2 == 6) begin


            if (sub_block_counter_D5 < (crop_count * crop_count - 1)) begin
                sub_block_counter_D5 = sub_block_counter_D5 + 1;

            end else begin
                updater_stage = updater_stage_controller;
                block_counter_D5 = block_counter_D5 + 1;


            end

            lagger_D5_2 = 0;

        end
    end
end



// sorting the var_sum array to get the arg sort of the
// D6
always @(negedge clk) begin
    
    if (build_arg_sort_of_ss_sum_ram_flag == 1) begin

        ss_sum_sorter_total_counter = ss_sum_sorter_total_counter + 1;

        if (ss_sum_sorter_stage == ss_sum_sorter_stage_looping) begin
            ss_sum_sorter_read_lag_counter  = ss_sum_sorter_read_lag_counter + 1;

            // $display("ss_sum_sorter_read_lag_counter: %d", ss_sum_sorter_read_lag_counter);

            if (ss_sum_sorter_read_lag_counter == 1) begin
                ss_sum_ram_read_addr            = ss_sum_sorter_counter;
                ss_sum_arg_sort_ram_read_addr   = ss_sum_sorter_counter;

            end else if (ss_sum_sorter_read_lag_counter == 2) begin
                ss_sum_sorter_var_ss_sum_1      = ss_sum_ram_read_data;
                ss_sum_sorter_var_idx_1         = ss_sum_arg_sort_ram_read_data;

            end else if (ss_sum_sorter_read_lag_counter == 3) begin
                ss_sum_ram_read_addr            = ss_sum_sorter_counter + 1;    
                ss_sum_arg_sort_ram_read_addr   = ss_sum_sorter_counter + 1;

            end else if (ss_sum_sorter_read_lag_counter == 4) begin
                ss_sum_sorter_var_ss_sum_2      = ss_sum_ram_read_data;
                ss_sum_sorter_var_idx_2         = ss_sum_arg_sort_ram_read_data;

            end else if (ss_sum_sorter_read_lag_counter == 5) begin

                // $display("counter:  [%d, %d], f1: %b     f2: %b", 
                // ss_sum_sorter_counter,
                // ss_sum_sorter_counter + 1,
                // ss_sum_sorter_var_idx_1,
                // ss_sum_sorter_var_idx_2);


                if (ss_sum_sorter_var_ss_sum_1 < ss_sum_sorter_var_ss_sum_2) begin
                    // $display("bump");
                    ss_sum_sorter_bump_flag = 1;
                    ss_sum_sorter_stage = ss_sum_sorter_stage_swapping;
                end 

                ss_sum_sorter_read_lag_counter = 0;

                if (ss_sum_sorter_counter < (crop_count * crop_count - 2)) begin
                    ss_sum_sorter_counter = ss_sum_sorter_counter + 1;

                end else begin

                    ss_sum_sorter_counter = 0;

                    if (ss_sum_sorter_bump_flag == 0) begin
                        build_arg_sort_of_ss_sum_ram_flag = 0;

                        $display("D6: ss_sum sorting done in %d clocks", ss_sum_sorter_total_counter);

                        ss_sum_sorter_stage = ss_sum_sorter_stage_looping;
                        ss_sum_sorter_total_counter = 0;
                        ss_sum_sorter_counter = 0;
                        ss_sum_sorter_read_lag_counter = 0;
                        ss_sum_sorter_write_lag_counter = 0;
                        ss_sum_sorter_var_idx_1 = 0;
                        ss_sum_sorter_var_idx_2 = 0;


                        // print_arg_sort_of_ss_sum_ram_flag = 1;

                        /*
                            starting to get the needed most significant blocks
                        */
                        total_blocks_needed             = top_blocks_count;

                        if (total_blocks_needed > none_dominated_blocks_count) begin
                            dominated_blocks_needed = total_blocks_needed - none_dominated_blocks_count;
                        end else begin
                            dominated_blocks_needed = none_dominated_blocks_count - total_blocks_needed;
                        end

                        $display("D6: total_blocks_needed: %d, dominated_blocks_needed: %d",
                         total_blocks_needed, 
                         dominated_blocks_needed);

                        $display("D6: going ahead with get_most_significant_block_idxs_flag ..");
                        get_most_significant_block_idxs_flag = 1;




                    end

                    ss_sum_sorter_bump_flag = 0;

                end

            end

        end else if (ss_sum_sorter_stage== ss_sum_sorter_stage_swapping) begin

            ss_sum_sorter_write_lag_counter = ss_sum_sorter_write_lag_counter + 1;

            if (ss_sum_sorter_write_lag_counter == 1) begin
                if (ss_sum_sorter_counter == 0) begin
                    ss_sum_arg_sort_ram_write_addr  = crop_count * crop_count - 2;
                    ss_sum_ram_write_addr           = crop_count * crop_count - 2;
                end else begin
                    ss_sum_arg_sort_ram_write_addr  = ss_sum_sorter_counter - 1;
                    ss_sum_ram_write_addr           = ss_sum_sorter_counter - 1;

                end

            end else if (ss_sum_sorter_write_lag_counter == 2) begin
                ss_sum_ram_write_data              = ss_sum_sorter_var_ss_sum_2;                
                ss_sum_arg_sort_ram_write_data     = ss_sum_sorter_var_idx_2;                


            end else if (ss_sum_sorter_write_lag_counter == 3) begin
                ss_sum_ram_write_enable             =  1;
                ss_sum_arg_sort_ram_write_enable    = 1;

            end else if (ss_sum_sorter_write_lag_counter == 4) begin
                ss_sum_ram_write_enable             = 0;
                ss_sum_arg_sort_ram_write_enable    = 0;

            end else if (ss_sum_sorter_write_lag_counter == 5) begin
                if (ss_sum_sorter_counter == 0) begin
                    ss_sum_arg_sort_ram_write_addr      = crop_count * crop_count - 1;
                    ss_sum_ram_write_addr               = crop_count * crop_count - 1;

                end else begin
                    ss_sum_arg_sort_ram_write_addr      = ss_sum_sorter_counter;
                    ss_sum_ram_write_addr               = ss_sum_sorter_counter;

                end

            end else if (ss_sum_sorter_write_lag_counter == 6) begin
                ss_sum_ram_write_data              = ss_sum_sorter_var_ss_sum_1;                
                ss_sum_arg_sort_ram_write_data     = ss_sum_sorter_var_idx_1;



            end else if (ss_sum_sorter_write_lag_counter == 7) begin
                ss_sum_ram_write_enable             =  1;
                ss_sum_arg_sort_ram_write_enable    = 1;


            end else if (ss_sum_sorter_write_lag_counter == 8) begin
                ss_sum_ram_write_enable             = 0;
                ss_sum_arg_sort_ram_write_enable    = 0;


            end else if (ss_sum_sorter_write_lag_counter == 9) begin
                ss_sum_sorter_write_lag_counter = 0;
                ss_sum_sorter_stage = ss_sum_sorter_stage_looping;
            end

        end
    end

end


/*
    ALG 2)
    dominated_needed = max(0 , top_blocks_count - non_dominated_block_counts)
    total_needed = top_blocks_count
    
    for i:
        if (total_needed > 0):
            if (non dominated):
                pick i
                total_needed -= 1;
                
            else (dominated)
                if (dominated_needed > 0)
                    pick i
                    dominated_needed -= 1
                    
        if total_needed == 0:
            break
            

*/
//D7
always @(negedge clk) begin
    if(get_most_significant_block_idxs_flag == 1) begin

        lagger_D7 = lagger_D7 + 1;

        if (lagger_D7 == 1) begin
            ss_sum_arg_sort_ram_read_addr       = counter_D7;
            ss_sum_ram_read_addr                = counter_D7;
            
        end else if (lagger_D7 == 2) begin
            // 
            if (total_blocks_needed > 0) begin
                

                if (nondominated_blocks[ss_sum_arg_sort_ram_read_data] == 1'b1) begin
                    
                    // $display("i=%d,  $b , %b , check: %d >? %d",
                    // counter_D7,
                    // nondominated_blocks & (64'd1 << counter_D7),
                    // 64'd1 << (counter_D7 - 1),
                    // nondominated_blocks & (64'd1 << counter_D7),
                    // 64'd1 << (counter_D7 - 1),
                    // );

                    most_significant_block_idxs = most_significant_block_idxs | (64'd1 << ss_sum_arg_sort_ram_read_data);

                    total_blocks_needed = total_blocks_needed - 1;

                end else begin
                    
                    if (dominated_blocks_needed > 0) begin
                        
                        most_significant_block_idxs = most_significant_block_idxs | (64'd1 << ss_sum_arg_sort_ram_read_data);

                        dominated_blocks_needed = dominated_blocks_needed - 1;
                        total_blocks_needed = total_blocks_needed - 1;

                    end

                end 

            end


        end else if (lagger_D7 == 3) begin
            // $display("counter_D7: %d, (%b < %b), read_data:%d", counter_D7, counter_D7, 24'd255, hue_hist_full_frame_mem_read_data);

            if ((counter_D7 == ((crop_count * crop_count) - 1)) || (total_blocks_needed == 0)) begin

                counter_D7 = 0;
                get_most_significant_block_idxs_flag = 0;

                $display("D7:most_significant_block_idxs: %b", most_significant_block_idxs);
                // most_significant_block_idxs = 64'b1111111111111111111110100111000000110000000100000011000000000000; // regular
                // most_significant_block_idxs =    64'b0000000000000000000000000000000000000000000100000010000000000000; // 13 and 20
                // most_significant_block_idxs =    64'b0000000000000000000000000000000000000000000000000011000000000000; // 12 and 13
                // most_significant_block_idxs =    64'b0000000000000000000000000000000000000000000000000010100000000000; // 11 and 13
                // most_significant_block_idxs =    64'b0000000000000000000000000000000000000000000000000000100000000000; // 11

                most_significant_block_idxs_populated_milestone = 1;
                // build_frame_ram_with_hue_included_mask_flag = 1; run in series

                
            end else begin
            
                counter_D7 = counter_D7 + 1;
            
            end

            lagger_D7 = 0;

        end 

    end 
end





reg                 [q_full - 1 : 0]                    pixel_counter_D6            = 0;
reg                 [q_full - 1 : 0]                    pixel_reader_lag_counter_D6    = 0;

// print_arg_sort_of_ss_sum_ram_flag
always @(negedge clk) begin
    if (print_arg_sort_of_ss_sum_ram_flag == 1) begin
        pixel_reader_lag_counter_D6 = pixel_reader_lag_counter_D6 + 1;

        if (pixel_reader_lag_counter_D6 == 1) begin
            ss_sum_arg_sort_ram_read_addr       = pixel_counter_D6;
            ss_sum_ram_read_addr                = pixel_counter_D6;
            
        end else if (pixel_reader_lag_counter_D6 == 2) begin
            // $fdisplay(output_file_hue_hist_blocks, hue_hist_blocks_mem_read_data);  // row integer values of the histogram
            // $fdisplay(output_file_hue_hist_blocks, SF * hue_hist_blocks_mem_read_data);  // for float value of um - just for plotting and comparing with python
            // $fdisplayb(output_file_hue_hist_blocks, hue_hist_blocks_mem_read_data);  // to dump actual binary value of um
            $display("%d: %f", ss_sum_arg_sort_ram_read_data, SF * ss_sum_ram_read_data);

        end else if (pixel_reader_lag_counter_D6 == 3) begin
            // $display("pixel_counter_D6: %d, (%b < %b), read_data:%d", pixel_counter_D6, pixel_counter_D6, 24'd255, hue_hist_full_frame_mem_read_data);

            if (pixel_counter_D6 < (crop_count * crop_count) - 1) begin
                // $display("pixel_counter_D6 + 1");

                pixel_counter_D6 = pixel_counter_D6 + 1;

            end else begin
                pixel_counter_D6 = 0;
                print_arg_sort_of_ss_sum_ram_flag = 0;
                // $fclose(output_file_hue_hist_blocks);  
            end

            pixel_reader_lag_counter_D6 = 0;

        end 
    end
end
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################
// start of process 2

reg                 [laggers_len - 1 : 0]               lagger_E0;
reg                 [q_full - 1 : 0]                    counter_E0;
reg                 [q_full - 1 : 0]                    hue_E0;


reg                 [laggers_len - 1 : 0]               lagger_E1;
reg                 [q_full - 1 : 0]                    counter_E1;


reg                 [q_full - 1 : 0]                    red_E1;
reg                 [q_full - 1 : 0]                    green_E1;
reg                 [q_full - 1 : 0]                    blue_E1;
reg                 [q_full - 1 : 0]                    gray_E1;



/*
you need to wait for process 1 to produce `excluded_hues`
then you proceed to eventually generate basepoints

then you wait until process one generates `most_significant_blocks_idx`

then we are ready for encoding

*/
// E0
always @(negedge clk) begin
    if (build_frame_ram_with_hue_included_mask_flag == 1) begin
        // task_manager_aux_flag_1 = 0;
        
        lagger_E0 = lagger_E0 + 1;

        if (lagger_E0 == 1) begin

            source_frame_hsv_mem_read_addr          = counter_E0;

            if (color_system == 0) begin
                masked_rgb_frame_ram_read_addr      = counter_E0;
                masked_rgb_frame_ram_write_addr     = counter_E0;

            end else if (color_system == 0) begin
                masked_gray_frame_ram_read_addr     = counter_E0;
                masked_gray_frame_ram_write_addr    = counter_E0;

            end

        end else if (lagger_E0 == 2) begin

            hue_E0 = (source_frame_hsv_mem_read_data & full_h_mask) >> 16;


            // $display("counter_E0=%d, hue_E0=%d,  %b",
            // counter_E0,
            //  hue_E0,
            //  excluded_hues[hue_E0],
            //   );

        end else if (lagger_E0 == 3) begin

                if (color_system == 0) begin
                    masked_rgb_frame_ram_write_data = 0;

                end else if (color_system == 3) begin
                    masked_gray_frame_ram_write_data = 0;

                end


        end else if (lagger_E0 == 4) begin

            if (excluded_hues[hue_E0] == 1'b1) begin

                if (color_system == 0) begin
                    masked_rgb_frame_ram_write_enable = 1;

                end else if (color_system == 3) begin
                    masked_gray_frame_ram_write_enable = 1;
                end

            end


        end else if (lagger_E0 == 5) begin
            masked_rgb_frame_ram_write_enable = 0;
            masked_gray_frame_ram_write_enable = 0;

        end else if (lagger_E0 == 6) begin
            if (color_system == 0) begin
                $fdisplayb(output_file_masked_rgb_frame, masked_rgb_frame_ram_read_data);

            end else if (color_system == 3) begin
                $fdisplayb(output_file_masked_gray_frame, masked_gray_frame_ram_read_data);

            end

        end else if (lagger_E0 == 7) begin

            if (counter_E0 < (width * height - 1)) begin
                counter_E0 = counter_E0 + 1;

            end else begin
                counter_E0 = 0;
                build_frame_ram_with_hue_included_mask_flag = 0;

                if (color_system == 0) begin
                    $fclose(output_file_masked_rgb_frame);  
                    $display("E0: dumped output_file_masked_rgb_frame.txt");

                end else if (color_system == 3) begin
                    $fclose(output_file_masked_gray_frame);  
                    $display("E0: dumped output_file_masked_gray_frame.txt");

                end

                $display("E0: going ahead with get_color_hists_for_masked_full_frame");
                get_color_hists_for_masked_full_frame = 1;
            end

            lagger_E0 = 0;

        end 



    end
end


// get_color_hists_for_masked_full_frame
// E1
always @(negedge clk) begin
    if (get_color_hists_for_masked_full_frame == 1) begin
        
        lagger_E1 = lagger_E1 + 1;

        if (lagger_E1 == 1) begin
            if (color_system == 0) begin
                masked_rgb_frame_ram_read_addr = counter_E1;
                
            end else if (color_system == 3) begin
                masked_gray_frame_ram_read_addr = counter_E1;
            end

        end else if (lagger_E1 == 2) begin
            if (color_system == 0) begin
                red_E1 =   (masked_rgb_frame_ram_read_data & full_r_mask) >> 16;
                green_E1 = (masked_rgb_frame_ram_read_data & full_g_mask) >> 8;
                blue_E1 =  (masked_rgb_frame_ram_read_data & full_b_mask);

                // $display("masked_rgb_frame_ram_read_data:%b, red:%b, green:%b, blue:%b",
                // masked_rgb_frame_ram_read_data,
                //  red_E1,
                //  green_E1,
                //  blue_E1);

            end else if (color_system == 3) begin
                gray_E1 = masked_gray_frame_ram_read_data;

            end

        end else if (lagger_E1 == 3) begin
            if (color_system == 0) begin
                red_hist_full_frame_masked_ram_read_addr    = red_E1;
                green_hist_full_frame_masked_ram_read_addr  = green_E1;
                blue_hist_full_frame_masked_ram_read_addr   = blue_E1;

                red_hist_full_frame_masked_ram_write_addr    = red_E1;
                green_hist_full_frame_masked_ram_write_addr  = green_E1;
                blue_hist_full_frame_masked_ram_write_addr   = blue_E1;


            end else if (color_system == 3) begin
                gray_hist_full_frame_masked_ram_read_addr   = gray_E1;
                gray_hist_full_frame_masked_ram_write_addr   = gray_E1;

            end



            // $display("lagger_E1:%d,hue_hist_full_frame_mem_write_addr: %b, %d", lagger_E1, hue_hist_full_frame_mem_write_addr, hue_hist_full_frame_mem_write_addr);

        end else if (lagger_E1 == 4) begin
            if (color_system == 0) begin
                red_hist_full_frame_masked_ram_write_data   = red_hist_full_frame_masked_ram_read_data      + 1;
                green_hist_full_frame_masked_ram_write_data = green_hist_full_frame_masked_ram_read_data    + 1;
                blue_hist_full_frame_masked_ram_write_data  = blue_hist_full_frame_masked_ram_read_data     + 1;

            end else if (color_system == 3) begin
                gray_hist_full_frame_masked_ram_write_data   = gray_hist_full_frame_masked_ram_read_data      + 1;

            end

            // $display("lagger_E1:%d,hue_hist_full_frame_mem_write_data: %b, %d", lagger_E1, hue_hist_full_frame_mem_write_data, hue_hist_full_frame_mem_write_data);

        end else if (lagger_E1 == 5) begin
            if (color_system == 0) begin

                if (red_E1 > 0) begin
                    red_hist_full_frame_masked_ram_write_enable = 1;
                end

                if (green_E1 > 0) begin
                    green_hist_full_frame_masked_ram_write_enable = 1;
                end

                if (blue_E1 > 0) begin
                    blue_hist_full_frame_masked_ram_write_enable = 1;
                end

            end else if (color_system == 3) begin

                if (gray_E1 > 0) begin
                    gray_hist_full_frame_masked_ram_write_enable = 1;
                end
            end


        end else if (lagger_E1 == 6) begin
            if (color_system == 0) begin
                red_hist_full_frame_masked_ram_write_enable = 0;
                green_hist_full_frame_masked_ram_write_enable = 0;
                blue_hist_full_frame_masked_ram_write_enable = 0;

            end else if (color_system == 3) begin
                gray_hist_full_frame_masked_ram_write_enable = 0;

            end


        end else if (lagger_E1 == 7) begin

            if (counter_E1 < (width * height - 1)) begin
                counter_E1 = counter_E1 + 1;

            end else begin
                counter_E1 = 0;
                get_color_hists_for_masked_full_frame = 0;
                // dump_hue_hist_full_frame_mem_to_file_flag = 1; // output_file_hue_hist_full_frame.txt
                // hue_hist_full_frame_norm_sum = 0;

                $display("E1: finished get_color_hists_for_masked_full_frame");  
                
                // $display("starting to dump_hue_hist_full_frame_mem_to_file_flag");  
                // dump_hue_hist_full_frame_mem_to_file_flag = 1;


                $display("E1: going to get_color_hists_for_masked_full_frame");  
                get_remaining_pixels_count_for_rgb_hists_flag = 1;

            end

            lagger_E1 = 0;

        end 

    end
end



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



































// UMapper ENCODER
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################


reg                 [5: 0]                              umapper_stage               ;

localparam          [5: 0]                              umapper_stage_controller     = 0;
localparam          [5: 0]                              umapper_stage_worker         = 1;
localparam          [5: 0]                              umapper_stage_finished       = 2;

reg                 [sum_bpu - 1 : 0]                   encoder_aeb;

reg                 [laggers_len - 1 : 0]               umapper_lagger_1;
reg                 [laggers_len - 1 : 0]               umapper_lagger_2;

reg                 [q_full - 1 : 0]                    encoder_start_pixel_address;
reg                 [q_full - 1 : 0]                    encoder_end_pixel_address;


reg                 [q_full - 1 : 0]                    encoder_block_position;
reg                 [q_full - 1 : 0]                    encoder_block_row;
reg                 [q_full - 1 : 0]                    encoder_block_col;

reg                 [q_full - 1 : 0]                    encoder_pixel_block_column_counter;
reg                 [q_full - 1 : 0]                    encoder_pixel_block_counter;
reg                 [q_full - 1 : 0]                    encoder_total_pixel_counter;

reg                 [q_full - 1 : 0]                    encoder_block_counter;
reg                 [q_full - 1 : 0]                    encoder_pixel_counter;


reg                 [q_full - 1 : 0]                    encoder_r_full_q                            ;
reg                 [q_full - 1 : 0]                    encoder_g_full_q                            ;
reg                 [q_full - 1 : 0]                    encoder_b_full_q                            ;
reg                 [q_full - 1 : 0]                    encoder_gray_full_q                            ;


// Counting the Blocks
always @(negedge clk) begin

    if (umapper_stage == umapper_stage_controller) begin
        // task_manager_aux_flag_2 = 0;
        
        // $display("umapper_lagger_1:%d, encoder_block_counter:%d",umapper_lagger_1, encoder_block_counter);
        umapper_lagger_1 = umapper_lagger_1 + 1;

        if (umapper_lagger_1 == 1)  begin

            // Is the block among the most significant ones?
            if (most_significant_block_idxs[encoder_block_counter] == 1'b1) begin

                encoder_block_position      = nt_aeb.mult_hp(encoder_block_counter, one_over_crop_count);
                encoder_block_row           = encoder_block_position >> q_half;
                encoder_block_col           = nt_aeb.mult( (encoder_block_position & nt_aeb.floating_part_mask) , full_q_crop_count) >> q_half;

                // these addresses are inclusive
                encoder_start_pixel_address = (encoder_block_row * block_width * block_height * crop_count) + encoder_block_col * block_width;
                encoder_end_pixel_address = (encoder_block_row * crop_count * block_height * block_width) + ((block_height-1) * crop_count * block_width)+ ((encoder_block_col + 1) * block_width);

                encoder_pixel_counter = encoder_start_pixel_address;
                encoder_pixel_block_column_counter = 0;
                encoder_pixel_block_counter = 0;

                $display("ENCODER Controller: ---------------block counter %d, block_global_row:%d, block_global_col:%d, encoder_start_pixel_address:%d, encoder_end_pixel_address:%d",
                 encoder_block_counter,
                 encoder_block_row,
                 encoder_block_col,
                 encoder_start_pixel_address,
                 encoder_end_pixel_address
                 
                 );

                umapper_stage = umapper_stage_worker;

            end 
            
            
            

        end else if (umapper_lagger_1 == 2)  begin

            if (encoder_block_counter == ((crop_count * crop_count) - 1)) begin
                umapper_stage = umapper_stage_finished;
                $display("ENCODER: finished mapping %d pixels in total.", encoder_total_pixel_counter);
                

                $fclose(output_file_aeb_frame);     // Displays in binary  

                // $display("dumping..");
                // pixel_reader_lag_counter = 0;
                // encoder_pixel_counter = 0;
                // dump_aeb_frame_to_file_flag = 1;

                $display("ENCODER: starting to decode..");
                // umapper_decoder_active_flag = 1;
                decoder_stage = decoder_stage_controller;


            end else begin
                encoder_block_counter = encoder_block_counter + 1;

            end

            umapper_lagger_1 = 0;

        end

    end

end




// UMapper Encoding the Block
always @(negedge clk) begin

    if (umapper_stage == umapper_stage_worker) begin

        umapper_lagger_2 = umapper_lagger_2 + 1;

        if (umapper_lagger_2 == 1) begin
            if (color_system == 0) begin
                source_frame_rgb_mem_read_addr = encoder_pixel_counter;

            end else if (color_system == 3) begin
                source_frame_gray_mem_read_addr = encoder_pixel_counter;

            end

        end else if (umapper_lagger_2 == 2) begin
            encoder_aeb= 0;

        end else if (umapper_lagger_2 == 3) begin

            if (color_system == 0) begin
                if(red_base_points > 0) begin
                    encoder_r_full_q = (source_frame_rgb_mem_read_data & full_r_mask) >> 16;
                    encoder_r_full_q = nt_aeb.get_aeb(red_base_points, encoder_r_full_q);
                    encoder_aeb=       encoder_r_full_q << (bpu_g + bpu_b);

                end 
            end else if (color_system == 3) begin
                if(gray_base_points > 0) begin
                    encoder_gray_full_q = source_frame_gray_mem_read_data;
                                        // $display("encoder_gray_full_q: %b", encoder_gray_full_q);

                    encoder_gray_full_q = nt_aeb.get_aeb(gray_base_points, encoder_gray_full_q);
                    encoder_aeb=       encoder_gray_full_q;

                end 
            end 
            


        end else if (umapper_lagger_2 == 4) begin

            if (color_system == 0) begin
                if(green_base_points > 0) begin
                    encoder_g_full_q = (source_frame_rgb_mem_read_data & full_g_mask) >> 8;
                    encoder_g_full_q = nt_aeb.get_aeb(green_base_points, encoder_g_full_q);
                    encoder_aeb= encoder_aeb+ (encoder_g_full_q << bpu_b);

                end 
            end 
            

        end else if (umapper_lagger_2 == 5) begin

            if (color_system == 0) begin
                if(blue_base_points > 0) begin
                    encoder_b_full_q = (source_frame_rgb_mem_read_data & full_b_mask);
                    encoder_b_full_q = nt_aeb.get_aeb(blue_base_points, encoder_b_full_q);
                    encoder_aeb= encoder_aeb+ encoder_b_full_q;

                end 
            end 


        end else if (umapper_lagger_2 == 6) begin
            // $display("encoder_total_pixel_counter:%d, encoder_aeb:%b", encoder_total_pixel_counter, encoder_aeb);
            aeb_frame_mem_write_addr = encoder_total_pixel_counter;
            encoder_total_pixel_counter = encoder_total_pixel_counter + 1;


        end else if (umapper_lagger_2 == 7) begin
            aeb_frame_mem_write_data = encoder_aeb;


        end else if (umapper_lagger_2 == 8) begin
            aeb_frame_mem_write_enable = 1;


        end else if (umapper_lagger_2 == 9) begin
            aeb_frame_mem_write_enable = 0;

        end else if (umapper_lagger_2 == 10) begin
            
            if (encoder_pixel_counter == encoder_end_pixel_address) begin
                umapper_stage = umapper_stage_controller;
                encoder_total_pixel_counter = encoder_total_pixel_counter - 1;
                // $display("encoded %d pixels         encoder_total_pixel_counter:", encoder_pixel_block_counter, encoder_total_pixel_counter);

            end else begin
                encoder_pixel_counter = encoder_pixel_counter + 1;
                encoder_pixel_block_counter = encoder_pixel_block_counter + 1;
                encoder_pixel_block_column_counter = encoder_pixel_block_column_counter + 1;


                $fdisplayb(output_file_aeb_frame, encoder_aeb);     // Displays in binary  

                /*
                    if we have reached the last column of the block we need to skip to the first column
                    of the next row.
                */
                if ((encoder_pixel_block_column_counter == block_width)&&(encoder_pixel_counter < encoder_end_pixel_address)) begin
                    // $display("encoder_pixel_counter: %d skipping to", encoder_pixel_counter);
                    encoder_pixel_block_column_counter = 0;
                    encoder_pixel_counter = encoder_pixel_counter + (crop_count - 1) * block_width;

                    // $display("encoder_pixel_counter: %d", encoder_pixel_counter);

                end

            end

            umapper_lagger_2 = 0;
        end


    end

end


// UMapper DECODER
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################
// ########################################################################################################################################################################################

/*
the issue is that the last block of the row prints one extra pixel traspassing into the next block
the extra pixel is actually the decoder_end_pixel_address

*/

reg                 [5: 0]                              decoder_stage               ;

localparam          [5: 0]                              decoder_stage_controller     = 0;
localparam          [5: 0]                              decoder_stage_worker         = 1;
localparam          [5: 0]                              decoder_stage_finished       = 2;


reg                 [laggers_len - 1 : 0]               decoder_lagger_1;
reg                 [laggers_len - 1 : 0]               decoder_lagger_2;

reg                 [q_full - 1 : 0]                    decoder_start_pixel_address;
reg                 [q_full - 1 : 0]                    decoder_end_pixel_address;


reg                 [q_full - 1 : 0]                    decoder_block_position;
reg                 [q_full - 1 : 0]                    decoder_block_row;
reg                 [q_full - 1 : 0]                    decoder_block_col;

reg                 [q_full - 1 : 0]                    decoder_pixel_block_column_counter;
reg                 [q_full - 1 : 0]                    decoder_pixel_block_counter;
reg                 [q_full - 1 : 0]                    decoder_total_pixel_counter;
reg                 [q_full - 1 : 0]                    decoder_aeb_counter;

reg                 [q_full - 1 : 0]                    decoder_pixel_counter;
reg                 [q_full - 1 : 0]                    decoder_block_counter;


reg                 [q_full - 1 : 0]                    decoder_r_full_q;
reg                 [q_full - 1 : 0]                    decoder_g_full_q;
reg                 [q_full - 1 : 0]                    decoder_b_full_q;
reg                 [q_full - 1 : 0]                    decoder_gray_full_q;



// Counting the Blocks
always @(negedge clk) begin

    if (decoder_stage == decoder_stage_controller) begin
        
        // $display("decoder_lagger_1:%d, block_counter:%d",decoder_lagger_1, block_counter);
        decoder_lagger_1 = decoder_lagger_1 + 1;

        if (decoder_lagger_1 == 1)  begin

            // Is the block among the most significant ones?
            if (most_significant_block_idxs[decoder_block_counter] == 1'b1) begin

                decoder_block_position      = nt_aeb.mult_hp(decoder_block_counter, one_over_crop_count);
                decoder_block_row           = decoder_block_position >> q_half;
                decoder_block_col           = nt_aeb.mult( (decoder_block_position & nt_aeb.floating_part_mask) , full_q_crop_count) >> q_half;

                // these addresses are inclusive
                decoder_start_pixel_address = (decoder_block_row * block_width * block_height * crop_count) + decoder_block_col * block_width;
                decoder_end_pixel_address = (decoder_block_row * crop_count * block_height * block_width) + ((block_height-1) * crop_count * block_width)+ ((decoder_block_col + 1) * block_width);

                decoder_pixel_counter = decoder_start_pixel_address;
                decoder_pixel_block_column_counter = 0;
                decoder_pixel_block_counter = 0;

                $display("DECODER Controller: ---------------block counter %d, block_global_row:%d, block_global_col:%d, decoder_start_pixel_address:%d, decoder_end_pixel_address:%d",
                 decoder_block_counter,
                 decoder_block_row,
                 decoder_block_col,
                 decoder_start_pixel_address,
                 decoder_end_pixel_address
                 );

                decoder_stage = decoder_stage_worker;

            end




        end else if (decoder_lagger_1 == 2)  begin

            if (decoder_block_counter == ((crop_count * crop_count) - 1)) begin
                decoder_stage = decoder_stage_finished;
                $display("DECODER: finished decoding %d pixels", decoder_total_pixel_counter);
                

                // $display("dumping..");
                // pixel_reader_lag_counter_decoder_dumper = 0;
                // decoder_pixel_counter = 0;
                // dump_aeb_frame_to_file_flag = 1;

                // $display("DECODER: starting to decode..");
                // umapper_decoder_active_flag = 1;
                dump_decoded_rgb_to_file_flag = 1;

                pixel_reader_lag_counter_decoder_dumper = 0;

            end else begin
                decoder_block_counter = decoder_block_counter + 1;

            end

            decoder_lagger_1 = 0;

        end

    end

end




// UMapper Decoding the Block
always @(negedge clk) begin

    if (decoder_stage == decoder_stage_worker) begin

        decoder_lagger_2 = decoder_lagger_2 + 1;

        if (decoder_lagger_2 == 1) begin
            aeb_frame_mem_read_addr = decoder_aeb_counter; // this should be a counter on the aeb pixels
            decoded_frame_rgb_mem_write_addr = decoder_pixel_counter; // this counter scans the block row by row


        end else if (decoder_lagger_2 == 3) begin


            // $display("decoder_aeb_counter:%d, decoder_pixel_counter:%d, aeb_frame_mem_read_data:%b, decoder_gray_full_q:%d",
            //  decoder_aeb_counter, 
            //  decoder_pixel_counter,
            //  aeb_frame_mem_read_data,
            //  decoder_gray_full_q
            //  );
            

            if (color_system == 0) begin

                // $display("decoder_aeb_counter: %d, aeb_frame_mem_read_data: %b", decoder_aeb_counter, aeb_frame_mem_read_data);

                decoder_r_full_q = aeb_frame_mem_read_data & r_mask;
                decoder_g_full_q = aeb_frame_mem_read_data & g_mask;
                decoder_b_full_q = aeb_frame_mem_read_data & b_mask;

                decoder_r_full_q = decoder_r_full_q >> (bpu_g + bpu_b);
                decoder_g_full_q = decoder_g_full_q >> bpu_b;

                // $display("decoder_r_full_q:%d, decoder_g_full_q:%d, decoder_b_full_q:%d", decoder_r_full_q, decoder_g_full_q, decoder_b_full_q);
                // $display("decoder_r_full_q:%d, red_base_points:%b", decoder_r_full_q, red_base_points);

                decoder_r_full_q = nt_aeb.aeb_to_basepoint(red_base_points, decoder_r_full_q);
                decoder_g_full_q = nt_aeb.aeb_to_basepoint(green_base_points, decoder_g_full_q);
                decoder_b_full_q = nt_aeb.aeb_to_basepoint(blue_base_points, decoder_b_full_q);

                // $display("extracted ----------decoder_r_full_q:%b, decoder_g_full_q:%d, decoder_b_full_q:%d", decoder_r_full_q, decoder_g_full_q, decoder_b_full_q);

                decoded_frame_rgb_mem_write_data =   (decoder_r_full_q << 16) + (decoder_g_full_q << 8) + (decoder_b_full_q);
                // decoded_frame_rgb_mem_write_data =   aeb_frame_mem_read_data;
                
                // $display("decoded_frame_rgb_mem_write_data:%d", decoded_frame_rgb_mem_write_data);
            end else if (color_system == 3) begin

                decoder_gray_full_q = aeb_frame_mem_read_data;
                // $display("ud_encoded_pixel_counter: %d, aeb_frame_mem_read_data: %b : %d", ud_encoded_pixel_counter, aeb_frame_mem_read_data , aeb_frame_mem_read_data);
                // $display("decoder_aeb_counter:%d, write_addr:%d, aeb_read_data:%b, decoder_gray_full_q:%d",
                // decoder_aeb_counter, 
                // decoder_pixel_counter,
                // aeb_frame_mem_read_data,
                // decoder_gray_full_q
                // );
            
                // $display("gray_base_points: %b", gray_base_points);
                decoder_gray_full_q = nt_aeb.aeb_to_basepoint(gray_base_points, decoder_gray_full_q);
                // $display("ud_encoded_pixel_counter: %d, decoder_gray_full_q: %b", ud_encoded_pixel_counter, decoder_gray_full_q);



                decoded_frame_rgb_mem_write_data =   (decoder_gray_full_q << 16) + (decoder_gray_full_q << 8) + (decoder_gray_full_q);

                // $display("ud_encoded_pixel_counter: %d, decoded_frame_rgb_mem_write_data: %b", ud_encoded_pixel_counter, decoded_frame_rgb_mem_write_data);


            end


        end else if (decoder_lagger_2 == 4) begin
            if (decoder_pixel_block_counter < (block_width * block_height)) begin
                decoded_frame_rgb_mem_write_enable = 1;
            end


        end else if (decoder_lagger_2 == 5) begin
            decoded_frame_rgb_mem_write_enable = 0;


        end else if (decoder_lagger_2 == 6) begin
            // $display("decoder_total_pixel_counter:%d, aeb:%b", decoder_total_pixel_counter, aeb);
            decoder_total_pixel_counter = decoder_total_pixel_counter + 1;


        end else if (decoder_lagger_2 == 7) begin

            if (decoder_pixel_counter == decoder_end_pixel_address) begin
                decoder_stage = decoder_stage_controller;
                decoder_total_pixel_counter = decoder_total_pixel_counter - 1;

                // $display("decoded %d pixels         decoder_total_pixel_counter:", decoder_pixel_block_counter, decoder_total_pixel_counter);

            end else begin
                decoder_pixel_counter = decoder_pixel_counter + 1;
                decoder_pixel_block_counter = decoder_pixel_block_counter + 1;
                decoder_pixel_block_column_counter = decoder_pixel_block_column_counter + 1;

                decoder_aeb_counter = decoder_aeb_counter + 1;

                /*
                    if we have reached the last column of the block we need to skip to the first column
                    of the next row.
                */
                if ((decoder_pixel_block_column_counter == block_width)&&(decoder_pixel_counter < decoder_end_pixel_address)) begin
                    // $display("decoder_pixel_counter: %d skipping to", decoder_pixel_counter);
                    decoder_pixel_block_column_counter = 0;
                    decoder_pixel_counter = decoder_pixel_counter + (crop_count - 1) * block_width;

                    // $display("decoder_pixel_counter: %d", decoder_pixel_counter);

                end

            end

            decoder_lagger_2 = 0;
        
        end


    end

end




reg                 [q_full - 1 : 0]                    pixel_counter_decoder_dumper            = 0;
reg                 [q_full - 1 : 0]                    pixel_reader_lag_counter_decoder_dumper    = 0;

always @(negedge clk) begin
    if (dump_decoded_rgb_to_file_flag == 1) begin
        pixel_reader_lag_counter_decoder_dumper = pixel_reader_lag_counter_decoder_dumper + 1;

        if (pixel_reader_lag_counter_decoder_dumper == 1) begin
            decoded_frame_rgb_mem_read_addr = pixel_counter_decoder_dumper;
            
        end else if (pixel_reader_lag_counter_decoder_dumper == 2) begin
            $fdisplayb(output_file_decoded_rgb, decoded_frame_rgb_mem_read_data);     // Displays in binary  

            // if (decoded_frame_rgb_mem_read_data > 0) begin
                // $display("dumper pixel_counter_decoder_dumper:%d, data: %b",pixel_counter_decoder_dumper, decoded_frame_rgb_mem_read_data);
            // end

        end else if (pixel_reader_lag_counter_decoder_dumper == 3) begin

            if (pixel_counter_decoder_dumper < (width * height - 1)) begin
                pixel_counter_decoder_dumper = pixel_counter_decoder_dumper + 1;

            end else begin
                pixel_counter_decoder_dumper = 0;
                dump_decoded_rgb_to_file_flag = 0;





                $fclose(output_file_decoded_rgb);  
                $display("dumping output_file_decoded_rgb.txt");
                $display("FINISHED ________________ at %d", $time);
            end

            pixel_reader_lag_counter_decoder_dumper = 0;

        end 
    end
end



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

endmodule