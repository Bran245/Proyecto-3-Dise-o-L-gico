//==================================================
// archivo: tb_divider_datapath.sv
// Descripcion: Testbench para divider_datapath.
// Prueba manual del datapath aplicando señales de control directamente.
// Casos de prueba: 63/15, 45/7, 10/3, 0/5
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

`timescale 1ns/1ps

module tb_divider_datapath;

    // Parametros
    localparam DIVIDEND_WIDTH = 6;
    localparam DIVISOR_WIDTH  = 4;
    localparam CLK_PERIOD     = 37;  // ~27 MHz

    // DUT signals
    logic                      clk;
    logic                      rst_n;
    logic [DIVIDEND_WIDTH-1:0] dividend_i;
    logic [DIVISOR_WIDTH-1:0]  divisor_i;
    logic                      load;
    logic                      shift;
    logic                      iter_done;
    logic [DIVIDEND_WIDTH-1:0] quotient;
    logic [DIVISOR_WIDTH-1:0]  remainder;

    // DUT
    divider_datapath #(
        .DIVIDEND_WIDTH(DIVIDEND_WIDTH),
        .DIVISOR_WIDTH (DIVISOR_WIDTH)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .dividend_i (dividend_i),
        .divisor_i  (divisor_i),
        .load       (load),
        .shift      (shift),
        .iter_done  (iter_done),
        .quotient   (quotient),
        .remainder  (remainder)
    );

    // Clock
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Tarea de division
    task automatic do_divide(
        input logic [DIVIDEND_WIDTH-1:0] a,
        input logic [DIVISOR_WIDTH-1:0]  b,
        input logic [DIVIDEND_WIDTH-1:0] expected_q,
        input logic [DIVISOR_WIDTH-1:0]  expected_r
    );
        integer i;
        $display("--- Dividiendo %0d / %0d ---", a, b);
        dividend_i = a;
        divisor_i  = b;
        load       = 1;
        @(posedge clk); #1;
        load = 0;
        shift = 1;
        // Iterar DIVIDEND_WIDTH veces
        repeat (DIVIDEND_WIDTH) begin
            @(posedge clk); #1;
        end
        shift = 0;
        @(posedge clk); #1;
        $display("    Cociente  = %0d (esperado %0d) %s",
            quotient, expected_q,
            (quotient == expected_q) ? "PASS" : "FAIL");
        $display("    Residuo   = %0d (esperado %0d) %s",
            remainder, expected_r,
            (remainder == expected_r) ? "PASS" : "FAIL");
    endtask

    initial begin
        rst_n      = 0;
        dividend_i = 0;
        divisor_i  = 0;
        load       = 0;
        shift      = 0;
        repeat(4) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // Casos de prueba
        do_divide(6'd63, 4'd15, 6'd4,  4'd3);   // 63/15 = 4 residuo 3
        do_divide(6'd45, 4'd7,  6'd6,  4'd3);   // 45/7  = 6 residuo 3
        do_divide(6'd10, 4'd3,  6'd3,  4'd1);   // 10/3  = 3 residuo 1
        do_divide(6'd0,  4'd5,  6'd0,  4'd0);   // 0/5   = 0 residuo 0

        $display("=== Simulacion completada ===");
        $finish;
    end

    // Monitoreo
    initial begin
        $dumpfile("tb_divider_datapath.vcd");
        $dumpvars(0, tb_divider_datapath);
    end

endmodule
