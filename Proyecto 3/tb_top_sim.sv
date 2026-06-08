//==================================================
// archivo: tb_top_sim.sv
// Descripcion: Testbench sencillo que instancia `top` (interfaz real)
// y un `divider_top` independiente para verificar casos de prueba
// de division. No modifica ningun archivo fuente existente.
//==================================================
`timescale 1ns/1ps

module tb_top_sim;

    // Parametros acordes a las versiones base del proyecto
    localparam int DIVIDEND_WIDTH = 6;
    localparam int DIVISOR_WIDTH  = 4;
    localparam int TIMEOUT_CYCLES = 10000;
    real HALF_PERIOD = 18.518; // ns -> ~27 MHz (period ~= 37.037 ns)

    // Señales del top real
    logic clk;
    logic rst_n; // activo bajo, como en `top`
    logic [3:0] row;
    logic [3:0] col;
    logic sel_btn_raw;
    logic [6:0] seg_o;
    logic [3:0] an_o;

    // Señales para instanciar divider_top y controlar la prueba
    logic [DIVIDEND_WIDTH-1:0] dividend_tb;
    logic [DIVISOR_WIDTH-1:0]  divisor_tb;
    logic                      valid_tb;
    logic [DIVIDEND_WIDTH-1:0] quotient_tb;
    logic [DIVISOR_WIDTH-1:0]  remainder_tb;
    logic                      done_tb;

    // Instancio el `top` tal y como está en el proyecto (puertos exactos)
    top u_top (
        .clk       (clk),
        .rst_n     (rst_n),
        .row       (row),
        .col       (col),
        .sel_btn_raw(sel_btn_raw),
        .seg_o     (seg_o),
        .an_o      (an_o)
    );

    // Instancio el `divider_top` directamente para poder inyectar
    // dividend/divisor/valid y observar quotient/remainder/done.
    divider_top #(
        .DIVIDEND_WIDTH(DIVIDEND_WIDTH),
        .DIVISOR_WIDTH (DIVISOR_WIDTH)
    ) u_divider (
        .clk        (clk),
        .rst_n      (rst_n),
        .dividend_i (dividend_tb),
        .divisor_i  (divisor_tb),
        .valid_i    (valid_tb),
        .quotient_o (quotient_tb),
        .remainder_o(remainder_tb),
        .done_o     (done_tb)
    );

    // Generador de reloj ~27 MHz
    initial clk = 0;
    always #HALF_PERIOD clk = ~clk;

    // Casos de prueba requeridos
    logic [DIVIDEND_WIDTH-1:0] test_a [0:4];
    logic [DIVISOR_WIDTH-1:0]  test_b [0:4];

    initial begin
        // Inicialización señales
        rst_n       = 0;
        valid_tb    = 0;
        dividend_tb = '0;
        divisor_tb  = '0;
        sel_btn_raw = 0;
        row         = 4'b0000;

        // Dump VCD opcional
        $dumpfile("tb_top_sim.vcd");
        $dumpvars(0, tb_top_sim);

        // Defino casos (A / B)
        test_a[0] = 6'd10;  test_b[0] = 4'd3;   // Q=3 R=1
        test_a[1] = 6'd63;  test_b[1] = 4'd15;  // Q=4 R=3
        test_a[2] = 6'd20;  test_b[2] = 4'd4;   // Q=5 R=0
        test_a[3] = 6'd7;   test_b[3] = 4'd2;   // Q=3 R=1
        test_a[4] = 6'd0;   test_b[4] = 4'd5;   // Q=0 R=0

        // Aplicar reset activo (rst_n activo bajo)
        repeat(4) @(posedge clk);
        rst_n = 1'b0; // mantener en reset
        repeat(6) @(posedge clk);
        rst_n = 1'b1; // liberar reset
        @(posedge clk);

        // Small pause
        repeat(2) @(posedge clk);

        // Ejecutar cada caso
        for (int i = 0; i < 5; i++) begin
            // Preparar operando y señalar valid
            dividend_tb = test_a[i];
            divisor_tb  = test_b[i];

            // Pulse de `valid` por 1 ciclo de reloj
            @(posedge clk);
            valid_tb = 1'b1;
            @(posedge clk);
            valid_tb = 1'b0;

            // Esperar `done` con watchdog
            int cycles = 0;
            while (!done_tb && cycles < TIMEOUT_CYCLES) begin
                @(posedge clk);
                cycles++;
            end

            if (!done_tb) begin
                $display("[TEST] A=%0d B=%0d → TIMEOUT después de %0d ciclos | FAIL",
                         test_a[i], test_b[i], cycles);
            end else begin
                // Sample outputs (ya disponibles en señales)
                logic [DIVIDEND_WIDTH-1:0] q_sample;
                logic [DIVISOR_WIDTH-1:0]  r_sample;
                q_sample = quotient_tb;
                r_sample = remainder_tb;

                // Calcular esperado usando expresiones de Verilog
                logic [DIVIDEND_WIDTH-1:0] q_exp;
                logic [DIVISOR_WIDTH-1:0]  r_exp;
                q_exp = test_a[i] / test_b[i];
                r_exp = test_a[i] % test_b[i];

                if (q_sample == q_exp && r_sample == r_exp)
                    $display("[TEST] A=%0d B=%0d → Q=%0d R=%0d | PASS",
                             test_a[i], test_b[i], q_sample, r_sample);
                else
                    $display("[TEST] A=%0d B=%0d → Q=%0d R=%0d | FAIL (exp Q=%0d R=%0d)",
                             test_a[i], test_b[i], q_sample, r_sample, q_exp, r_exp);
            end

            // Pequeña separación entre casos
            repeat(4) @(posedge clk);
        end

        $display("Todas las pruebas completadas. Fin de simulación.");
        #100 $finish;
    end

endmodule
