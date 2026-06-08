//==================================================
// archivo: divider_top.sv
// Descripcion: Integrador del subsistema de calculo de division entera.
// Conecta divider_datapath <-> divider_controller_fsm.
//
// Parametros configurables para version base y version extra:
//   Version base:  DIVIDEND_WIDTH=6, DIVISOR_WIDTH=4  (max 63/15)
//   Version extra: DIVIDEND_WIDTH=7, DIVISOR_WIDTH=5  (max 127/31)
//
// Protocolo de bus:
//   Entrada: valid_i (desde subsistema de lectura)
//   Salida:  done_o  (hacia subsistema de display)
//
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

module divider_top #(
    parameter DIVIDEND_WIDTH = 6,
    parameter DIVISOR_WIDTH  = 4
)(
    input  logic                      clk,
    input  logic                      rst_n,
    // Interfaz de entrada
    input  logic [DIVIDEND_WIDTH-1:0] dividend_i,
    input  logic [DIVISOR_WIDTH-1:0]  divisor_i,
    input  logic                      valid_i,
    // Resultados
    output logic [DIVIDEND_WIDTH-1:0] quotient_o,
    output logic [DIVISOR_WIDTH-1:0]  remainder_o,
    output logic                      done_o
);

    // ------- Señales internas de control -------
    logic load;
    logic shift;
    logic iter_done;

    // ------- Instancia del datapath -------
    divider_datapath #(
        .DIVIDEND_WIDTH(DIVIDEND_WIDTH),
        .DIVISOR_WIDTH (DIVISOR_WIDTH)
    ) u_datapath (
        .clk        (clk),
        .rst_n      (rst_n),
        .dividend_i (dividend_i),
        .divisor_i  (divisor_i),
        .load       (load),
        .shift      (shift),
        .iter_done  (iter_done),
        .quotient   (quotient_o),
        .remainder  (remainder_o)
    );

    // ------- Instancia de la FSM de control -------
    divider_controller_fsm u_fsm (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_i   (valid_i),
        .iter_done (iter_done),
        .load      (load),
        .shift     (shift),
        .done_o    (done_o)
    );

endmodule
