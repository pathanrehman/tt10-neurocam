# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
import random

@cocotb.test()
async def test_neurocam_basic(dut):
    """Test basic NeuroCAM functionality"""
    dut._log.info("Starting NeuroCAM basic test")
    
    # Set the clock period to 100 ns (10 MHz)
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut._log.info("Resetting NeuroCAM")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Test exact match with default pattern 0x000 (pattern 0)
    dut._log.info("Testing exact match with pattern 0x000")
    await load_search_pattern(dut, 0x000)
    await execute_search(dut)
    
    # Check results
    match_addr = dut.uo_out.value & 0x0F
    hamming_dist = (dut.uo_out.value >> 4) & 0x07
    match_valid = (dut.uo_out.value >> 7) & 0x01
    
    assert match_valid == 1, f"Match should be valid, got {match_valid}"
    assert match_addr == 0, f"Expected match address 0, got {match_addr}"
    assert hamming_dist == 0, f"Expected Hamming distance 0, got {hamming_dist}"
    
    dut._log.info("✓ Exact match test passed")

@cocotb.test()
async def test_hamming_distance(dut):
    """Test Hamming distance calculation"""
    dut._log.info("Starting Hamming distance test")
    
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Test 1-bit difference from pattern 0x000
    dut._log.info("Testing 1-bit difference (0x001 vs 0x000)")
    await load_search_pattern(dut, 0x001)
    await execute_search(dut)
    
    match_addr = dut.uo_out.value & 0x0F
    hamming_dist = (dut.uo_out.value >> 4) & 0x07
    full_hamming = dut.uio_out.value & 0x0F
    
    assert match_addr == 0, f"Expected closest match to pattern 0, got {match_addr}"
    assert hamming_dist == 1, f"Expected Hamming distance 1, got {hamming_dist}"
    assert full_hamming == 1, f"Expected full Hamming distance 1, got {full_hamming}"
    
    dut._log.info("✓ 1-bit Hamming distance test passed")
    
    # Test with pattern 0x0FF (should match pattern 1)
    dut._log.info("Testing exact match with pattern 0x0FF")
    await load_search_pattern(dut, 0x0FF)
    await execute_search(dut)
    
    match_addr = dut.uo_out.value & 0x0F
    hamming_dist = (dut.uo_out.value >> 4) & 0x07
    
    assert match_addr == 1, f"Expected match address 1, got {match_addr}"
    assert hamming_dist == 0, f"Expected Hamming distance 0, got {hamming_dist}"
    
    dut._log.info("✓ Second exact match test passed")

@cocotb.test()
async def test_pattern_write_read(dut):
    """Test writing new patterns and reading them back"""
    dut._log.info("Starting pattern write/read test")
    
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Write a custom pattern 0x123 to address 0
    custom_pattern = 0x123
    write_addr = 0
    
    dut._log.info(f"Writing pattern 0x{custom_pattern:03X} to address {write_addr}")
    await write_pattern(dut, write_addr, custom_pattern)
    
    # Search for the pattern we just wrote
    dut._log.info("Searching for the written pattern")
    await load_search_pattern(dut, custom_pattern)
    await execute_search(dut)
    
    match_addr = dut.uo_out.value & 0x0F
    hamming_dist = (dut.uo_out.value >> 4) & 0x07
    
    assert match_addr == write_addr, f"Expected match address {write_addr}, got {match_addr}"
    assert hamming_dist == 0, f"Expected Hamming distance 0, got {hamming_dist}"
    
    dut._log.info("✓ Write/read test passed")

@cocotb.test()
async def test_multiple_patterns(dut):
    """Test with multiple different patterns"""
    dut._log.info("Starting multiple patterns test")
    
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Test patterns that should match default stored patterns
    test_cases = [
        (0x000, 0),  # Should match pattern 0
        (0x0FF, 1),  # Should match pattern 1  
        (0xF00, 2),  # Should match pattern 2
        (0xFFF, 3),  # Should match pattern 3
        (0xAAA, 4),  # Should match pattern 4
        (0x555, 5),  # Should match pattern 5
    ]
    
    for pattern, expected_addr in test_cases:
        dut._log.info(f"Testing pattern 0x{pattern:03X}, expecting address {expected_addr}")
        await load_search_pattern(dut, pattern)
        await execute_search(dut)
        
        match_addr = dut.uo_out.value & 0x0F
        hamming_dist = (dut.uo_out.value >> 4) & 0x07
        
        assert match_addr == expected_addr, f"Pattern 0x{pattern:03X}: expected addr {expected_addr}, got {match_addr}"
        assert hamming_dist == 0, f"Pattern 0x{pattern:03X}: expected distance 0, got {hamming_dist}"
    
    dut._log.info("✓ Multiple patterns test passed")

async def load_search_pattern(dut, pattern):
    """Helper function to load a 12-bit search pattern via multi-cycle input"""
    # Cycle 0: Load bits [3:0]
    dut.ui_in.value = 0x00  # Clear cycle selector
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

async def execute_search(dut):
    """Helper function to execute search operation"""
    dut.ui_in.value = 0x80  # Set search enable (bit 7)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 2)  # Allow time for search to complete
    
    # Clear search enable
    dut.ui_in.value = 0x00
    await ClockCycles(dut.clk, 1)

async def write_pattern(dut, addr, pattern):
    """Helper function to write a pattern to memory"""
    # Set write address
    write_cmd = 0x40 | (addr << 2)  # Write enable + address
    
    # Cycle 0: Load write data bits [3:0]
    dut.ui_in.value = write_cmd | 0x00  # Cycle selector = 00
    dut.uio_in.value = ((pattern & 0x0F) << 4) | (pattern & 0x0F)
    await ClockCycles(dut.clk, 1)
    
    # Cycle 1: Load write data bits [7:4]
    dut.ui_in.value = write_cmd | 0x01  # Cycle selector = 01
    dut.uio_in.value = (((pattern >> 4) & 0x0F) << 4) | ((pattern >> 4) & 0x0F)
    await ClockCycles(dut.clk, 1)
    
    # Cycle 2: Load write data bits [11:8]
    dut.ui_in.value = write_cmd | 0x02  # Cycle selector = 10
    dut.uio_in.value = (((pattern >> 8) & 0x0F) << 4) | ((pattern >> 8) & 0x0F)
    await ClockCycles(dut.clk, 1)
    
    # Cycle 3: Execute write
    dut.ui_in.value = write_cmd | 0x03  # Cycle selector = 11 (execute)
    await ClockCycles(dut.clk, 2)
    
    # Clear write enable
    dut.ui_in.value = 0x00
    await ClockCycles(dut.clk, 1)
