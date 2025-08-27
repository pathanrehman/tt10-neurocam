`default_nettype none
`timescale 1ns / 1ps

/* This testbench instantiates the NeuroCAM Pro module and provides convenient wires
   for testing the advanced AI pattern matching functionality via cocotb test.py.
*/
module tb ();
  // Dump all signals to VCD file for comprehensive debugging
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Clock and control signals
  reg clk;
  reg rst_n;
  reg ena;
  
  // Input/Output interface (8-bit each as per Tinytapeout standard)
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  // Power supply connections for gate-level testing
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // Instantiate the NeuroCAM Pro design under test
  tt_um_neurocam neurocam_dut (
      // Power connections for gate-level simulation
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif
      // Standard Tinytapeout interface
      .ui_in  (ui_in),    // Dedicated inputs [7:0]
      .uo_out (uo_out),   // Dedicated outputs [7:0]
      .uio_in (uio_in),   // Bidirectional IOs: Input path [7:0]
      .uio_out(uio_out),  // Bidirectional IOs: Output path [7:0]
      .uio_oe (uio_oe),   // Bidirectional IOs: Enable (1=output, 0=input) [7:0]
      .ena    (ena),      // Enable signal (always 1 when design is powered)
      .clk    (clk),      // 25MHz system clock for pipeline operation
      .rst_n  (rst_n)     // Active-low reset for initialization
  );

  // Optional: Monitor key internal signals for debugging (RTL simulation only)
`ifndef GL_TEST
  // Monitor pipeline stages for debugging
  wire [15:0] current_search_pattern = neurocam_dut.search_pipeline[3];
  wire [5:0] current_best_addr = neurocam_dut.best_match_addr;
  wire [4:0] current_distance = neurocam_dut.best_distance;
  wire [7:0] current_confidence = neurocam_dut.confidence_score;
  wire current_match_valid = neurocam_dut.match_valid;
  
  // Monitor bank distances for verification
  wire [4:0] bank0_best = neurocam_dut.bank_best_distances[0];
  wire [4:0] bank1_best = neurocam_dut.bank_best_distances[1];
  wire [4:0] bank2_best = neurocam_dut.bank_best_distances[2];
  wire [4:0] bank3_best = neurocam_dut.bank_best_distances[3];
  
  // Monitor pattern memory (first few patterns for debugging)
  wire [15:0] pattern_0_bank_0 = neurocam_dut.pattern_banks[0][0];
  wire [15:0] pattern_1_bank_0 = neurocam_dut.pattern_banks[0][1];
  wire [15:0] pattern_0_bank_1 = neurocam_dut.pattern_banks[1][0];
  
  // Monitor learning system
  wire [15:0] learned_pattern_0 = neurocam_dut.learned_patterns[0];
  wire learning_active = neurocam_dut.learning_enable;
  wire [2:0] current_match_mode = neurocam_dut.match_mode;
`endif

  // Clock generation for 25MHz operation (40ns period)
  initial begin
    clk = 0;
    forever #20 clk = ~clk;  // 25MHz clock (40ns period)
  end

  // Initialize control signals
  initial begin
    ena = 1;     // Always enabled for Tinytapeout
    rst_n = 0;   // Start in reset
    ui_in = 0;   // Clear all inputs
    uio_in = 0;  // Clear bidirectional inputs
    
    // Hold reset for initialization
    #100;        // 100ns reset period
    rst_n = 1;   // Release reset
    
    // Allow pipeline to stabilize
    #200;        // Additional settling time
  end

  // Optional: Basic functionality monitor for RTL debugging
`ifndef GL_TEST
  always @(posedge clk) begin
    if (rst_n && current_match_valid) begin
      $display("Time=%0t: Match found - Addr=0x%02X, Distance=%0d, Confidence=%0d", 
               $time, current_best_addr, current_distance, current_confidence);
    end
  end
`endif

endmodule
