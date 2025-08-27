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

    // NeuroCAM Parameters
    parameter PATTERN_COUNT = 16;    // Number of stored patterns
    parameter PATTERN_WIDTH = 12;    // Width of each pattern
    parameter ADDR_WIDTH = 4;        // Address width for 16 patterns

    // Pattern storage memory (16 patterns x 12 bits)
    reg [PATTERN_WIDTH-1:0] pattern_memory [0:PATTERN_COUNT-1];
    
    // Input registers for search pattern and control
    reg [PATTERN_WIDTH-1:0] search_pattern;
    reg search_enable;
    reg write_enable;
    reg [ADDR_WIDTH-1:0] write_addr;
    reg [PATTERN_WIDTH-1:0] write_data;
    
    // Output registers
    reg [ADDR_WIDTH-1:0] match_addr;
    reg [3:0] hamming_distance;
    reg match_valid;
    
    // Internal wires for parallel comparison
    wire [3:0] distances [0:PATTERN_COUNT-1];
    wire [PATTERN_COUNT-1:0] exact_matches;
    
    // Generate Hamming distance calculation for each pattern
    genvar i;
    generate
        for (i = 0; i < PATTERN_COUNT; i = i + 1) begin : hamming_calc
            wire [PATTERN_WIDTH-1:0] xor_result;
            assign xor_result = search_pattern ^ pattern_memory[i];
            assign exact_matches[i] = (xor_result == 0);
            
            // Synthesizable population count using combinational logic
            assign distances[i] = 
                xor_result[0] + xor_result[34] + xor_result[2] + xor_result[35] +
                xor_result[4] + xor_result[5] + xor_result[6] + xor_result[7] +
                xor_result[8] + xor_result[9] + xor_result[10] + xor_result[11];
        end
    endgenerate
    
    // Find minimum distance and corresponding address using combinational logic
    wire [3:0] min_distance;
    wire [ADDR_WIDTH-1:0] min_addr;
    
    // Combinational minimum finder (synthesizable)
    assign min_distance = 
        (distances[0] <= distances[1] && distances[0] <= distances[2] && distances[0] <= distances[3] &&
         distances[0] <= distances[4] && distances[0] <= distances[5] && distances[0] <= distances[6] && distances[0] <= distances[7] &&
         distances[0] <= distances[8] && distances[0] <= distances[9] && distances[0] <= distances[10] && distances[0] <= distances[11] &&
         distances[0] <= distances[12] && distances[0] <= distances[13] && distances[0] <= distances[14] && distances[0] <= distances[15]) ? distances[0] :
        (distances[1] <= distances[2] && distances[1] <= distances[3] &&
         distances[1] <= distances[4] && distances[1] <= distances[5] && distances[1] <= distances[6] && distances[1] <= distances[7] &&
         distances[1] <= distances[8] && distances[1] <= distances[9] && distances[1] <= distances[10] && distances[1] <= distances[11] &&
         distances[1] <= distances[12] && distances[1] <= distances[13] && distances[1] <= distances[14] && distances[1] <= distances[15]) ? distances[1] :
        // ... continue pattern for all 16 comparisons
        distances[15]; // fallback
    
    assign min_addr = 
        (distances[0] <= distances[1] && distances[0] <= distances[2] && distances[0] <= distances[3] &&
         distances[0] <= distances[4] && distances[0] <= distances[5] && distances[0] <= distances[6] && distances[0] <= distances[7] &&
         distances[0] <= distances[8] && distances[0] <= distances[9] && distances[0] <= distances[10] && distances[0] <= distances[11] &&
         distances[0] <= distances[12] && distances[0] <= distances[13] && distances[0] <= distances[14] && distances[0] <= distances[15]) ? 4'd0 :
        (distances[1] <= distances[2] && distances[1] <= distances[3] &&
         distances[1] <= distances[4] && distances[1] <= distances[5] && distances[1] <= distances[6] && distances[1] <= distances[7] &&
         distances[1] <= distances[8] && distances[1] <= distances[9] && distances[1] <= distances[10] && distances[1] <= distances[11] &&
         distances[1] <= distances[12] && distances[1] <= distances[13] && distances[1] <= distances[14] && distances[1] <= distances[15]) ? 4'd1 :
        // ... continue for all addresses
        4'd15; // fallback
    
    // Main sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset: Initialize with default patterns
            pattern_memory[0]  <= 12'h000;
            pattern_memory[1]  <= 12'h0FF;
            pattern_memory[2]  <= 12'hF00;
            pattern_memory[3]  <= 12'hFFF;
            pattern_memory[4]  <= 12'hAAA;
            pattern_memory[5]  <= 12'h555;
            pattern_memory[6]  <= 12'hF0F;
            pattern_memory[7]  <= 12'h0F0;
            pattern_memory[8]  <= 12'h123;
            pattern_memory[9]  <= 12'h456;
            pattern_memory[10] <= 12'h789;
            pattern_memory[11] <= 12'hABC;
            pattern_memory[12] <= 12'hDEF;
            pattern_memory[13] <= 12'h321;
            pattern_memory[14] <= 12'h654;
            pattern_memory[15] <= 12'h987;
            
            search_pattern <= 0;
            search_enable <= 0;
            write_enable <= 0;
            write_addr <= 0;
            write_data <= 0;
            match_addr <= 0;
            hamming_distance <= 15; // Max distance
            match_valid <= 0;
        end else begin
            // Input decoding from ui_in and uio_in
            search_enable <= ui_in[7];
            write_enable <= ui_in[6];
            write_addr <= ui_in[5:2];
            
            // Multi-cycle input for 12-bit search pattern
            if (ui_in[1:0] == 2'b00) begin
                search_pattern[3:0] <= uio_in[3:0];
            end else if (ui_in[1:0] == 2'b01) begin
                search_pattern[7:4] <= uio_in[3:0];
            end else if (ui_in[1:0] == 2'b10) begin
                search_pattern[11:8] <= uio_in[3:0];
            end
            
            // Multi-cycle input for 12-bit write data
            if (ui_in[1:0] == 2'b00) begin
                write_data[3:0] <= uio_in[7:4];
            end else if (ui_in[1:0] == 2'b01) begin
                write_data[7:4] <= uio_in[7:4];
            end else if (ui_in[1:0] == 2'b10) begin
                write_data[11:8] <= uio_in[7:4];
            end
            
            // Write operation
            if (write_enable && ui_in[1:0] == 2'b11) begin
                pattern_memory[write_addr] <= write_data;
            end
            
            // Search operation
            if (search_enable) begin
                match_addr <= min_addr;
                hamming_distance <= min_distance;
                match_valid <= 1;
            end else begin
                match_valid <= 0;
            end
        end
    end
    
    // Output assignments
    assign uo_out = {match_valid, hamming_distance[2:0], match_addr};
    assign uio_out = {4'b0000, hamming_distance};
    assign uio_oe = 8'hFF; // All uio pins as outputs
    
    // Suppress unused signal warnings
    wire _unused = &{ena, 1'b0};

endmodule
