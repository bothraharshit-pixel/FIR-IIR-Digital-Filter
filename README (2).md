# FIR / IIR Digital Filter — MATLAB + SystemVerilog

**Author:** Harshit Bothra
**Institution:** PES University, ECE Department
**Year:** 2nd Year
**Tools:** MATLAB, Simulink, SystemVerilog, ModelSim / Xilinx Vivado

---

## Project Overview

A complete **digital filter design and hardware implementation** project. The filter is first designed and verified in MATLAB using the windowing method, then the coefficients are exported and implemented as a synthesizable hardware module in SystemVerilog — exactly the workflow used in industry for DSP-to-hardware pipelines.

This project bridges signal processing theory and VLSI hardware implementation, directly relevant to GPU signal processing and audio/video compute pipelines at Nvidia.

---

## Filter Specifications

| Parameter | Value |
|-----------|-------|
| Filter Type | FIR Low-Pass |
| Design Method | Hamming Window |
| Filter Order | 16 (17 taps) |
| Cutoff Frequency | 1000 Hz |
| Sampling Frequency | 8000 Hz |
| Arithmetic | Q15 Fixed-Point (16-bit) |
| Hardware Target | Xilinx FPGA (DSP48 blocks) |

---

## File Structure

```
fir_filter/
├── fir_filter_design.m    # MATLAB: filter design, analysis, coefficient export
├── fir_filter.sv          # SystemVerilog: hardware FIR implementation
├── fir_filter_tb.sv       # SystemVerilog: testbench with pass/stop band test
└── README.md              # Project documentation
```

---

## Workflow

```
MATLAB Design          →      Hardware Implementation
──────────────────────────────────────────────────────
fir1() design          →      coeff[] array in .sv
freqz() verification   →      fir_filter_tb.sv tests
FFT analysis           →      pass/stop band check
Q15 coefficient export →      16-bit signed parameters
```

---

## How to Run

### Step 1: MATLAB (Filter Design)
```matlab
% Run in MATLAB
run('fir_filter_design.m')
% Outputs:
% - Frequency response plots
% - Fixed-point coefficients
% - FIR vs IIR comparison plot
```

### Step 2: ModelSim (Hardware Simulation)
```bash
vlog fir_filter.sv fir_filter_tb.sv
vsim fir_filter_tb
run -all
```

### Step 3: Vivado (FPGA Synthesis)
1. Add `fir_filter.sv` as design source
2. Run Synthesis → check DSP48 utilization report
3. Verify timing constraints met

---

## Key Concepts Demonstrated

- **FIR Filter Design** — windowing method, Hamming window, linear phase
- **Q15 Fixed-Point Arithmetic** — scaling real coefficients to 16-bit integers
- **Shift Register (Delay Line)** — hardware implementation of x[n-k]
- **MAC Unit** — multiply-accumulate maps to FPGA DSP48 blocks
- **valid/ready handshake** — standard hardware data flow control
- **MATLAB-to-HDL workflow** — industry-standard design methodology

---

## Resume Description

> Designed a 17-tap FIR low-pass filter in MATLAB using the Hamming window method and verified frequency response via FFT analysis. Exported Q15 fixed-point coefficients and implemented the filter in SystemVerilog using a shift-register delay line and MAC unit. Verified passband and stopband behavior through a self-checking testbench with sinusoidal test inputs.

---

## FIR vs IIR Comparison

| Feature | FIR | IIR |
|---------|-----|-----|
| Phase | Linear (always stable) | Non-linear |
| Stability | Always stable | May be unstable |
| Taps needed | More | Fewer |
| Hardware | No feedback (simpler) | Has feedback |
| Best for | Audio, communications | Sharp cutoff needed |

---

## Relevance to Nvidia

DSP pipelines are at the core of GPU workloads — from audio processing in GeForce to video encode/decode in Tegra. This project demonstrates the full MATLAB→HDL design flow, fixed-point arithmetic awareness, and understanding of synthesizable hardware — all skills directly applicable to Nvidia's signal processing and GPU compute teams.
