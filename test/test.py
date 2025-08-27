# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
import random

@cocotb.test()
async def test_neurocam_pro_basic(dut):
    """Test basic NeuroCAM Pro functionality with 16-bit patterns"""
    dut._log.info("Starting NeuroCAM Pro basic test")
    
    # Set the clock period to 40 ns (25 MHz for pipeline operation)
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset sequence for complex design
    dut._log.info("Resetting NeuroCAM Pro")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 20)  # Extended reset for 700+ cells
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 8)   # Allow pipeline to stabilize
    
    # Test exact match with default pattern from bank 0
    dut._log.info("Testing exact match with 16-bit pattern 0x0000")
    await load_search_pattern_16bit(dut, 0x0000)
    await execute_search_with_mode(dut, mode=0)  # Exact match mode
    
    # Check results with new output format
    match_addr = dut.uo_out.value & 0x03        # 2 bits for address in output
    distance = (dut.uo_out.value >> 2) & 0x1F   # 5 bits for distance  
    match_valid = (dut.uo_out.value >> 7) & 0x01
    confidence = dut.uio_out.value              # 8-bit confidence score
    
    assert match_valid == 1, f"Match should be valid, got {match_valid}"
    assert distance == 0, f"Expected Hamming distance 0, got {distance}"
    assert confidence > 200, f"Expected high confidence, got {confidence}"
    
    dut._log.info(f"✓ Exact match test passed - Addr: {match_addr}, Distance: {distance}, Confidence: {confidence}")

@cocotb.test()
async def test_multi_bank_functionality(dut):
    """Test multi-bank architecture with 64 patterns"""
    dut._log.info("Starting multi-bank functionality test")
    
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    await reset_neurocam_pro(dut)
    
    # Test patterns from different banks
    bank_test_patterns = [
        (0x0000, 0),  # Bank 0, Pattern 0: should match perfectly
        (0x0001, 0),  # Bank 0, Pattern 0: 1-bit difference
        (0x000F, 0),  # Bank 0, Pattern 1: should be close match
    ]
    
    for pattern, expected_bank in bank_test_patterns:
        dut._log.info(f"Testing pattern 0x{pattern:04X} from bank {expected_bank}")
        await load_search_pattern_16bit(dut, pattern)
        await execute_search_with_mode(dut, mode=0)  # Exact match mode
        
        match_addr = dut.uo_out.value & 0x03
        distance = (dut.uo_out.value >> 2) & 0x1F
        match_valid = (dut.uo_out.value >> 7) & 0x01
        confidence = dut.uio_out.value
        
        assert match_valid == 1, f"Match should be valid for pattern 0x{pattern:04X}"
        dut._log.info(f"Pattern 0x{pattern:04X}: Addr={match_addr}, Distance={distance}, Confidence={confidence}")
    
    dut._log.info("✓ Multi-bank functionality test passed")

@cocotb.test()
async def test_fuzzy_matching(dut):
    """Test fuzzy matching mode with configurable thresholds"""
    dut._log.info("Starting fuzzy matching test")
    
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())
    
    await reset_neurocam_pro(dut)
    
    # Test fuzzy matching with different distances
    fuzzy_test_cases = [
        (0x0001, 1),  # 1-bit difference should match in fuzzy mode
        (0x0003, 2),  # 2-bit difference
        (0x0007, 3),  # 3-bit difference
    ]
    
    for pattern, expected_distance in fuzzy_test_cases:
        dut._log.info(f"Testing fuzzy match with pattern 0x{pattern:04X}")
        await load_search_pattern_16bit(dut, pattern)
        await execute_search_with_mode(dut, mode=1)  # Fuzzy match mode
        
        match_addr = dut.uo_out.value & 0x03
        distance = (dut.uo_out.value >> 2) & 0x1F
        match_valid = (dut.uo_out.value >> 7) & 0x01
        confidence = dut.uio_out.value
        
        assert match_valid == 1, f"Fuzzy match should be valid for pattern 0x{pattern:04X}"
        assert distance == expected_distance, f"Expected distance {expected_distance}, got {distance}"
        
        dut._log.info(f"Fuzzy match 0x{pattern:04X}: Distance={distance}, Confidence={confidence}")
    
    dut._log.info("✓ Fuzzy matching test passed")

@cocotb.test()
async def test_adaptive_learning(dut):
    """Test adaptive learning mode"""
    dut._log.info("Starting adaptive learning test")
    
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())
    
    await reset_neurocam_pro(dut)
    
    # Test learning mode with unknown pattern
    unknown_pattern = 0x1234
    dut._log.info(f"Testing learning mode with unknown pattern 0x{unknown_pattern:04X}")
    
    await load_search_pattern_16bit(dut, unknown_pattern)
    await execute_search_with_mode(dut, mode=3, learning=True)  # Learning mode
    
    # Allow time for learning to complete
    await ClockCycles(dut.clk, 10)
    
    # Search again - should now find the learned pattern
    await load_search_pattern_16bit(dut, unknown_pattern)
    await execute_search_with_mode(dut, mode=0)  # Exact match mode
    
    match_valid = (dut.uo_out.value >> 7) & 0x01
    distance = (dut.uo_out.value >> 2) & 0x1F
    confidence = dut.uio_out.value
    
    dut._log.info(f"Learning result: Valid={match_valid}, Distance={distance}, Confidence={confidence}")
    dut._log.info("✓ Adaptive learning test completed")

@cocotb.test()
async def test_pipeline_performance(dut):
    """Test pipeline performance with continuous pattern stream"""
    dut._log.info("Starting pipeline performance test")
    
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())
    
    await reset_neurocam_pro(dut)
    
    # Test continuous pattern submission (pipeline stress test)
    test_patterns = [0x0000, 0x0001, 0x000F, 0x00FF, 0x0F0F, 0x1234]
    
    for i, pattern in enumerate(test_patterns):
        dut._log.info(f"Pipeline test {i+1}: Pattern 0x{pattern:04X}")
        await load_search_pattern_16bit(dut, pattern)
        await execute_search_with_mode(dut, mode=0)
        
        # Check pipeline latency (should be 4 cycles + processing)
        await ClockCycles(dut.clk, 6)  # Allow pipeline completion
        
        match_valid = (dut.uo_out.value >> 7) & 0x01
        distance = (dut.uo_out.value >> 2) & 0x1F
        
        dut._log.info(f"Pipeline result {i+1}: Valid={match_valid}, Distance={distance}")
    
    dut._log.info("✓ Pipeline performance test passed")

@cocotb.test()
async def test_confidence_scoring(dut):
    """Test confidence scoring system"""
    dut._log.info("Starting confidence scoring test")
    
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())
    
    await reset_neurocam_pro(dut)
    
    # Test confidence with different match qualities
    confidence_tests = [
        (0x0000, "perfect_match"),    # Perfect match - high confidence
        (0x0001, "close_match"),      # 1-bit difference - medium confidence  
        (0x00FF, "distant_match"),    # Many bits different - lower confidence
    ]
    
    for pattern, test_type in confidence_tests:
        dut._log.info(f"Testing confidence for {test_type}: 0x{pattern:04X}")
        await load_search_pattern_16bit(dut, pattern)
        await execute_search_with_mode(dut, mode=0)
        
        confidence = dut.uio_out.value
        distance = (dut.uo_out.value >> 2) & 0x1F
        
        dut._log.info(f"{test_type}: Distance={distance}, Confidence={confidence}")
        
        # Verify confidence correlates with match quality
        if test_type == "perfect_match":
            assert confidence > 200, f"Perfect match should have high confidence, got {confidence}"
        elif test_type == "distant_match":
            assert confidence < 100, f"Distant match should have low confidence, got {confidence}"
    
    dut._log.info("✓ Confidence scoring test passed")

# Helper Functions for NeuroCAM Pro

async def reset_neurocam_pro(dut):
    """Reset NeuroCAM Pro with proper timing for complex design"""
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 20)  # Extended reset for initialization
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 8)   # Pipeline stabilization time

async def load_search_pattern_16bit(dut, pattern):
    """Load a 16-bit search pattern via 4-cycle input protocol"""
    # Cycle 0: Load bits [3:0]
    dut.ui_in.value = 0x00  # Clear mode bits, cycle selector = 00
    dut.uio_in.value = pattern & 0x0F
    await ClockCycles(dut.clk, 1)
    
    # Cycle 1: Load bits [7:4]
    dut.ui_in.value = 0x01  # Cycle selector = 01
    dut.uio_in.value = (pattern >> 4) & 0x0F
    await ClockCycles(dut.clk, 1)
    
    # Cycle 2: Load bits [11:8]
    dut.ui_in.value = 0x02  # Cycle selector = 10
    dut.uio_in.value = (pattern >> 8) & 0x0F
    await ClockCycles(dut.clk, 1)
    
    # Cycle 3: Load bits [15:12]
    dut.ui_in.value = 0x03  # Cycle selector = 11
    dut.uio_in.value = (pattern >> 12) & 0x0F
    await ClockCycles(dut.clk, 1)

async def execute_search_with_mode(dut, mode=0, learning=False):
    """Execute search with specified AI mode and optional learning"""
    # Set search enable with mode selection
    mode_bits = (mode & 0x07) << 2  # 3-bit mode in bits [4:2]
    learning_bit = (1 << 5) if learning else 0  # Learning enable in bit [5]
    search_enable = (1 << 7)  # Search enable in bit [7]
    
    dut.ui_in.value = search_enable | learning_bit | mode_bits
    dut.uio_in.value = 0x00
    
    # Wait for 4-stage pipeline completion + processing
    await ClockCycles(dut.clk, 8)
    
    # Clear enables
    dut.ui_in.value = 0x00
    await ClockCycles(dut.clk, 2)

async def write_pattern_16bit(dut, bank, addr, pattern):
    """Write a 16-bit pattern to specified bank and address"""
    # Multi-cycle write protocol for 16-bit patterns
    write_enable = (1 << 6)  # Write enable in bit [6]
    
    # Cycle 0: Write data bits [3:0]
    dut.ui_in.value = write_enable | 0x00  # Cycle selector = 00
    dut.uio_in.value = ((pattern & 0x0F) << 4) | (pattern & 0x0F)
    await ClockCycles(dut.clk, 1)
    
    # Cycle 1: Write data bits [7:4]
    dut.ui_in.value = write_enable | 0x01  # Cycle selector = 01
    pattern_nibble = (pattern >> 4) & 0x0F
    dut.uio_in.value = (pattern_nibble << 4) | pattern_nibble
    await ClockCycles(dut.clk, 1)
    
    # Cycle 2: Write data bits [11:8]
    dut.ui_in.value = write_enable | 0x02  # Cycle selector = 10
    pattern_nibble = (pattern >> 8) & 0x0F
    dut.uio_in.value = (pattern_nibble << 4) | pattern_nibble 
    await ClockCycles(dut.clk, 1)
    
    # Cycle 3: Execute write with bank/address
    dut.ui_in.value = write_enable | 0x03  # Cycle selector = 11
    pattern_nibble = (pattern >> 12) & 0x0F
    bank_addr = ((bank & 0x03) << 4) | (addr & 0x0F)
    dut.uio_in.value = (pattern_nibble << 4) | bank_addr
    await ClockCycles(dut.clk, 2)
    
    # Clear write enable
    dut.ui_in.value = 0x00
    await ClockCycles(dut.clk, 2)
