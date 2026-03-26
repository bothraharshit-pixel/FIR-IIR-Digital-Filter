// ============================================================
// Project      : FIR Low-Pass Filter Hardware Implementation
// Author       : Harshit Bothra
// College      : PES University, ECE Department
// Tool         : ModelSim / Xilinx Vivado
// Description  : 17-tap FIR low-pass filter in SystemVerilog.
//                Coefficients derived from MATLAB fir1() design.
//                Uses Q15 fixed-point arithmetic.
//                Cutoff: 1000Hz, Sampling: 8000Hz, Order: 16
// ============================================================

module fir_filter (
    input  logic        clk,          // Clock
    input  logic        rst,          // Active-high synchronous reset
    input  logic        valid_in,     // Input sample valid strobe
    input  logic signed [15:0] x_in,  // 16-bit signed input sample (Q15)
    output logic signed [31:0] y_out, // 32-bit signed filtered output
    output logic        valid_out     // Output valid strobe
);

    // ============================================================
    // FILTER PARAMETERS
    // 17 taps (order 16), symmetric — FIR filters are always symmetric
    // for linear phase response
    // Coefficients from MATLAB: fir1(16, 1000/4000, hamming(17))
    // Scaled to Q15: multiply by 2^15 = 32768
    // ============================================================
    localparam int TAPS = 17;

    // Symmetric FIR coefficients in Q15 fixed-point format
    // h[0]=h[16], h[1]=h[15], ... (linear phase property)
    logic signed [15:0] coeff [0:TAPS-1];
    initial begin
        coeff[0]  = 16'sd  -67;
        coeff[1]  = 16'sd  -75;
        coeff[2]  = 16'sd  187;
        coeff[3]  = 16'sd  746;
        coeff[4]  = 16'sd 1609;
        coeff[5]  = 16'sd 2682;
        coeff[6]  = 16'sd 3712;
        coeff[7]  = 16'sd 4380;
        coeff[8]  = 16'sd 4608;   // Center tap (largest)
        coeff[9]  = 16'sd 4380;
        coeff[10] = 16'sd 3712;
        coeff[11] = 16'sd 2682;
        coeff[12] = 16'sd 1609;
        coeff[13] = 16'sd  746;
        coeff[14] = 16'sd  187;
        coeff[15] = 16'sd  -75;
        coeff[16] = 16'sd  -67;
    end

    // ============================================================
    // SHIFT REGISTER (Delay Line)
    // Stores the last TAPS samples — this is the "memory" of the filter
    // Each clock cycle, old samples shift right, new sample enters left
    // y[n] = sum(h[k] * x[n-k]) for k = 0 to TAPS-1
    // ============================================================
    logic signed [15:0] shift_reg [0:TAPS-1];

    always_ff @(posedge clk) begin
        if (rst) begin
            // Clear all delay elements on reset
            for (int i = 0; i < TAPS; i++)
                shift_reg[i] <= 16'sb0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            // Shift existing samples and insert new one at position 0
            // shift_reg[0] = newest sample
            // shift_reg[TAPS-1] = oldest sample
            shift_reg[0] <= x_in;
            for (int i = 1; i < TAPS; i++)
                shift_reg[i] <= shift_reg[i-1];
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

    // ============================================================
    // MAC (Multiply-Accumulate) Unit
    // Computes dot product: y = sum(h[k] * x[n-k])
    // Uses combinational logic for simplicity
    // In hardware synthesis, this maps to DSP48 blocks on Xilinx FPGAs
    // ============================================================
    logic signed [31:0] products [0:TAPS-1]; // Each product: 16+16=32 bits
    logic signed [35:0] accumulator;          // Extra bits to prevent overflow

    always_comb begin
        accumulator = 36'sb0;
        for (int k = 0; k < TAPS; k++) begin
            // Multiply: 16-bit coeff x 16-bit sample = 32-bit product
            products[k] = coeff[k] * shift_reg[k];
            accumulator = accumulator + products[k];
        end
    end

    // Output: take bits [31:0] — drop the overflow guard bits
    // In real hardware, you'd saturate or round here
    assign y_out = accumulator[31:0];

endmodule
