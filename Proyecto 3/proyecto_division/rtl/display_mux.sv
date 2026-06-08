//==================================================
// archivo: display_mux.sv
// Descripcion: Multiplexor temporal para N displays de 7 segmentos.
// Activa un display a la vez con frecuencia de refresco suficiente
// para eliminar el parpadeo visible (> 60 Hz por display).
//
// A 27 MHz con 4 displays: refresco por display = 27MHz/(DIV*4)
//   DIV = 5400 => 27e6/5400/4 = 1250 Hz por display (sin parpadeo).
//
// Salidas:
//   seg_o   : segmentos del display activo (activo bajo)
//   an_o    : anodos de los displays (activo bajo, one-hot-inverted)
//
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

module display_mux #(
    parameter NUM_DIGITS = 4,           // numero de displays
    parameter CLK_FREQ   = 27_000_000,
    parameter REFRESH_HZ = 1_000       // frecuencia de refresco por digito
)(
    input  logic                    clk,
    input  logic                    rst_n,
    // Digitos BCD para cada display (digit[0] = menos significativo)
    input  logic [3:0]              digit [NUM_DIGITS-1:0],
    // Salidas fisicas
    output logic [6:0]              seg_o,
    output logic [NUM_DIGITS-1:0]   an_o    // activo bajo
);

    localparam REFRESH_DIV = CLK_FREQ / REFRESH_HZ / NUM_DIGITS;

    // ------- Divisor de frecuencia -------
    logic [$clog2(REFRESH_DIV)-1:0] refresh_cnt;
    logic refresh_tick;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            refresh_cnt  <= '0;
            refresh_tick <= 1'b0;
        end else begin
            if (refresh_cnt == REFRESH_DIV - 1) begin
                refresh_cnt  <= '0;
                refresh_tick <= 1'b1;
            end else begin
                refresh_cnt  <= refresh_cnt + 1;
                refresh_tick <= 1'b0;
            end
        end
    end

    // ------- Selector de display activo -------
    logic [$clog2(NUM_DIGITS)-1:0] dig_sel;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dig_sel <= '0;
        else if (refresh_tick)
            dig_sel <= (dig_sel == NUM_DIGITS - 1) ? '0 : dig_sel + 1;
    end

    // ------- Decodificador de anodo (activo bajo) -------
    always_comb begin
        an_o = '1;  // todos apagados por defecto
        an_o[dig_sel] = 1'b0;  // solo el activo encendido
    end

    // ------- Decodificador de segmento -------
    logic [3:0] active_digit;
    assign active_digit = digit[dig_sel];

    seven_seg_decoder u_seg_dec (
        .bcd_i(active_digit),
        .seg_o(seg_o)
    );

endmodule
