//==================================================
// archivo: tb_divider_top.sv
// Descripcion: Testbench integrado para divider_top (datapath + FSM).
// Prueba el sistema completo de division usando el protocolo de bus:
//   valid_i -> esperar done_o -> leer resultados
// Casos: 63/15, 45/7, 10/3, 0/5
// Tambien prueba la version extra: 127/31
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

`timescale 1ns/1ps

module tb_divider_top;

    localparam DIVIDEND_WIDTH = 7;  // version extra habilitada
    localparam DIVISOR_WIDTH  = 5;
    localparam CLK_PERIOD     = 37;
    localparam TIMEOUT        = 1000;

    logic                      clk, rst_n;
    logic [DIVIDEND_WIDTH-1:0] dividend_i;
    logic [DIVISOR_WIDTH-1:0]  divisor_i;
    logic                      valid_i;
    logic [DIVIDEND_WIDTH-1:0] quotient_o;
    logic [DIVISOR_WIDTH-1:0]  remainder_o;
    logic                      done_o;

    divider_top #(
        .DIVIDEND_WIDTH(DIVIDEND_WIDTH),
        .DIVISOR_WIDTH (DIVISOR_WIDTH)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .dividend_i (dividend_i),
        .divisor_i  (divisor_i),
        .valid_i    (valid_i),
        .quotient_o (quotient_o),
        .remainder_o(remainder_o),
        .done_o     (done_o)
    );

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Tarea de prueba con verificacion automatica
    task automatic test_division(
        input logic [DIVIDEND_WIDTH-1:0] a,
        input logic [DIVISOR_WIDTH-1:0]  b,
        input logic [DIVIDEND_WIDTH-1:0] exp_q,
        input logic [DIVISOR_WIDTH-1:0]  exp_r
    );
        integer timeout_cnt;
        $display("--- Test: %0d / %0d ---", a, b);
        dividend_i  = a;
        divisor_i   = b;
        valid_i     = 1;
        timeout_cnt = 0;

        // Esperar done_o
        while (!done_o && timeout_cnt < TIMEOUT) begin
            @(posedge clk); #1;
            timeout_cnt++;
        end

        if (timeout_cnt >= TIMEOUT)
            $error("TIMEOUT: done_o no se activo");

        // Verificar resultados
        if (quotient_o == exp_q && remainder_o == exp_r)
            $display("    PASS: Q=%0d R=%0d", quotient_o, remainder_o);
        else
            $error("    FAIL: Q=%0d (exp %0d) R=%0d (exp %0d)",
                quotient_o, exp_q, remainder_o, exp_r);

        // Bajar valid_i para volver a IDLE
        valid_i = 0;
        repeat(3) @(posedge clk);
    endtask

    initial begin
        $dumpfile("tb_divider_top.vcd");
        $dumpvars(0, tb_divider_top);

        rst_n      = 0;
        valid_i    = 0;
        dividend_i = 0;
        divisor_i  = 0;
        repeat(4) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // --- Version base (6 bits / 4 bits) ---
        $display("=== Casos version base (max 63/15) ===");
        test_division(7'd63,  5'd15, 7'd4,  5'd3);
        test_division(7'd45,  5'd7,  7'd6,  5'd3);
        test_division(7'd10,  5'd3,  7'd3,  5'd1);
        test_division(7'd0,   5'd5,  7'd0,  5'd0);

        // --- Version extra (7 bits / 5 bits) ---
        $display("=== Casos version extra (max 127/31) ===");
        test_division(7'd127, 5'd31, 7'd4,  5'd3);   // 127/31=4 r3
        test_division(7'd100, 5'd17, 7'd5,  5'd15);  // 100/17=5 r15
        test_division(7'd99,  5'd31, 7'd3,  5'd6);   // 99/31=3 r6

        $display("=== Testbench divider_top completado ===");
        $finish;
    end

endmodule
