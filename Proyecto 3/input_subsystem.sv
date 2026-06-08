//==================================================
// archivo: input_subsystem.sv
// Descripcion: Integra los modulos del subsistema de lectura:
//   sync_2ff -> debouncer -> keypad_scanner -> input_controller_fsm
// Expone dividend, divisor y data_valid al subsistema de division.
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

module input_subsystem #(
    parameter DIVIDEND_WIDTH  = 6,
    parameter DIVISOR_WIDTH   = 4,
    parameter CLK_FREQ        = 27_000_000
)(
    input  logic                      clk,
    input  logic                      rst_n,
    // Teclado fisico
    input  logic [3:0]                row,
    output logic [3:0]                col,
    // Datos hacia subsistema de division
    output logic [DIVIDEND_WIDTH-1:0] dividend,
    output logic [DIVISOR_WIDTH-1:0]  divisor,
    output logic                      data_valid
);

    // Señales internas
    logic [3:0] key_value;
    logic       key_valid_raw;
    logic       key_valid_db;    // key_valid despues de debounce
    logic       key_pulse;

    // Instancia del keypad_scanner
    keypad_scanner #(
        .CLK_FREQ (CLK_FREQ),
        .SCAN_FREQ(1_000)
    ) u_scanner (
        .clk      (clk),
        .rst_n    (rst_n),
        .row      (row),
        .col      (col),
        .key_value(key_value),
        .key_valid(key_valid_raw)
    );

    // Debounce sobre la señal key_valid del scanner
    debouncer #(
        .DEBOUNCE_COUNT(27_000)  // 1 ms @ 27 MHz, suficiente para teclado
    ) u_debounce (
        .clk      (clk),
        .rst_n    (rst_n),
        .btn_in   (key_valid_raw),
        .btn_out  (key_valid_db),
        .btn_pulse(key_pulse)
    );

    // FSM de control de entrada
    input_controller_fsm #(
        .DIVIDEND_WIDTH(DIVIDEND_WIDTH),
        .DIVISOR_WIDTH (DIVISOR_WIDTH)
    ) u_fsm (
        .clk       (clk),
        .rst_n     (rst_n),
        .key_value (key_value),
        .key_valid (key_pulse),   // solo pulsos confirmados
        .dividend  (dividend),
        .divisor   (divisor),
        .data_valid(data_valid)
    );

endmodule
