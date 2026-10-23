`timescale 1ns/1ps

module fp8_adder (
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

    // Extended mantissas for alignment and rounding
    logic [7:0] mant_a_ext;
    logic [7:0] mant_b_ext;
    logic [7:0] mant_a_aligned;
    logic [7:0] mant_b_aligned;
    logic [2:0] exp_diff;
    logic [2:0] aligned_exp;

    // Mantissa addition/subtraction
    logic [8:0] mant_result;
    logic       result_sign;
    logic [2:0] result_exp;

    logic [8:0] norm_mant;
    logic signed [4:0] norm_exp;

    // Rounding signals
    logic [4:0] mant_keep;
    logic       guard_bit;
    logic       sticky_bit;
    logic       round_up;
    logic [5:0] rounded_mant;

    // Final result after rounding
    logic [4:0] final_mant;
    logic signed [4:0] final_exp;

    logic overflow;
    logic underflow;
    logic align_sticky;

    // Decode operands
    assign sign_a = a[7];
    assign exp_a  = a[6:4];
    assign frac_a = a[3:0];
    assign sign_b = b[7];
    assign exp_b  = b[6:4];
    assign frac_b = b[3:0];

    // Zero
    assign a_zero = (exp_a == 3'b000) &&
                    (frac_a == 4'b0000);
    assign b_zero = (exp_b == 3'b000) &&
                    (frac_b == 4'b0000);
    // Infinity
    assign a_inf = (exp_a == 3'b111) &&
                   (frac_a == 4'b0000);
    assign b_inf = (exp_b == 3'b111) &&
                   (frac_b == 4'b0000);
    // NaN
    assign a_nan = (exp_a == 3'b111) &&
                   (frac_a != 4'b0000);
    assign b_nan = (exp_b == 3'b111) &&
                   (frac_b != 4'b0000);

    assign mant_a_ext = {1'b1, frac_a, 3'b000};
    assign mant_b_ext = {1'b1, frac_b, 3'b000};

    assign overflow  = (final_exp >= 5'sd7);
    assign underflow = (final_exp <= 5'sd0);
    assign flags = {
        (a_nan || b_nan || a_inf || b_inf),
        a_nan,
        b_nan,
        a_inf,
        b_inf
    };

    always_comb begin
        mant_a_aligned = mant_a_ext;
        mant_b_aligned = mant_b_ext;
        aligned_exp    = exp_a;
        exp_diff       = 3'b000;
        align_sticky   = 1'b0;

        if (exp_a > exp_b) begin
            exp_diff       = exp_a - exp_b;
            aligned_exp    = exp_a;
            mant_b_aligned = mant_b_ext >> exp_diff;

            case (exp_diff)
                3'd1: align_sticky = 1'b0;
                3'd2: align_sticky = |mant_b_ext[0];
                3'd3: align_sticky = |mant_b_ext[1:0];
                3'd4: align_sticky = |mant_b_ext[2:0];
                3'd5: align_sticky = |mant_b_ext[3:0];
                3'd6: align_sticky = |mant_b_ext[4:0];
                3'd7: align_sticky = |mant_b_ext[5:0];
                default: align_sticky = 1'b0;
            endcase

            mant_b_aligned[0] = mant_b_aligned[0] | align_sticky;
        end

        else if (exp_b > exp_a) begin
            exp_diff       = exp_b - exp_a;
            aligned_exp    = exp_b;
            mant_a_aligned = mant_a_ext >> exp_diff;

            case (exp_diff)
                3'd1: align_sticky = 1'b0;
                3'd2: align_sticky = |mant_a_ext[0];
                3'd3: align_sticky = |mant_a_ext[1:0];
                3'd4: align_sticky = |mant_a_ext[2:0];
                3'd5: align_sticky = |mant_a_ext[3:0];
                3'd6: align_sticky = |mant_a_ext[4:0];
                3'd7: align_sticky = |mant_a_ext[5:0];
                default: align_sticky = 1'b0;
            endcase

            mant_a_aligned[0] = mant_a_aligned[0] | align_sticky;
        end
    end
    

    always_comb begin
        mant_result = 9'b0;
        result_sign = 1'b0;
        result_exp  = aligned_exp;

        // Same signs -> add mantissas
        if (sign_a == sign_b) begin
            mant_result = {1'b0, mant_a_aligned}
                        + {1'b0, mant_b_aligned};

            result_sign = sign_a;
        end

        // Different signs -> subtract smaller magnitude
        else begin
            if (mant_a_aligned > mant_b_aligned) begin
                mant_result = {1'b0, mant_a_aligned}
                            - {1'b0, mant_b_aligned};

                result_sign = sign_a;
            end
            else if (mant_b_aligned > mant_a_aligned) begin
                mant_result = {1'b0, mant_b_aligned}
                            - {1'b0, mant_a_aligned};

                result_sign = sign_b;
            end
            else begin
                // Equal magnitude with opposite signs -> zero
                mant_result = 9'b0;
                result_sign = 1'b0;
            end
        end
    end

    integer i;

    always_comb begin
        norm_mant = mant_result;
        norm_exp  = $signed({1'b0, result_exp});

        // Case 1:
        // Addition produced a carry.
        // Shift right once and increase exponent.
        if (mant_result[8]) begin
            norm_mant = mant_result >> 1;
            norm_exp  = $signed({1'b0, result_exp}) + 5'sd1;
        end

        // Case 2:
        // Subtraction may require left normalization.
        else if (mant_result != 9'b0) begin

            // The normalized implicit 1 should be at bit [7].
            // Shift left until bit [7] becomes 1.
            for (i = 0; i < 7; i = i + 1) begin
                if ((norm_mant[7] == 1'b0) &&
                    (norm_exp > 5'sd0)) begin

                    norm_mant = norm_mant << 1;
                    norm_exp  = norm_exp - 5'sd1;
                end
            end
        end
    end

    always_comb begin
        // Keep implicit 1 + four fraction bits
        mant_keep = norm_mant[7:3];

        // Round-to-nearest, ties-to-even
        guard_bit  = norm_mant[2];
        sticky_bit = |norm_mant[1:0];

        round_up = guard_bit &&
                   (sticky_bit || mant_keep[0]);

        rounded_mant = {1'b0, mant_keep};

        if (round_up)
            rounded_mant = {1'b0, mant_keep} + 6'd1;
    end

    always_comb begin
        final_mant = rounded_mant[4:0];
        final_exp  = norm_exp;

        // Rounding overflow: 1.1111 -> 10.0000
        if (rounded_mant[5]) begin
            final_mant = rounded_mant[5:1];
            final_exp  = norm_exp + 5'sd1;
        end
    end

    always_comb begin
        result = 8'b0;
        // NaN input
        if (a_nan || b_nan) begin
            result = 8'b0_111_0001;
        end
        // +Inf + -Inf or -Inf + +Inf -> NaN
        else if (a_inf && b_inf && (sign_a != sign_b)) begin
            result = 8'b0_111_0001;
        end
        // A is infinity
        else if (a_inf) begin
            result = {sign_a, 3'b111, 4'b0000};
        end
        // B is infinity
        else if (b_inf) begin
            result = {sign_b, 3'b111, 4'b0000};
        end
        // A is zero -> return B
        else if (a_zero) begin
            result = b;
        end
        // B is zero -> return A
        else if (b_zero) begin
            result = a;
        end
        // Exact cancellation, e.g. 1.5 + (-1.5)
        else if (mant_result == 9'b0) begin
            result = 8'b0_000_0000;
        end
        // Overflow -> infinity
        else if (overflow) begin
            result = {result_sign, 3'b111, 4'b0000};
        end
        // Underflow -> zero
        else if (underflow) begin
            result = {result_sign, 3'b000, 4'b0000};
        end
        // Normal result
        else begin
            result = {
                result_sign,
                final_exp[2:0],
                final_mant[3:0]
            };
        end
    end

endmodule
