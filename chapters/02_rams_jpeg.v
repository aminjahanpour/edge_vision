






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


