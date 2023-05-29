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










