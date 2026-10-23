`timescale 1ns/1ps

module fp8_multiplier_tb;

    logic [7:0] a;
    logic [7:0] b;

    logic [7:0] result;
    logic [4:0] flags;

    // Device Under Test
    fp8_multiplier dut (
        .a(a),
        .b(b),
        .result(result),
        .flags(flags)
    );

    // Test task
    task automatic run_test(
        input logic [7:0] test_a,
        input logic [7:0] test_b,
        input logic [7:0] expected,
        input string test_name
    );
    begin
        a = test_a;
        b = test_b;

        #10;

        if (result === expected)
            $display("PASS: %s | A=%b B=%b Result=%b",
                     test_name, a, b, result);
        else
            $display("FAIL: %s | A=%b B=%b Result=%b Expected=%b",
                     test_name, a, b, result, expected);
    end
    endtask

    initial begin
        $fsdbDumpfile("multiplier.fsdb");
        $fsdbDumpvars(0, fp8_multiplier_tb);
    end

    initial begin

        // -------------------------------------------------
        // Test 1: Normal multiplication
        // 1.5 * 2.0 = 3.0
        // 1.5 = 0_011_1000
        // 2.0 = 0_100_0000
        // 3.0 = 0_100_1000
        // -------------------------------------------------
        run_test(
            8'b0_011_1000,
            8'b0_100_0000,
            8'b0_100_1000,
            "1.5 * 2.0 = 3.0"
        );


        // -------------------------------------------------
        // Test 2: Normalization required
        // 1.5 * 1.5 = 2.25
        // 2.25 = 1.001 x 2^1
        // FP8 = 0_100_0010
        // -------------------------------------------------
        run_test(
            8'b0_011_1000,
            8'b0_011_1000,
            8'b0_100_0010,
            "1.5 * 1.5 = 2.25"
        );


        // -------------------------------------------------
        // Test 3: Negative result
        // -1.5 * 2.0 = -3.0
        // -------------------------------------------------
        run_test(
            8'b1_011_1000,
            8'b0_100_0000,
            8'b1_100_1000,
            "-1.5 * 2.0 = -3.0"
        );


        // -------------------------------------------------
        // Test 4: Multiply by zero
        // 0 * 2.0 = 0
        // -------------------------------------------------
        run_test(
            8'b0_000_0000,
            8'b0_100_0000,
            8'b0_000_0000,
            "0 * 2.0 = 0"
        );


        // -------------------------------------------------
        // Test 5: Infinity
        // Infinity * 2.0 = Infinity
        // -------------------------------------------------
        run_test(
            8'b0_111_0000,
            8'b0_100_0000,
            8'b0_111_0000,
            "Infinity * 2.0 = Infinity"
        );


        // -------------------------------------------------
        // Test 6: Invalid operation
        // 0 * Infinity = NaN
        // Our multiplier returns canonical NaN 0_111_0001
        // -------------------------------------------------
        run_test(
            8'b0_000_0000,
            8'b0_111_0000,
            8'b0_111_0001,
            "0 * Infinity = NaN"
        );


        // -------------------------------------------------
        // Test 7: Overflow
        // 15.5 * 2.0 -> Infinity
        //
        // 15.5 = 1.1111 * 2^3
        //      = 0_110_1111
        // -------------------------------------------------
        run_test(
            8'b0_110_1111,
            8'b0_100_0000,
            8'b0_111_0000,
            "15.5 * 2.0 = Overflow"
        );

        // -------------------------------------------------
        // Test 8: Underflow
        // 0.25 * 0.25 = 0.0625
        // Denormals are not supported, so flush to zero
        // -------------------------------------------------
        // -------------------------------------------------
        // Test 9: Rounding
        // 1.0625 * 1.0625 = 1.12890625
        // Rounded to nearest FP8 value = 1.125
        // -------------------------------------------------

        
        run_test(
            8'b0_011_0001,
            8'b0_011_0001,
            8'b0_011_0010,
            "Rounding: 1.0625 * 1.0625 -> 1.125"
        );
        run_test(
            8'b0_001_0000,
            8'b0_001_0000,
            8'b0_000_0000,
            "0.25 * 0.25 = Underflow"
        );


        $display("-----------------------------------");
        $display("FP8 multiplier testing completed.");
        $display("-----------------------------------");

        #10;
        $finish;

    end

endmodule
