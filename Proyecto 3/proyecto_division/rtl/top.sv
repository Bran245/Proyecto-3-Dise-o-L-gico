//==================================================
// archivo: top.sv
// Descripcion: Modulo top-level del sistema de division de enteros.
//
// Flujo completo:
//   Teclado fisico
//     -> sync_2ff (dentro de keypad_scanner)
//     -> debouncer
//     -> keypad_scanner
//     -> input_controller_fsm [subsistema de lectura]
//          |--- dividend (binario, DIVIDEND_WIDTH bits)
//          |--- divisor  (binario, DIVISOR_WIDTH bits)
//          `--- data_valid
//     -> divider_top [subsistema de division]
//          |--- quotient  (DIVIDEND_WIDTH bits)
//          |--- remainder (DIVISOR_WIDTH bits)
//          `--- done
//     -> display_subsystem [BCD + display]
//          |--- binary_to_bcd (cociente)
//          |--- binary_to_bcd (residuo)
//          |--- display_controller (sel boton)
//          `--- display_mux -> seg_o, an_o
//
// Parametros para seleccion de version:
//   Version base:  DIVIDEND_WIDTH=6, DIVISOR_WIDTH=4 (max 63/15)
//   Version extra: DIVIDEND_WIDTH=7, DIVISOR_WIDTH=5 (max 127/31)
//
// Proyecto: EL-3307 Diseño Logico I-2026 | EL-3307 Diseño Logico
//==================================================

module top #(
    // -----------------------------------------------
    // VERSION BASE:  DIVIDEND_WIDTH=6, DIVISOR_WIDTH=4
    // VERSION EXTRA: DIVIDEND_WIDTH=7, DIVISOR_WIDTH=5
    // -----------------------------------------------
    parameter DIVIDEND_WIDTH = 6,
    parameter DIVISOR_WIDTH  = 4,
    parameter BCD_DIGITS_Q   = 2,   // 2 para base, 3 para extra
    parameter BCD_DIGITS_R   = 2,
    parameter CLK_FREQ       = 27_000_000,
    // Seleccion de arquitectura de division:
    //   0 = iterativa (FSM)
    //   1 = pipeline
    parameter USE_PIPELINE   = 0
)(
    input  logic       clk,          // 27 MHz TangNano
    input  logic       rst_n,        // reset activo bajo
    // Teclado matricial 4x4
    input  logic [3:0] row,
    output logic [3:0] col,
    // Boton de seleccion cociente/residuo
    input  logic       sel_btn_raw,
    // Display de 7 segmentos
    output logic [6:0] seg_o,
    output logic [3:0] an_o
);

    // ------- Señales internas -------
    logic [DIVIDEND_WIDTH-1:0] dividend;
    logic [DIVISOR_WIDTH-1:0]  divisor;
    logic                      data_valid;

    logic [DIVIDEND_WIDTH-1:0] quotient;
    logic [DIVISOR_WIDTH-1:0]  remainder;
    logic                      done;

    logic sel_btn_sync;
    logic sel_btn_db;
    logic sel_btn_pulse;

    // ------- Subsistema de lectura -------
    input_subsystem #(
        .DIVIDEND_WIDTH(DIVIDEND_WIDTH),
        .DIVISOR_WIDTH (DIVISOR_WIDTH),
        .CLK_FREQ      (CLK_FREQ)
    ) u_input (
        .clk       (clk),
        .rst_n     (rst_n),
        .row       (row),
        .col       (col),
        .dividend  (dividend),
        .divisor   (divisor),
        .data_valid(data_valid)
    );

    // ------- Subsistema de division -------
    generate
        if (USE_PIPELINE == 0) begin : gen_iterative
            // Version iterativa (FSM)
            divider_top #(
                .DIVIDEND_WIDTH(DIVIDEND_WIDTH),
                .DIVISOR_WIDTH (DIVISOR_WIDTH)
            ) u_divider (
                .clk        (clk),
                .rst_n      (rst_n),
                .dividend_i (dividend),
                .divisor_i  (divisor),
                .valid_i    (data_valid),
                .quotient_o (quotient),
                .remainder_o(remainder),
                .done_o     (done)
            );
        end else begin : gen_pipeline
            // Version pipeline
            divider_pipeline #(
                .DIVIDEND_WIDTH(DIVIDEND_WIDTH),
                .DIVISOR_WIDTH (DIVISOR_WIDTH)
            ) u_divider_pipe (
                .clk        (clk),
                .rst_n      (rst_n),
                .dividend_i (dividend),
                .divisor_i  (divisor),
                .valid_i    (data_valid),
                .quotient_o (quotient),
                .remainder_o(remainder),
                .done_o     (done)
            );
        end
    endgenerate

    // ------- Sincronizacion y debounce del boton de seleccion -------
    sync_2ff #(.WIDTH(1)) u_sel_sync (
        .clk     (clk),
        .rst_n   (rst_n),
        .async_in(sel_btn_raw),
        .sync_out(sel_btn_sync)
    );

    debouncer #(
        .DEBOUNCE_COUNT(540_000)  // 20 ms @ 27 MHz
    ) u_sel_db (
        .clk      (clk),
        .rst_n    (rst_n),
        .btn_in   (sel_btn_sync),
        .btn_out  (sel_btn_db),
        .btn_pulse(sel_btn_pulse)
    );

    // ------- Subsistema de display -------
    display_subsystem #(
        .DIVIDEND_WIDTH(DIVIDEND_WIDTH),
        .DIVISOR_WIDTH (DIVISOR_WIDTH),
        .CLK_FREQ      (CLK_FREQ),
        .BCD_DIGITS_Q  (BCD_DIGITS_Q),
        .BCD_DIGITS_R  (BCD_DIGITS_R)
    ) u_display (
        .clk       (clk),
        .rst_n     (rst_n),
        .quotient_i (quotient),
        .remainder_i(remainder),
        .done_i     (done),
        .sel_btn    (sel_btn_pulse),
        .seg_o      (seg_o),
        .an_o       (an_o)
    );

endmodule
