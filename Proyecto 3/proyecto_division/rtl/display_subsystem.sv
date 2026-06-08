//==================================================
// archivo: display_subsystem.sv
// Descripcion: Integrador del subsistema de display de 7 segmentos.
// Conecta:
//   binary_to_bcd (cociente) ->
//   binary_to_bcd (residuo)  ->
//   display_controller       ->
//   display_mux              ->
//   seven_seg_decoder (instanciado dentro de display_mux)
//
// El boton 'sel_i' selecciona entre cociente y residuo.
// Un pulso en 'sel_btn' cambia el modo de visualizacion.
//
// Parametros configurables para version base y extra.
//
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

module display_subsystem #(
    parameter DIVIDEND_WIDTH = 6,
    parameter DIVISOR_WIDTH  = 4,
    parameter CLK_FREQ       = 27_000_000,
    // BCD: max(63) = 2 digitos, max(127) = 3 digitos
    parameter BCD_DIGITS_Q   = 2,
    parameter BCD_DIGITS_R   = 2
)(
    input  logic                      clk,
    input  logic                      rst_n,
    // Datos desde subsistema de division
    input  logic [DIVIDEND_WIDTH-1:0] quotient_i,
    input  logic [DIVISOR_WIDTH-1:0]  remainder_i,
    input  logic                      done_i,
    // Boton de seleccion (ya sincronizado y debounced, pulso)
    input  logic                      sel_btn,
    // Salidas fisicas
    output logic [6:0]                seg_o,
    output logic [3:0]                an_o
);

    // ------- Registro del selector (toggle) -------
    logic sel_mode;  // 0=cociente, 1=residuo

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sel_mode <= 1'b0;
        else if (sel_btn)
            sel_mode <= ~sel_mode;
    end

    // ------- Conversion BCD del cociente -------
    logic [BCD_DIGITS_Q*4-1:0] quotient_bcd;

    binary_to_bcd #(
        .INPUT_WIDTH(DIVIDEND_WIDTH),
        .BCD_DIGITS (BCD_DIGITS_Q)
    ) u_bcd_quotient (
        .bin_i(quotient_i),
        .bcd_o(quotient_bcd)
    );

    // ------- Conversion BCD del residuo -------
    logic [BCD_DIGITS_R*4-1:0] remainder_bcd;

    binary_to_bcd #(
        .INPUT_WIDTH(DIVISOR_WIDTH),
        .BCD_DIGITS (BCD_DIGITS_R)
    ) u_bcd_remainder (
        .bin_i(remainder_i),
        .bcd_o(remainder_bcd)
    );

    // ------- Controlador de display -------
    logic [3:0] digit [3:0];

    display_controller #(
        .BCD_DIGITS_Q(BCD_DIGITS_Q),
        .BCD_DIGITS_R(BCD_DIGITS_R)
    ) u_disp_ctrl (
        .clk             (clk),
        .rst_n           (rst_n),
        .sel_i           (sel_mode),
        .done_i          (done_i),
        .quotient_bcd_i  (quotient_bcd),
        .remainder_bcd_i (remainder_bcd),
        .digit           (digit)
    );

    // ------- Multiplexor de display -------
    display_mux #(
        .NUM_DIGITS (4),
        .CLK_FREQ   (CLK_FREQ),
        .REFRESH_HZ (1_000)
    ) u_disp_mux (
        .clk   (clk),
        .rst_n (rst_n),
        .digit (digit),
        .seg_o (seg_o),
        .an_o  (an_o)
    );

endmodule
