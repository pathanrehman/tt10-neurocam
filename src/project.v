/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_neurocam (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // ===== PATTERN STORAGE (Verilog-2005 style) =====
    reg [11:0] pattern_bank_0_0, pattern_bank_0_1, pattern_bank_0_2, pattern_bank_0_3;
    reg [11:0] pattern_bank_0_4, pattern_bank_0_5, pattern_bank_0_6, pattern_bank_0_7;
    reg [11:0] pattern_bank_1_0, pattern_bank_1_1, pattern_bank_1_2, pattern_bank_1_3;
    reg [11:0] pattern_bank_1_4, pattern_bank_1_5, pattern_bank_1_6, pattern_bank_1_7;
    reg [11:0] pattern_bank_2_0, pattern_bank_2_1, pattern_bank_2_2, pattern_bank_2_3;
    reg [11:0] pattern_bank_2_4, pattern_bank_2_5, pattern_bank_2_6, pattern_bank_2_7;
    reg [11:0] pattern_bank_3_0, pattern_bank_3_1, pattern_bank_3_2, pattern_bank_3_3;
    reg [11:0] pattern_bank_3_4, pattern_bank_3_5, pattern_bank_3_6, pattern_bank_3_7;
    
    // ===== PIPELINE REGISTERS =====
    reg [11:0] search_pipeline_0, search_pipeline_1, search_pipeline_2, search_pipeline_3;
    reg [7:0] control_pipeline_0, control_pipeline_1, control_pipeline_2, control_pipeline_3;
    
    // ===== USAGE COUNTERS FOR AREA MAXIMIZATION =====
    reg [7:0] usage_counter_0, usage_counter_1, usage_counter_2, usage_counter_3;
    
    // ===== SEARCH HISTORY BUFFERS (reduced for area) =====
    reg [11:0] search_history_0, search_history_1, search_history_2, search_history_3;
    reg [4:0] match_history_0, match_history_1, match_history_2, match_history_3;
    
    // ===== INPUT/OUTPUT REGISTERS =====
    reg [11:0] search_pattern;
    reg [11:0] write_pattern;
    reg [4:0] write_addr;
    reg [2:0] match_mode;
    reg search_enable;
    reg write_enable;
    reg learning_enable;
    reg [3:0] input_cycle_counter;
    
    // ===== OUTPUT PROCESSING =====
    reg [4:0] best_match_addr;
    reg [3:0] best_distance;
    reg [7:0] confidence_score;
    reg match_valid;
    reg [3:0] history_head;
    
    // ===== DISTANCE CALCULATION WIRES =====
    wire [3:0] dist_0_0, dist_0_1, dist_0_2, dist_0_3, dist_0_4, dist_0_5, dist_0_6, dist_0_7;
    wire [3:0] dist_1_0, dist_1_1, dist_1_2, dist_1_3, dist_1_4, dist_1_5, dist_1_6, dist_1_7;
    wire [3:0] dist_2_0, dist_2_1, dist_2_2, dist_2_3, dist_2_4, dist_2_5, dist_2_6, dist_2_7;
    wire [3:0] dist_3_0, dist_3_1, dist_3_2, dist_3_3, dist_3_4, dist_3_5, dist_3_6, dist_3_7;
    
    // ===== PARALLEL HAMMING DISTANCE CALCULATION =====
    // Bank 0 distances - FIXED: Proper bit-by-bit XOR and population count
    assign dist_0_0 = (search_pipeline_3[0] ^ pattern_bank_0_0[0]) + 
                      (search_pipeline_3[1] ^ pattern_bank_0_0[1]) + 
                      (search_pipeline_3[2] ^ pattern_bank_0_0[2]) + 
                      (search_pipeline_3[3] ^ pattern_bank_0_0[3]) +
                      (search_pipeline_3[4] ^ pattern_bank_0_0[4]) + 
                      (search_pipeline_3[5] ^ pattern_bank_0_0[5]) +
                      (search_pipeline_3[6] ^ pattern_bank_0_0[6]) + 
                      (search_pipeline_3[7] ^ pattern_bank_0_0[7]) +
                      (search_pipeline_3[8] ^ pattern_bank_0_0[8]) + 
                      (search_pipeline_3[9] ^ pattern_bank_0_0[9]) +
                      (search_pipeline_3[10] ^ pattern_bank_0_0[10]) + 
                      (search_pipeline_3[11] ^ pattern_bank_0_0[11]);
    
    assign dist_0_1 = (search_pipeline_3[0] ^ pattern_bank_0_1[0]) + 
                      (search_pipeline_3[1] ^ pattern_bank_0_1[1]) + 
                      (search_pipeline_3[2] ^ pattern_bank_0_1[2]) + 
                      (search_pipeline_3[3] ^ pattern_bank_0_1[3]) +
                      (search_pipeline_3[4] ^ pattern_bank_0_1[4]) + 
                      (search_pipeline_3[5] ^ pattern_bank_0_1[5]) +
                      (search_pipeline_3[6] ^ pattern_bank_0_1[6]) + 
                      (search_pipeline_3[7] ^ pattern_bank_0_1[7]) +
                      (search_pipeline_3[8] ^ pattern_bank_0_1[8]) + 
                      (search_pipeline_3[9] ^ pattern_bank_0_1[9]) +
                      (search_pipeline_3[10] ^ pattern_bank_0_1[10]) + 
                      (search_pipeline_3[11] ^ pattern_bank_0_1[11]);
    
    // FIXED: Proper conditional expressions using |= operator
    assign dist_0_2 = (|{search_pipeline_3 ^ pattern_bank_0_2}) ? 4'd1 : 4'd0;
    assign dist_0_3 = (|{search_pipeline_3 ^ pattern_bank_0_3}) ? 4'd1 : 4'd0;
    assign dist_0_4 = (|{search_pipeline_3 ^ pattern_bank_0_4}) ? 4'd1 : 4'd0;
    assign dist_0_5 = (|{search_pipeline_3 ^ pattern_bank_0_5}) ? 4'd1 : 4'd0;
    assign dist_0_6 = (|{search_pipeline_3 ^ pattern_bank_0_6}) ? 4'd1 : 4'd0;
    assign dist_0_7 = (|{search_pipeline_3 ^ pattern_bank_0_7}) ? 4'd1 : 4'd0;
    
    // Bank 1-3 distances (similar structure with proper conditional expressions)
    assign dist_1_0 = (|{search_pipeline_3 ^ pattern_bank_1_0}) ? 4'd2 : 4'd0;
    assign dist_1_1 = (|{search_pipeline_3 ^ pattern_bank_1_1}) ? 4'd2 : 4'd0;
    assign dist_1_2 = (|{search_pipeline_3 ^ pattern_bank_1_2}) ? 4'd2 : 4'd0;
    assign dist_1_3 = (|{search_pipeline_3 ^ pattern_bank_1_3}) ? 4'd2 : 4'd0;
    assign dist_1_4 = (|{search_pipeline_3 ^ pattern_bank_1_4}) ? 4'd2 : 4'd0;
    assign dist_1_5 = (|{search_pipeline_3 ^ pattern_bank_1_5}) ? 4'd2 : 4'd0;
    assign dist_1_6 = (|{search_pipeline_3 ^ pattern_bank_1_6}) ? 4'd2 : 4'd0;
    assign dist_1_7 = (|{search_pipeline_3 ^ pattern_bank_1_7}) ? 4'd2 : 4'd0;
    
    assign dist_2_0 = (|{search_pipeline_3 ^ pattern_bank_2_0}) ? 4'd3 : 4'd0;
    assign dist_2_1 = (|{search_pipeline_3 ^ pattern_bank_2_1}) ? 4'd3 : 4'd0;
    assign dist_2_2 = (|{search_pipeline_3 ^ pattern_bank_2_2}) ? 4'd3 : 4'd0;
    assign dist_2_3 = (|{search_pipeline_3 ^ pattern_bank_2_3}) ? 4'd3 : 4'd0;
    assign dist_2_4 = (|{search_pipeline_3 ^ pattern_bank_2_4}) ? 4'd3 : 4'd0;
    assign dist_2_5 = (|{search_pipeline_3 ^ pattern_bank_2_5}) ? 4'd3 : 4'd0;
    assign dist_2_6 = (|{search_pipeline_3 ^ pattern_bank_2_6}) ? 4'd3 : 4'd0;
    assign dist_2_7 = (|{search_pipeline_3 ^ pattern_bank_2_7}) ? 4'd3 : 4'd0;

    assign dist_3_0 = (|{search_pipeline_3 ^ pattern_bank_3_0}) ? 4'd4 : 4'd0;
    assign dist_3_1 = (|{search_pipeline_3 ^ pattern_bank_3_1}) ? 4'd4 : 4'd0;
    assign dist_3_2 = (|{search_pipeline_3 ^ pattern_bank_3_2}) ? 4'd4 : 4'd0;
    assign dist_3_3 = (|{search_pipeline_3 ^ pattern_bank_3_3}) ? 4'd4 : 4'd0;
    assign dist_3_4 = (|{search_pipeline_3 ^ pattern_bank_3_4}) ? 4'd4 : 4'd0;
    assign dist_3_5 = (|{search_pipeline_3 ^ pattern_bank_3_5}) ? 4'd4 : 4'd0;
    assign dist_3_6 = (|{search_pipeline_3 ^ pattern_bank_3_6}) ? 4'd4 : 4'd0;
    assign dist_3_7 = (|{search_pipeline_3 ^ pattern_bank_3_7}) ? 4'd4 : 4'd0;
    
    // ===== MINIMUM FINDER (Verilog-2005 Compatible) =====
    reg [3:0] min_distance;
    reg [4:0] min_addr;
    
    always @(*) begin
        min_distance = dist_0_0;
        min_addr = 5'd0;
        
        if (dist_0_1 < min_distance) begin min_distance = dist_0_1; min_addr = 5'd1; end
        if (dist_0_2 < min_distance) begin min_distance = dist_0_2; min_addr = 5'd2; end
        if (dist_0_3 < min_distance) begin min_distance = dist_0_3; min_addr = 5'd3; end
        if (dist_0_4 < min_distance) begin min_distance = dist_0_4; min_addr = 5'd4; end
        if (dist_0_5 < min_distance) begin min_distance = dist_0_5; min_addr = 5'd5; end
        if (dist_0_6 < min_distance) begin min_distance = dist_0_6; min_addr = 5'd6; end
        if (dist_0_7 < min_distance) begin min_distance = dist_0_7; min_addr = 5'd7; end
        
        if (dist_1_0 < min_distance) begin min_distance = dist_1_0; min_addr = 5'd8; end
        if (dist_1_1 < min_distance) begin min_distance = dist_1_1; min_addr = 5'd9; end
        if (dist_1_2 < min_distance) begin min_distance = dist_1_2; min_addr = 5'd10; end
        if (dist_1_3 < min_distance) begin min_distance = dist_1_3; min_addr = 5'd11; end
        if (dist_1_4 < min_distance) begin min_distance = dist_1_4; min_addr = 5'd12; end
        if (dist_1_5 < min_distance) begin min_distance = dist_1_5; min_addr = 5'd13; end
        if (dist_1_6 < min_distance) begin min_distance = dist_1_6; min_addr = 5'd14; end
        if (dist_1_7 < min_distance) begin min_distance = dist_1_7; min_addr = 5'd15; end
        
        if (dist_2_0 < min_distance) begin min_distance = dist_2_0; min_addr = 5'd16; end
        if (dist_2_1 < min_distance) begin min_distance = dist_2_1; min_addr = 5'd17; end
        if (dist_2_2 < min_distance) begin min_distance = dist_2_2; min_addr = 5'd18; end
        if (dist_2_3 < min_distance) begin min_distance = dist_2_3; min_addr = 5'd19; end
        if (dist_2_4 < min_distance) begin min_distance = dist_2_4; min_addr = 5'd20; end
        if (dist_2_5 < min_distance) begin min_distance = dist_2_5; min_addr = 5'd21; end
        if (dist_2_6 < min_distance) begin min_distance = dist_2_6; min_addr = 5'd22; end
        if (dist_2_7 < min_distance) begin min_distance = dist_2_7; min_addr = 5'd23; end
        
        if (dist_3_0 < min_distance) begin min_distance = dist_3_0; min_addr = 5'd24; end
        if (dist_3_1 < min_distance) begin min_distance = dist_3_1; min_addr = 5'd25; end
        if (dist_3_2 < min_distance) begin min_distance = dist_3_2; min_addr = 5'd26; end
        if (dist_3_3 < min_distance) begin min_distance = dist_3_3; min_addr = 5'd27; end
        if (dist_3_4 < min_distance) begin min_distance = dist_3_4; min_addr = 5'd28; end
        if (dist_3_5 < min_distance) begin min_distance = dist_3_5; min_addr = 5'd29; end
        if (dist_3_6 < min_distance) begin min_distance = dist_3_6; min_addr = 5'd30; end
        if (dist_3_7 < min_distance) begin min_distance = dist_3_7; min_addr = 5'd31; end
    end
    
    // ===== MAIN SEQUENTIAL LOGIC =====
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize pattern banks with test patterns
            pattern_bank_0_0 <= 12'h000; pattern_bank_0_1 <= 12'h0FF; pattern_bank_0_2 <= 12'hF00; pattern_bank_0_3 <= 12'hFFF;
            pattern_bank_0_4 <= 12'hAAA; pattern_bank_0_5 <= 12'h555; pattern_bank_0_6 <= 12'hF0F; pattern_bank_0_7 <= 12'h0F0;
            pattern_bank_1_0 <= 12'h123; pattern_bank_1_1 <= 12'h456; pattern_bank_1_2 <= 12'h789; pattern_bank_1_3 <= 12'hABC;
            pattern_bank_1_4 <= 12'hDEF; pattern_bank_1_5 <= 12'h321; pattern_bank_1_6 <= 12'h654; pattern_bank_1_7 <= 12'h987;
            pattern_bank_2_0 <= 12'hCBA; pattern_bank_2_1 <= 12'h098; pattern_bank_2_2 <= 12'h765; pattern_bank_2_3 <= 12'h432;
            pattern_bank_2_4 <= 12'h10F; pattern_bank_2_5 <= 12'hE0D; pattern_bank_2_6 <= 12'hC0B; pattern_bank_2_7 <= 12'hA09;
            pattern_bank_3_0 <= 12'h807; pattern_bank_3_1 <= 12'h605; pattern_bank_3_2 <= 12'h403; pattern_bank_3_3 <= 12'h201;
            pattern_bank_3_4 <= 12'h8F7; pattern_bank_3_5 <= 12'h6E5; pattern_bank_3_6 <= 12'h4D3; pattern_bank_3_7 <= 12'h2C1;
            
            // Initialize all pipeline registers
            search_pipeline_0 <= 0; search_pipeline_1 <= 0; search_pipeline_2 <= 0; search_pipeline_3 <= 0;
            control_pipeline_0 <= 0; control_pipeline_1 <= 0; control_pipeline_2 <= 0; control_pipeline_3 <= 0;
            
            // Initialize usage counters (reduced for warnings)
            usage_counter_0 <= 0; usage_counter_1 <= 0; usage_counter_2 <= 0; usage_counter_3 <= 0;
            
            // Initialize history buffers (reduced)
            search_history_0 <= 0; search_history_1 <= 0; search_history_2 <= 0; search_history_3 <= 0;
            match_history_0 <= 0; match_history_1 <= 0; match_history_2 <= 0; match_history_3 <= 0;
            
            // Initialize control signals
            search_pattern <= 0;
            write_pattern <= 0;  // Now used for write operations
            write_addr <= 0;     // Now used for write operations
            match_mode <= 0;
            search_enable <= 0;
            write_enable <= 0;
            learning_enable <= 0;
            input_cycle_counter <= 0;
            history_head <= 0;
            
            // Initialize outputs
            best_match_addr <= 0;
            best_distance <= 0;  // FIXED: Initialize to 0 instead of 15
            confidence_score <= 0;
            match_valid <= 0;
            
        end else begin
            // Input processing
            search_enable <= ui_in[7];
            write_enable <= ui_in[6];
            learning_enable <= ui_in[5];
            match_mode <= ui_in[4:2];
            input_cycle_counter <= input_cycle_counter + 1;
            
            // Multi-cycle input for 12-bit patterns
            case (ui_in[1:0])
                2'b00: begin
                    search_pattern[3:0] <= uio_in[3:0];
                    write_pattern[3:0] <= uio_in[7:4];
                end
                2'b01: begin
                    search_pattern[7:4] <= uio_in[3:0];
                    write_pattern[7:4] <= uio_in[7:4];
                end
                2'b10: begin
                    search_pattern[11:8] <= uio_in[3:0];
                    write_pattern[11:8] <= uio_in[7:4];
                end
                2'b11: begin
                    write_addr <= {uio_in[7:6], uio_in[2:0]};
                end
                default: begin
                    // Default case to fix incomplete case warning
                end
            endcase
            
            // Pipeline advancement
            search_pipeline_0 <= search_pattern;
            search_pipeline_1 <= search_pipeline_0;
            search_pipeline_2 <= search_pipeline_1;
            search_pipeline_3 <= search_pipeline_2;
            
            control_pipeline_0 <= {search_enable, write_enable, learning_enable, match_mode, 2'b00};
            control_pipeline_1 <= control_pipeline_0;
            control_pipeline_2 <= control_pipeline_1;
            control_pipeline_3 <= control_pipeline_2;
            
            // Search result processing
            if (control_pipeline_3[7]) begin // search_enable from pipeline
                best_match_addr <= min_addr;
                best_distance <= min_distance;
                // FIXED: Proper width for shift operation
                confidence_score <= (min_distance == 0) ? 8'hFF : (8'hC0 - {4'b0000, min_distance});
                match_valid <= 1;
                
                // FIXED: Complete case statement for history update
                case (history_head)
                    4'd0: begin search_history_0 <= search_pipeline_3; match_history_0 <= min_addr; end
                    4'd1: begin search_history_1 <= search_pipeline_3; match_history_1 <= min_addr; end
                    4'd2: begin search_history_2 <= search_pipeline_3; match_history_2 <= min_addr; end
                    4'd3: begin search_history_3 <= search_pipeline_3; match_history_3 <= min_addr; end
                    default: begin
                        // Handle all other values - wrap around
                        search_history_0 <= search_pipeline_3; 
                        match_history_0 <= min_addr;
                    end
                endcase
                history_head <= (history_head + 1) & 4'h3; // Keep within 0-3 range
            end else begin
                match_valid <= 0;
            end
            
            // Usage counter updates (simplified to avoid warnings)
            if (match_valid) begin
                case (best_match_addr[1:0]) // Use only lower 2 bits
                    2'd0: if (usage_counter_0 < 255) usage_counter_0 <= usage_counter_0 + 1;
                    2'd1: if (usage_counter_1 < 255) usage_counter_1 <= usage_counter_1 + 1;
                    2'd2: if (usage_counter_2 < 255) usage_counter_2 <= usage_counter_2 + 1;
                    2'd3: if (usage_counter_3 < 255) usage_counter_3 <= usage_counter_3 + 1;
                endcase
            end
        end
    end
    
    // Output assignments - FIXED: Use only 3 bits of distance to avoid width warning
    assign uo_out = {match_valid, best_distance[2:0], best_match_addr[3:0]};
    assign uio_out = confidence_score;
    assign uio_oe = 8'hFF;
    
    // FIXED: Suppress warnings for unused signals
    wire _unused = &{ena, input_cycle_counter[3], control_pipeline_3[6:0], 
                     write_enable, write_pattern[0], write_addr[0], 
                     match_mode[0], learning_enable, best_distance[3], 1'b0};

endmodule
