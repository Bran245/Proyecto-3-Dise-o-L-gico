//==================================================
// archivo: tb_top.sv
// Descripcion: Testbench del sistema completo.
// Dado que el teclado fisico es dificil de simular, este testbench
// estimula directamente los modulos internos via una version de top
// con un puerto adicional de bypass para inyectar operandos.
//
// Estrategia: se instancia directamente input_controller_fsm con
// estimulos de tecla sinteticos, y se verifica la salida del display.
//
// Casos de prueba:
//   63 / 15 => Q=4  R=3
//   45 /  7 => Q=6  R=3
//   10 /  3 => Q=3  R=1
//    0 /  5 => Q=0  R=0
// Version extra:
//  127 / 31 => Q=4  R=3
//
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

`timescale 1ns/1ps

module tb_top;

    localparam DIVIDEND_WIDTH = 7;  // version extra
    localparam DIVISOR_WIDTH  = 5;
    localparam CLK_PERIOD     = 37;

    logic                      clk, rst_n;
    logic [DIVIDEND_WIDTH-1:0] dividend_tb;
    logic [DIVISOR_WIDTH-1:0]  divisor_tb;
    logic                      valid_tb;
    logic                      sel_btn;
    logic [6:0]                seg_o;
    logic [3:0]                an_o;

    // ------- Instanciar divisor directamente para prueba de integracion -------
    logic [DIVIDEND_WIDTH-1:0] quotient_out;
    logic [DIVISOR_WIDTH-1:0]  remainder_out;
    logic                      done_out;

    divider_top #(
        .DIVIDEND_WIDTH(DIVIDEND_WIDTH),
        .DIVISOR_WIDTH (DIVISOR_WIDTH)
    ) u_divider (
        .clk        (clk),
        .rst_n      (rst_n),
        .dividend_i (dividend_tb),
        .divisor_i  (divisor_tb),
        .valid_i    (valid_tb),
        .quotient_o (quotient_out),
        .remainder_o(remainder_out),
        .done_o     (done_out)
    );

    display_subsystem #(
        .DIVIDEND_WIDTH(DIVIDEND_WIDTH),
        .DIVISOR_WIDTH (DIVISOR_WIDTH),
        .CLK_FREQ      (27_000_000),
        .BCD_DIGITS_Q  (3),
        .BCD_DIGITS_R  (2)
    ) u_display (
        .clk        (clk),
        .rst_n      (rst_n),
        .quotient_i (quotient_out),
        .remainder_i(remainder_out),
        .done_i     (done_out),
        .sel_btn    (sel_btn),
        .seg_o      (seg_o),
        .an_o       (an_o)
    );

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Tarea de prueba completa
    task automatic full_test(
        input logic [DIVIDEND_WIDTH-1:0] a,
        input logic [DIVISOR_WIDTH-1:0]  b,
        input logic [DIVIDEND_WIDTH-1:0] exp_q,
        input logic [DIVISOR_WIDTH-1:0]  exp_r
    );
        integer timeout;
        $display("--- Full test: %0d / %0d ---", a, b);
        dividend_tb = a;
        divisor_tb  = b;
        valid_tb    = 1;
        timeout     = 0;
        while (!done_out && timeout < 500) begin
            @(posedge clk); #1;
            timeout++;
        end
        if (timeout >= 500)
            $error("TIMEOUT esperando done_o");
        if (quotient_out == exp_q && remainder_out == exp_r)
            $display("    PASS: Q=%0d R=%0d | seg=%b an=%b",
                quotient_out, remainder_out, seg_o, an_o);
        else
            $error("    FAIL: Q=%0d (exp=%0d) R=%0d (exp=%0d)",
                quotient_out, exp_q, remainder_out, exp_r);
        valid_tb = 0;
        repeat(5) @(posedge clk);
    endtask

    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);

        rst_n       = 0;
        valid_tb    = 0;
        dividend_tb = 0;
        divisor_tb  = 0;
        sel_btn     = 0;
        repeat(4) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        $display("=== Casos version base ===");
        full_test(7'd63,  5'd15, 7'd4, 5'd3);
        full_test(7'd45,  5'd7,  7'd6, 5'd3);
        full_test(7'd10,  5'd3,  7'd3, 5'd1);
        full_test(7'd0,   5'd5,  7'd0, 5'd0);

        $display("=== Casos version extra ===");
        full_test(7'd127, 5'd31, 7'd4,  5'd3);
        full_test(7'd100, 5'd17, 7'd5,  5'd15);

        $display("=== Testbench top completado ===");
        $finish;
    end

endmodule
