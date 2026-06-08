//==================================================
// archivo: debouncer.sv
// Descripcion: Elimina rebotes mecanicos de botones/teclado.
// Cuando la señal sincronica se mantiene estable por DEBOUNCE_COUNT
// ciclos consecutivos, se acepta el nuevo valor.
// A 27 MHz, 20 ms de debounce => 540000 ciclos.
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

module debouncer #(
    parameter DEBOUNCE_COUNT = 540000  // 20 ms @ 27 MHz
)(
    input  logic clk,
    input  logic rst_n,
    input  logic btn_in,     // señal ya sincronizada (2FF)
    output logic btn_out,    // salida estable
    output logic btn_pulse   // pulso de un ciclo en flanco ascendente
);

    logic [$clog2(DEBOUNCE_COUNT)-1:0] cnt;
    logic btn_stable;
    logic btn_prev;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt        <= '0;
            btn_stable <= 1'b0;
            btn_out    <= 1'b0;
            btn_prev   <= 1'b0;
        end else begin
            btn_prev <= btn_out;

            if (btn_in == btn_stable) begin
                cnt <= '0;
            end else begin
                if (cnt == DEBOUNCE_COUNT - 1) begin
                    btn_stable <= btn_in;
                    cnt        <= '0;
                end else begin
                    cnt <= cnt + 1;
                end
            end

            btn_out <= btn_stable;
        end
    end

    // Pulso de un ciclo en flanco ascendente de btn_out
    assign btn_pulse = btn_out & ~btn_prev;

endmodule
