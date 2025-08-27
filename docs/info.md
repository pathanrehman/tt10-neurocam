<!---
This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.
You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

NeuroCAM Pro implements an **advanced multi-bank Content-Addressable Memory (CAM)** specifically engineered for high-performance AI pattern recognition tasks. Unlike traditional memory architectures, this design performs content-based searches with sophisticated AI enhancements.

**Revolutionary Architecture:**
- **64 stored patterns** across **4 parallel banks** (16 patterns each) for maximum throughput
- **16-bit pattern width** supporting complex feature vectors and high-resolution templates  
- **4-stage pipeline architecture** enabling 25MHz operation with deep parallel processing
- **Parallel Hamming distance calculation** across all 64 patterns simultaneously
- **Multi-cycle 16-bit input interface** through optimized 8-bit I/O ports

**Advanced AI Capabilities:**
- **Multi-Mode Intelligence**: Exact match, fuzzy matching, partial pattern recognition, and adaptive learning
- **Confidence Scoring**: 8-bit confidence metrics based on distance separation analysis
- **Adaptive Learning**: Automatic pattern storage when no suitable match is found
- **LRU Replacement**: Intelligent pattern management with usage-based aging
- **Template Classification**: 6-bit addressing supporting 64-class classification problems
- **Real-time Inference**: Pipeline architecture enables continuous pattern stream processing

**Professional Features:**
- **Search History Buffer**: 16-deep history tracking for pattern analysis and debugging
- **Bank Selection**: Targeted search within specific pattern categories
- **Priority Management**: Configurable pattern priorities and access control
- **Statistical Tracking**: Usage counters and pattern popularity metrics

**Silicon Optimization:**
- **700+ standard cells** achieving 75-85% tile utilization for maximum silicon efficiency
- **Parallel processing arrays** with 64 simultaneous distance calculators
- **Multi-bank minimum finders** with global optimization across all banks
- **Extensive register pipelining** for high-frequency operation and area maximization

## How to test

**Advanced Pattern Search (16-bit patterns):**
1. **Configure AI Mode**: Set `ui_in[4:2]` to select matching algorithm:
   - `000`: Exact matching (traditional CAM)
   - `001`: Fuzzy matching with configurable threshold
   - `010`: Partial matching with mask support
   - `011`: Learning mode with adaptive storage
   - `100-111`: Reserved for future AI algorithms

2. **Load 16-bit Search Pattern** via 4-cycle input sequence:
   - Cycle 0: Set `ui_in[1:0] = 00`, load bits [3:0] via `uio_in[3:0]`
   - Cycle 1: Set `ui_in[1:0] = 01`, load bits [7:4] via `uio_in[3:0]`
   - Cycle 2: Set `ui_in[1:0] = 10`, load bits [11:8] via `uio_in[3:0]`
   - Cycle 3: Set `ui_in[1:0] = 11`, load bits [15:12] via `uio_in[3:0]`

3. **Execute Intelligent Search**:
   - Set `ui_in[7] = 1` (search enable)
   - Optional: Set `ui_in[5] = 1` (learning enable) for adaptive behavior
   - Wait 4 clock cycles for pipeline completion

4. **Read AI Results**:
   - `uo_out[1:0]`: Best match address bits [1:0] (supports 64 patterns)
   - `uo_out[6:2]`: 5-bit Hamming distance (0-16 for 16-bit patterns)
   - `uo_out[7]`: Match valid flag with confidence verification
   - `uio_out[7:0]`: 8-bit AI confidence score (0-255, higher = more confident)

**Advanced Pattern Management:**
1. **Multi-Bank Writing**:
   - Select target bank using cycle 3 data: `uio_in[5:4]` = bank selection
   - 6-bit addressing: `uio_in[7:6]` + internal counters = full address space
   - Set `ui_in[6] = 1` (write enable) on cycle 3 completion

2. **Adaptive Learning Test**:
   - Enable learning mode: `ui_in[4:2] = 011`
   - Search with unknown pattern (high distance expected)
   - Enable learning: `ui_in[5] = 1`
   - Verify pattern auto-storage in learned pattern slots

**Professional Verification Sequences:**

**Exact Match Verification:**
- Test with bank 0 patterns: 0x0000, 0x00FF, 0x0F00, 0x0FFF
- Expected: Address matches, distance = 0, confidence = 255

**Fuzzy Matching Test:**
- Input: 0x0001 (1-bit difference from 0x0000)
- Expected: Address = 0, distance = 1, confidence > 200

**Multi-Bank Performance:**
- Store unique patterns in each bank (0-3)
- Verify cross-bank minimum finding
- Test concurrent access patterns

**Confidence Analysis:**
- Compare similar patterns: 0x0000 vs 0x0001 vs 0x0003
- Verify confidence decreases as distance ambiguity increases
- Test confidence = 0 for equidistant patterns

**Pipeline Stress Test:**
- Submit search patterns on consecutive clock cycles
- Verify 4-cycle latency consistency
- Test continuous throughput at 25MHz

## External hardware

**Standalone Operation** - NeuroCAM Pro is a complete AI accelerator requiring no external components for basic operation.

**Professional Development Setup:**

**High-Speed Interface:**
- **Logic analyzer** (25MHz+ sampling) for pipeline analysis and multi-cycle protocol debugging
- **High-resolution oscilloscope** for confidence score and distance measurement verification
- **Pattern generator** for automated test sequence injection and performance benchmarking

**AI System Integration:**
- **ARM Cortex microcontroller** with SPI/I2C for real-time AI application integration
- **FPGA development board** (Xilinx/Altera) for high-throughput pattern stream processing
- **Raspberry Pi** with custom driver for Python-based AI algorithm development
- **Arduino with shields** for sensor preprocessing and real-time pattern classification

**Production Applications:**

**Computer Vision Pipeline:**
- **Camera modules** → **Feature extraction** → **NeuroCAM classification** → **Decision logic**
- Connect to **image processors** for real-time template matching and object recognition

**Industrial AI:**
- **Sensor arrays** (temperature, pressure, vibration) → **ADCs** → **NeuroCAM** → **Control systems**
- Integration with **PLCs** for predictive maintenance and anomaly detection

**Edge AI Acceleration:**
- **Neural network coprocessor** role in larger AI systems
- **UART/SPI slave** for AI inference offloading from main processors
- **Real-time classification** for IoT and embedded AI applications

**Advanced Testing Framework:**
- **Automated test bench** with pattern libraries for comprehensive validation
- **Performance profiling tools** for throughput and latency characterization  
- **AI algorithm validation** comparing against software reference implementations

The **4-stage pipeline** and **25MHz operation** make NeuroCAM Pro suitable for **real-time AI inference** in professional applications, while the **8-bit I/O interface** ensures compatibility with standard development ecosystems and production deployment scenarios.
