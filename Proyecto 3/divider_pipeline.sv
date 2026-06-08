//==================================================
// archivo: divider_pipeline.sv
// Descripcion: Divisor de enteros sin signo con pipeline de N etapas.
//
// Estructura: DIVIDEND_WIDTH etapas en cascada, cada una implementada
// por divider_pipeline_stage. Corta el camino critico de la version
// combinacional pura, permitiendo operar a 27 MHz.
//
// Latencia: DIVIDEND_WIDTH ciclos de reloj desde valid_i hasta done_o.
//   - Version base  (N=6): 6 ciclos
//   - Version extra (N=7): 7 ciclos
//
// Throughput: 1 resultado por ciclo una vez el pipeline esta lleno.
//
// Parametros:
//   DIVIDEND_WIDTH = 6 (base) o 7 (extra)
//   DIVISOR_WIDTH  = 4 (base) o 5 (extra)
//
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

module divider_pipeline #(
    parameter DIVIDEND_WIDTH = 6,
    parameter DIVISOR_WIDTH  = 4
)(
    input  logic                      clk,
    input  logic                      rst_n,
    input  logic [DIVIDEND_WIDTH-1:0] dividend_i,
    input  logic [DIVISOR_WIDTH-1:0]  divisor_i,
    input  logic                      valid_i,
    output logic [DIVIDEND_WIDTH-1:0] quotient_o,
    output logic [DIVISOR_WIDTH-1:0]  remainder_o,
    output logic                      done_o
);

    // ------- Arrays de señales inter-etapa -------
    // Indices: 0 = entrada de etapa 0, N = salida de etapa N-1
    logic [DIVISOR_WIDTH:0]    R_pipe  [DIVIDEND_WIDTH:0];
    logic [DIVIDEND_WIDTH-1:0] A_pipe  [DIVIDEND_WIDTH:0];
    logic [DIVISOR_WIDTH-1:0]  B_pipe  [DIVIDEND_WIDTH:0];
    logic [DIVIDEND_WIDTH-1:0] Q_pipe  [DIVIDEND_WIDTH:0];
    logic                      valid_pipe [DIVIDEND_WIDTH:0];

    // ------- Entradas a la primera etapa -------
    assign R_pipe[0]     = '0;
    assign A_pipe[0]     = dividend_i;
    assign B_pipe[0]     = divisor_i;
    assign Q_pipe[0]     = '0;
    assign valid_pipe[0] = valid_i;

    // ------- Generacion parametrica de etapas -------
    genvar i;
    generate
        for (i = 0; i < DIVIDEND_WIDTH; i++) begin : gen_stages
            divider_pipeline_stage #(
                .DIVIDEND_WIDTH(DIVIDEND_WIDTH),
                .DIVISOR_WIDTH (DIVISOR_WIDTH),
                .STAGE         (i)
            ) u_stage (
                .clk    (clk),
                .rst_n  (rst_n),
                .valid_i(valid_pipe[i]),
                .R_in   (R_pipe[i]),
                .A_in   (A_pipe[i]),
                .B_in   (B_pipe[i]),
                .Q_in   (Q_pipe[i]),
                .valid_o(valid_pipe[i+1]),
                .R_out  (R_pipe[i+1]),
                .A_out  (A_pipe[i+1]),
                .B_out  (B_pipe[i+1]),
                .Q_out  (Q_pipe[i+1])
            );
        end
    endgenerate

    // ------- Salidas de la ultima etapa -------
    assign quotient_o  = Q_pipe[DIVIDEND_WIDTH];
    assign remainder_o = R_pipe[DIVIDEND_WIDTH][DIVISOR_WIDTH-1:0];
    assign done_o      = valid_pipe[DIVIDEND_WIDTH];

endmodule
