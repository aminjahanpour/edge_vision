
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


