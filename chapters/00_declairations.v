
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












