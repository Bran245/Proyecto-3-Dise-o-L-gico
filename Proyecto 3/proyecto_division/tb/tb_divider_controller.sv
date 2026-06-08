//==================================================
// archivo: tb_divider_controller.sv
// Descripcion: Testbench para divider_controller_fsm.
// Verifica las transiciones de estado y señales de control:
//   IDLE -> LOAD -> ITERATE -> DONE
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

`timescale 1ns/1ps

module tb_divider_controller;

    localparam CLK_PERIOD = 37;

    logic clk, rst_n;
    logic valid_i, iter_done;
    logic load, shift, done_o;

    divider_controller_fsm dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .valid_i  (valid_i),
        .iter_done(iter_done),
        .load     (load),
        .shift    (shift),
        .done_o   (done_o)
    );

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Monitor de estado
    always @(posedge clk) begin
        $display("T=%0t | valid=%b iter_done=%b | load=%b shift=%b done=%b",
            $time, valid_i, iter_done, load, shift, done_o);
    end

    initial begin
        $dumpfile("tb_divider_controller.vcd");
        $dumpvars(0, tb_divider_controller);

        rst_n     = 0;
        valid_i   = 0;
        iter_done = 0;
        repeat(3) @(posedge clk);
        rst_n = 1;

        // Verificar estado IDLE
        @(posedge clk); #1;
        assert(load == 0 && shift == 0 && done_o == 0)
            else $error("Error: en IDLE deben estar inactivas");

        // Activar valid_i -> transicion a LOAD
        valid_i = 1;
        @(posedge clk); #1;
        assert(load == 1) else $error("Error: LOAD no activo");

        // Siguiente ciclo: ITERATE (shift debe activarse)
        @(posedge clk); #1;
        assert(shift == 1) else $error("Error: shift no activo en ITERATE");

        // Simular 5 ciclos de iteracion
        repeat(5) @(posedge clk);

        // Activar iter_done -> transicion a DONE
        iter_done = 1;
        @(posedge clk); #1;
        assert(done_o == 1) else $error("Error: done_o no activo en DONE");

        // Desactivar valid_i -> volver a IDLE
        valid_i   = 0;
        iter_done = 0;
        @(posedge clk); #1;
        assert(done_o == 0) else $error("Error: done_o debe estar inactivo en IDLE");

        $display("=== Testbench FSM completado ===");
        $finish;
    end

endmodule
