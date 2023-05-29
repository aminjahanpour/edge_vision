







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































