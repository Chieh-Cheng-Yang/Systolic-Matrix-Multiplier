`timescale 1ns/1ps

module fp8_adder_tb;

    logic [7:0] a;
    logic [7:0] b;

    logic [7:0] result;
    logic [4:0] flags;

    // Device Under Test
    fp8_adder dut (
        .a(a),
        .b(b),
        .result(result),
        .flags(flags)
    );


    // -------------------------------------------------
    // Test task
    // -------------------------------------------------
    task automatic run_test(
        input logic [7:0] test_a,
        input logic [7:0] test_b,
        input logic [7:0] expected,
        input string test_name
    );
    begin

        a = test_a;
        b = test_b;

        // Allow combinational logic to settle
        #10;

        if (result === expected)
            $display(
                "PASS: %s | A=%b B=%b Result=%b Flags=%b",
                test_name, a, b, result, flags
            );
        else
            $display(
                "FAIL: %s | A=%b B=%b Result=%b Expected=%b Flags=%b",
                test_name, a, b, result, expected, flags
            );

    end
    endtask

    initial begin
        $fsdbDumpfile("adder.fsdb");
        $fsdbDumpvars(0, fp8_adder_tb);
    end


    initial begin

        // -------------------------------------------------
        // Test 1: Different exponents / alignment
        //
        // 1.5 + 0.5 = 2.0
        //
        // 1.5 = 0_011_1000
        // 0.5 = 0_010_0000
        // 2.0 = 0_100_0000
        // -------------------------------------------------
        run_test(
            8'b0_011_1000,
            8'b0_010_0000,
            8'b0_100_0000,
            "1.5 + 0.5 = 2.0"
        );


        // -------------------------------------------------
        // Test 2: Same exponent + normalization
        //
        // 1.5 + 1.5 = 3.0
        //
        // 3.0 = 0_100_1000
        // -------------------------------------------------
        run_test(
            8'b0_011_1000,
            8'b0_011_1000,
            8'b0_100_1000,
            "1.5 + 1.5 = 3.0"
        );


        // -------------------------------------------------
        // Test 3: Different signs / subtraction
        //
        // 1.5 + (-0.5) = 1.0
        //
        // 1.0 = 0_011_0000
        // -------------------------------------------------
        run_test(
            8'b0_011_1000,
            8'b1_010_0000,
            8'b0_011_0000,
            "1.5 + (-0.5) = 1.0"
        );


        // -------------------------------------------------
        // Test 4: Negative result
        //
        // 0.5 + (-1.5) = -1.0
        //
        // -1.0 = 1_011_0000
        // -------------------------------------------------
        run_test(
            8'b0_010_0000,
            8'b1_011_1000,
            8'b1_011_0000,
            "0.5 + (-1.5) = -1.0"
        );


        // -------------------------------------------------
        // Test 5: Exact cancellation
        //
        // 1.5 + (-1.5) = 0
        // -------------------------------------------------
        run_test(
            8'b0_011_1000,
            8'b1_011_1000,
            8'b0_000_0000,
            "1.5 + (-1.5) = 0"
        );


        // -------------------------------------------------
        // Test 6: Addition with zero
        //
        // 0 + 1.5 = 1.5
        // -------------------------------------------------
        run_test(
            8'b0_000_0000,
            8'b0_011_1000,
            8'b0_011_1000,
            "0 + 1.5 = 1.5"
        );


        // -------------------------------------------------
        // Test 7: Infinity
        //
        // +Infinity + 1.5 = +Infinity
        //
        // +Infinity = 0_111_0000
        // -------------------------------------------------
        run_test(
            8'b0_111_0000,
            8'b0_011_1000,
            8'b0_111_0000,
            "+Infinity + 1.5 = +Infinity"
        );


        // -------------------------------------------------
        // Test 8: Invalid infinity operation
        //
        // +Infinity + (-Infinity) = NaN
        //
        // Canonical NaN = 0_111_0001
        // -------------------------------------------------
        run_test(
            8'b0_111_0000,
            8'b1_111_0000,
            8'b0_111_0001,
            "+Infinity + (-Infinity) = NaN"
        );


        // -------------------------------------------------
        // Test 9: Overflow
        //
        // 15.5 + 15.5 = 31.0
        // 31.0 is outside finite E3M4 range
        // Expected result = +Infinity
        //
        // 15.5 = 0_110_1111
        // -------------------------------------------------
        run_test(
            8'b0_110_1111,
            8'b0_110_1111,
            8'b0_111_0000,
            "15.5 + 15.5 = Overflow"
        );


        // -------------------------------------------------
        // Test 10: Rounding
        //
        // 1.0 + 0.28125 = 1.28125
        //
        // 1.0     = 0_011_0000
        // 0.28125 = 0_001_0010
        //
        // 1.28125 is exactly halfway between:
        // 1.25   = 1.0100
        // 1.3125 = 1.0101
        //
        // Round-to-nearest, ties-to-even -> 1.25
        //
        // 1.25 = 0_011_0100
        // -------------------------------------------------
        run_test(
            8'b0_011_0000,
            8'b0_001_0010,
            8'b0_011_0100,
            "Rounding tie: 1.0 + 0.28125 -> 1.25"
        );


        $display("-----------------------------------");
        $display("FP8 adder testing completed.");
        $display("-----------------------------------");

        #10;
        $finish;

    end

endmodule
