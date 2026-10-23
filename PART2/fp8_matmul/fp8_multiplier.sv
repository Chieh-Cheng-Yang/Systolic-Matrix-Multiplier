`timescale 1ns / 1ps
module fp8_multiplier (
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] result,
    output logic [4:0] flags
);

    // FP8 E3M4 format:
    // [7]   = sign
    // [6:4] = exponent
    // [3:0] = fraction
    // exponent bias = 3

    logic       sign_a;
    logic       sign_b;
    logic [2:0] exp_a;
    logic [2:0] exp_b;
    logic [3:0] frac_a;
    logic [3:0] frac_b;

    // Special value detection
    logic a_zero;
    logic b_zero;
    logic a_inf;
    logic b_inf;
    logic a_nan;
    logic b_nan;

     // Normalized significands with implicit leading 1
    logic [4:0] mant_a;
    logic [4:0] mant_b;
    // 5-bit x 5-bit = 10-bit product
    logic [9:0] mant_product;

    logic result_sign;
    logic signed [4:0] exp_sum;
    // Normalized multiplication result
    logic [9:0] norm_mant;
    logic signed [4:0] norm_exp;

      // Rounding signals
    logic [4:0] mant_keep;
    logic       guard_bit;
    logic       sticky_bit;
    logic       round_up;
    logic [5:0] rounded_mant;

     // Final mantissa/exponent after rounding
    logic [4:0] final_mant;
    logic signed [4:0] final_exp;

    logic overflow;
    logic underflow;


    assign sign_a = a[7];
    assign exp_a  = a[6:4];
    assign frac_a = a[3:0];

    assign sign_b = b[7];
    assign exp_b  = b[6:4];
    assign frac_b = b[3:0];

        // Zero: exponent = 000 and fraction = 0000
    assign a_zero = (exp_a == 3'b000) && (frac_a == 4'b0000);
    assign b_zero = (exp_b == 3'b000) && (frac_b == 4'b0000);

    // Infinity: exponent = 111 and fraction = 0000
    assign a_inf = (exp_a == 3'b111) && (frac_a == 4'b0000);
    assign b_inf = (exp_b == 3'b111) && (frac_b == 4'b0000);

    // NaN: exponent = 111 and fraction != 0000
    assign a_nan = (exp_a == 3'b111) && (frac_a != 4'b0000);
    assign b_nan = (exp_b == 3'b111) && (frac_b != 4'b0000);

    assign mant_a = {1'b1, frac_a};
    assign mant_b = {1'b1, frac_b};

    assign mant_product = mant_a * mant_b;
    assign result_sign = sign_a ^ sign_b;
    assign exp_sum = $signed({1'b0, exp_a}) + $signed({1'b0, exp_b}) - 5'sd3;

    assign overflow  = (final_exp >= 5'sd7);
    assign underflow = (final_exp <= 5'sd0);

    // Exception flags following the provided FP32 multiplier reference:
    // [4] any NaN/Infinity input
    // [3] A is NaN
    // [2] B is NaN
    // [1] A is Infinity
    // [0] B is Infinity
    assign flags = {
        (a_nan || b_nan || a_inf || b_inf),
        a_nan,
        b_nan,
        a_inf,
        b_inf
    };

    always_comb begin
        norm_mant = mant_product;
        norm_exp  = exp_sum;

        // If product >= 2.0, shift right and increment exponent
        if (mant_product[9]) begin
            norm_mant = mant_product >> 1;
            norm_exp  = exp_sum + 5'sd1;
        end
    end

    always_comb begin
        // Keep the implicit 1 and four fraction bits
        mant_keep = norm_mant[8:4];

        // Bits discarded during rounding
        guard_bit  = norm_mant[3];
        sticky_bit = |norm_mant[2:0];

        // Round to nearest, ties to even
        round_up = guard_bit &&
                   (sticky_bit || mant_keep[0]);

        rounded_mant = {1'b0, mant_keep};

        if (round_up)
            rounded_mant = {1'b0, mant_keep} + 6'd1;
    end

    always_comb begin
        final_mant = rounded_mant[4:0];
        final_exp  = norm_exp;

        // Rounding can produce 10.0000
        if (rounded_mant[5]) begin
            final_mant = rounded_mant[5:1];
            final_exp  = norm_exp + 5'sd1;
        end
    end

    always_comb begin
        result = 8'b0;
        // NaN input, or invalid operation: 0 * infinity
        if (a_nan || b_nan ||
            ((a_zero || b_zero) && (a_inf || b_inf))) begin
            result = 8'b0111_0001;   // NaN
        end
        // Infinity multiplied by a finite non-zero value
        else if (a_inf || b_inf) begin
            result = {result_sign, 3'b111, 4'b0000};
        end
        // Multiplication by zero
        else if (a_zero || b_zero) begin
            result = {result_sign, 3'b000, 4'b0000};
        end
        // Exponent overflow -> infinity
        else if (overflow) begin
            result = {result_sign, 3'b111, 4'b0000};
        end
        // Denormals are not supported; flush underflow to zero
        else if (underflow) begin
            result = {result_sign, 3'b000, 4'b0000};
        end
        // Normal FP8 result
        else begin
            result = {
                result_sign,
                final_exp[2:0],
                final_mant[3:0]
            };
        end
    end

endmodule


// FP32
// S | EEEEEEEE | MMMMMMMMMMMMMMMMMMMMMMM
// 1      8                23
// -----------------------------------------------------------------------------------

// FP8 E3M4
// S |  EEE  |  MMMM
// 1     3       4
