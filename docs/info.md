<!---
This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.
You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

NeuroCAM implements a **Content-Addressable Memory (CAM)** optimized for AI pattern recognition tasks. Unlike traditional memory that searches by address, CAM searches by content - making it perfect for template matching, classification, and associative memory applications.

**Core Architecture:**
- **16 stored patterns** × **12 bits each** for optimal tile utilization
- **Parallel Hamming distance calculation** for all patterns simultaneously
- **Priority encoding** to find the best matching pattern
- **Multi-cycle input interface** to handle 12-bit patterns through 8-bit I/O ports

**AI Functionality:**
- **Template Matching**: Compare input patterns against stored templates
- **Nearest Neighbor Classification**: Find closest stored pattern based on Hamming distance
- **Pattern Completion**: Identify stored patterns from partial or noisy inputs
- **Associative Memory**: Content-based retrieval for neural network applications

**Operation Modes:**
1. **Search Mode**: Input a pattern and find the best match from stored patterns
2. **Write Mode**: Store new patterns in the memory array for later matching
3. **Distance Calculation**: Compute Hamming distance between input and all stored patterns

The design uses **fixed-point arithmetic** and **combinational logic** for predictable, deterministic operation - essential for verification and real-time AI applications.

## How to test

**Basic Search Operation:**
1. **Load search pattern** using multi-cycle input:
   - Set `ui_in[1:0] = 00` and provide bits [3:0] via `uio_in[3:0]`
   - Set `ui_in[1:0] = 01` and provide bits [7:4] via `uio_in[3:0]`  
   - Set `ui_in[1:0] = 10` and provide bits [11:8] via `uio_in[3:0]`

2. **Execute search**:
   - Set `ui_in[7] = 1` (search enable)
   - Read results from `uo_out`:
     - `uo_out[3:0]`: Best match address (0-15)
     - `uo_out[6:4]`: Hamming distance (lower 3 bits)
     - `uo_out[7]`: Match valid flag
   - Full Hamming distance available on `uio_out[3:0]`

**Pattern Writing:**
1. **Set write address**: `ui_in[5:2]` (4-bit address for patterns 0-15)
2. **Load write data** using same multi-cycle method as search pattern
3. **Execute write**: Set `ui_in[6] = 1` (write enable) with `ui_in[1:0] = 11`

**Test Patterns for Verification:**
- **Exact matches**: Test with stored default patterns (0x000, 0x0FF, 0xF00, etc.)
- **Hamming distance**: Test with 1-bit, 2-bit differences from stored patterns
- **Boundary cases**: Test with all-zeros, all-ones, alternating patterns
- **Write verification**: Store custom pattern and immediately search for it

**Expected Results:**
- Searching for 0x000 should return address 0 with distance 0
- Searching for 0x001 should return address 0 with distance 1
- Invalid/no-match cases should show appropriate distance values

## External hardware

**No external hardware required** - NeuroCAM is a purely digital design that operates standalone.

**Optional Testing Equipment:**
- **Logic analyzer** or **oscilloscope** for observing multi-cycle input sequences
- **Microcontroller** (Arduino, Raspberry Pi) for automated testing and pattern injection
- **LED indicators** connected to output pins for visual verification of match results

**Recommended Test Setup:**
- Connect input switches to `ui_in` for manual control
- Connect LEDs to `uo_out` to visualize match address and distance
- Use UART interface for automated pattern loading and result logging

**Integration with AI Systems:**
- **UART/SPI interface**: For integration with microcontrollers running AI inference
- **Parallel data buses**: Direct connection to FPGA-based AI accelerators
- **Sensor preprocessing**: Connect to ADCs for real-time pattern recognition from sensors

The design's **8-bit I/O interface** makes it compatible with standard microcontroller ecosystems while the **parallel processing architecture** provides the speed necessary for real-time AI applications.
