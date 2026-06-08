//==================================================
// archivo: divider_pipeline_stage.sv
// Descripcion: Una etapa del divisor en pipeline.
//
// Cada etapa implementa UNA fila del arreglo combinacional de Fig. 2
// del documento, seguida de registros de pipeline para cortar el
// camino critico.
//
// Operacion por etapa (equivale a una iteracion del algoritmo):
//   R_out = {R_in[DIVISOR_WIDTH-2:0], A_bit}  (shift left + nuevo bit)
//   D     = R_out - B
//   si D[DIVISOR_WIDTH] == 0 (D >= 0): Q_bit=1, R' = D
//   si D[DIVISOR_WIDTH] == 1 (D < 0):  Q_bit=0, R' = R_out
//
// Los registros de pipeline almacenan:
//   - El residuo parcial R'
//   - Los bits de cociente ya calculados
//   - Los bits restantes del dividendo (A_remaining)
//   - El divisor B (se propaga sin cambio)
//
// Latencia total del pipeline: DIVIDEND_WIDTH ciclos de reloj
// Throughput: 1 resultado por ciclo (una vez lleno)
//
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

module divider_pipeline_stage #(
    parameter DIVIDEND_WIDTH = 6,
    parameter DIVISOR_WIDTH  = 4,
    parameter STAGE          = 0    // indice de etapa (0 = MSB del dividendo)
)(
    input  logic                      clk,
    input  logic                      rst_n,
    input  logic                      valid_i,
    // Residuo parcial de la etapa anterior
    input  logic [DIVISOR_WIDTH:0]    R_in,
    // Bits del dividendo aun no procesados
    // El bit a procesar en esta etapa es A_in[DIVIDEND_WIDTH-1-STAGE]
    input  logic [DIVIDEND_WIDTH-1:0] A_in,
    // Divisor (se propaga)
    input  logic [DIVISOR_WIDTH-1:0]  B_in,
    // Cociente parcial de etapas anteriores
    input  logic [DIVIDEND_WIDTH-1:0] Q_in,
    // Salidas registradas
    output logic                      valid_o,
    output logic [DIVISOR_WIDTH:0]    R_out,
    output logic [DIVIDEND_WIDTH-1:0] A_out,
    output logic [DIVISOR_WIDTH-1:0]  B_out,
    output logic [DIVIDEND_WIDTH-1:0] Q_out
);

    // ------- Logica combinacional de la etapa -------
    localparam A_BIT_IDX = DIVIDEND_WIDTH - 1 - STAGE;

    logic [DIVISOR_WIDTH:0] R_shifted;
    logic [DIVISOR_WIDTH:0] D_sub;
    logic                   q_bit;
    logic [DIVISOR_WIDTH:0] R_next;
    logic [DIVIDEND_WIDTH-1:0] Q_next;

    always_comb begin
        // Desplazamiento y entrada del bit de dividendo
        R_shifted = {R_in[DIVISOR_WIDTH-1:0], A_in[A_BIT_IDX]};
        // Resta con bit de signo
        D_sub     = R_shifted - {1'b0, B_in};
        // Seleccion de cociente y residuo
        q_bit     = ~D_sub[DIVISOR_WIDTH];  // 1 si D >= 0

        if (q_bit) begin
            R_next = D_sub;
            Q_next = Q_in | ({{(DIVIDEND_WIDTH-1){1'b0}}, 1'b1} << A_BIT_IDX);
        end else begin
            R_next = R_shifted;
            Q_next = Q_in;
        end
    end

    // ------- Registros de pipeline -------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
            R_out   <= '0;
            A_out   <= '0;
            B_out   <= '0;
            Q_out   <= '0;
        end else begin
            valid_o <= valid_i;
            R_out   <= R_next;
            A_out   <= A_in;
            B_out   <= B_in;
            Q_out   <= Q_next;
        end
    end

endmodule
