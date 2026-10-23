`timescale 1ns/1ns

module matmul_tb;

    // SystemVerilog logic signals
    logic clk;
    logic resetn;
    logic pe_resetn;
    logic start;
    logic done;
    logic [4:0] flags;

    // ============================================================
    // DUT
    // ============================================================
    matrix_multiplication u_matmul(
        .clk(clk), 
        .resetn(resetn), 
        .pe_resetn(pe_resetn), 
        .address_mat_a(10'b0),
        .address_mat_b(10'b0),
        .address_mat_c(10'b0),
        .address_stride_a(8'd1),
        .address_stride_b(8'd1),
        .address_stride_c(8'd1),
        .start(start),
        .done(done),
        .flags(flags)
    );
    
    // ============================================================
    // Clock Generation
    // ============================================================
    initial begin
        clk = 0;

        forever begin
            #10 clk = ~clk;
        end
    end
    
    
    // ============================================================
    // Test Sequence
    // ============================================================
    initial begin

        start = 0;
        resetn = 0;
        pe_resetn = 0;

        // Reset
        #55;
        resetn = 1;
        pe_resetn = 1;

        #60;


        // ========================================================
        // Test Case 1: Normal FP8 Matrix Multiplication
        // ========================================================
        start = 1;

        @(posedge done);
        start = 0;

        // Wait for final RAM writes
        #100;

        $display("----------------------------------------");
        $display("Checking FP8 Matrix Multiplication...");
        $display("----------------------------------------");

        if ((u_matmul.matrix_C.ram[0] === 32'h20384030) &&
            (u_matmul.matrix_C.ram[1] === 32'h38203040) &&
            (u_matmul.matrix_C.ram[2] === 32'h40302038) &&
            (u_matmul.matrix_C.ram[3] === 32'h30403820) &&
            (flags === 5'b00000))
        begin
            $display("PASS: FP8 Matrix Test Case 1");
            $display("RAM[0] = %h", u_matmul.matrix_C.ram[0]);
            $display("RAM[1] = %h", u_matmul.matrix_C.ram[1]);
            $display("RAM[2] = %h", u_matmul.matrix_C.ram[2]);
            $display("RAM[3] = %h", u_matmul.matrix_C.ram[3]);
            $display("Flags  = %b", flags);
        end
        else begin
            $display("FAIL: FP8 Matrix Test Case 1");

            $display(
                "RAM[0] = %h Expected = 20384030",
                u_matmul.matrix_C.ram[0]
            );

            $display(
                "RAM[1] = %h Expected = 38203040",
                u_matmul.matrix_C.ram[1]
            );

            $display(
                "RAM[2] = %h Expected = 40302038",
                u_matmul.matrix_C.ram[2]
            );

            $display(
                "RAM[3] = %h Expected = 30403820",
                u_matmul.matrix_C.ram[3]
            );

            $display(
                "Flags = %b Expected = 00000",
                flags
            );
        end

        $display("----------------------------------------");


        // ========================================================
        // Test Case 2: Exception Propagation
        // A = Identity Matrix
        // B contains +Infinity
        // ========================================================

        $display("");
        $display("----------------------------------------");
        $display("Starting FP8 Matrix Test Case 2...");
        $display("----------------------------------------");

        // Reset PE accumulators
        pe_resetn = 0;
        #40;
        pe_resetn = 1;

        // Clear output RAM
        u_matmul.matrix_C.ram[0] = 32'b0;
        u_matmul.matrix_C.ram[1] = 32'b0;
        u_matmul.matrix_C.ram[2] = 32'b0;
        u_matmul.matrix_C.ram[3] = 32'b0;


        // Matrix A = Identity
        u_matmul.matrix_A.ram[0] =
            {8'h00, 8'h00, 8'h00, 8'h30};

        u_matmul.matrix_A.ram[1] =
            {8'h00, 8'h00, 8'h30, 8'h00};

        u_matmul.matrix_A.ram[2] =
            {8'h00, 8'h30, 8'h00, 8'h00};

        u_matmul.matrix_A.ram[3] =
            {8'h30, 8'h00, 8'h00, 8'h00};


        // Matrix B is the same as Test Case 1,
        // except B[0][0] = +Infinity (8'h70)
        u_matmul.matrix_B.ram[0] =
            {8'h20, 8'h38, 8'h40, 8'h70};

        u_matmul.matrix_B.ram[1] =
            {8'h38, 8'h20, 8'h30, 8'h40};

        u_matmul.matrix_B.ram[2] =
            {8'h40, 8'h30, 8'h20, 8'h38};

        u_matmul.matrix_B.ram[3] =
            {8'h30, 8'h40, 8'h38, 8'h20};


        // Start second matrix multiplication
        #40;
        start = 1;

        @(posedge done);
        start = 0;

        // Wait for final RAM writes
        #100;

        $display("Checking FP8 Matrix Test Case 2...");

        if (flags != 5'b00000)
        begin
            $display(
                "PASS: FP8 Matrix Test Case 2 - Exception detected"
            );

            $display(
                "RAM[0] = %h",
                u_matmul.matrix_C.ram[0]
            );

            $display(
                "RAM[1] = %h",
                u_matmul.matrix_C.ram[1]
            );

            $display(
                "RAM[2] = %h",
                u_matmul.matrix_C.ram[2]
            );

            $display(
                "RAM[3] = %h",
                u_matmul.matrix_C.ram[3]
            );

            $display(
                "Flags  = %b",
                flags
            );
        end
        else begin
            $display("FAIL: FP8 Matrix Test Case 2");
            $display("Expected exception flags != 00000");
            $display("Actual Flags = %b", flags);
        end

        $display("----------------------------------------");
        $display("Part 2 functional testing completed.");
        $display("----------------------------------------");

        $finish;
    end


    // ============================================================
    // Initial Matrix Data for Test Case 1
    // ============================================================
    initial begin

        // Matrix A = Identity Matrix
        //
        // FP8 1.0 = 8'h30
        //
        // A is stored in row-major format.

        u_matmul.matrix_A.ram[0] =
            {8'h00, 8'h00, 8'h00, 8'h30};

        u_matmul.matrix_A.ram[1] =
            {8'h00, 8'h00, 8'h30, 8'h00};

        u_matmul.matrix_A.ram[2] =
            {8'h00, 8'h30, 8'h00, 8'h00};

        u_matmul.matrix_A.ram[3] =
            {8'h30, 8'h00, 8'h00, 8'h00};


        // Matrix B
        //
        // B is stored in column-major format.

        u_matmul.matrix_B.ram[0] =
            {8'h20, 8'h38, 8'h40, 8'h30};

        u_matmul.matrix_B.ram[1] =
            {8'h38, 8'h20, 8'h30, 8'h40};

        u_matmul.matrix_B.ram[2] =
            {8'h40, 8'h30, 8'h20, 8'h38};

        u_matmul.matrix_B.ram[3] =
            {8'h30, 8'h40, 8'h38, 8'h20};

    end


    // ============================================================
    // FSDB Waveform Dump
    // ============================================================
    initial begin
        $fsdbDumpfile("novas.fsdb");
        $fsdbDumpvars(0, matmul_tb);
    end

endmodule
