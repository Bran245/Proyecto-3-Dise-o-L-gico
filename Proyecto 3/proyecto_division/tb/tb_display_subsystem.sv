//==================================================
// archivo: tb_display_subsystem.sv
// Descripcion: Testbench para display_subsystem.
// Verifica que los digitos BCD correctos llegan al display_mux
// tanto para cociente como para residuo, y que el boton sel_btn
// alterna entre ambos modos.
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

`timescale 1ns/1ps

module tb_display_subsystem;

    localparam DIVIDEND_WIDTH = 6;
    localparam DIVISOR_WIDTH  = 4;
    localparam CLK_PERIOD     = 37;
    // Reducir divisores para simulacion rapida
    localparam CLK_FREQ_SIM   = 27_000_000;

    logic                      clk, rst_n;
    logic [DIVIDEND_WIDTH-1:0] quotient_i;
    logic [DIVISOR_WIDTH-1:0]  remainder_i;
    logic                      done_i;
    logic                      sel_btn;
    logic [6:0]                seg_o;
    logic [3:0]                an_o;

    display_subsystem #(
        .DIVIDEND_WIDTH(DIVIDEND_WIDTH),
        .DIVISOR_WIDTH (DIVISOR_WIDTH),
        .CLK_FREQ      (CLK_FREQ_SIM),
        .BCD_DIGITS_Q  (2),
        .BCD_DIGITS_R  (2)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .quotient_i (quotient_i),
        .remainder_i(remainder_i),
        .done_i     (done_i),
        .sel_btn    (sel_btn),
        .seg_o      (seg_o),
        .an_o       (an_o)
    );

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Monitoreo de an_o para verificar refresco
    always @(an_o)
        $display("T=%0t | an_o=%b seg_o=%b", $time, an_o, seg_o);

    initial begin
        $dumpfile("tb_display_subsystem.vcd");
        $dumpvars(0, tb_display_subsystem);

        rst_n       = 0;
        quotient_i  = 0;
        remainder_i = 0;
        done_i      = 0;
        sel_btn     = 0;
        repeat(4) @(posedge clk);
        rst_n = 1;

        // Cargar resultado 63/15 = 4 residuo 3
        quotient_i  = 6'd4;
        remainder_i = 4'd3;
        done_i      = 1;
        @(posedge clk);

        // Dejar correr algunos ciclos de refresco
        $display("--- Mostrando COCIENTE (Q=4) ---");
        repeat(200) @(posedge clk);

        // Presionar boton de seleccion
        sel_btn = 1;
        @(posedge clk);
        sel_btn = 0;

        $display("--- Mostrando RESIDUO (R=3) ---");
        repeat(200) @(posedge clk);

        // Caso 45/7 = 6 r3
        quotient_i  = 6'd6;
        remainder_i = 4'd3;
        repeat(100) @(posedge clk);

        // Volver a cociente
        sel_btn = 1;
        @(posedge clk);
        sel_btn = 0;
        repeat(100) @(posedge clk);

        $display("=== Testbench display_subsystem completado ===");
        $finish;
    end

endmodule
