// ============================================================
//  keypad_4x4.sv
//  Escáner de teclado 4×4 con anti-rebote y sincronización.
//  key_event = pulso de 1 ciclo en la primera detección
//  de una tecla (borde de reposo→presionada).
// ============================================================
module keypad_4x4 #(
    parameter CLK_FREQ = 27_000_000,
    parameter SCAN_HZ  = 500
)(
    input  logic        clk,
    input  logic        rst_n,
    output logic [3:0]  rows,
    input  logic [3:0]  cols,
    output logic [15:0] key_pressed,
    output logic        key_event
);
    localparam integer SCAN_DIV = CLK_FREQ / SCAN_HZ;

    logic [$clog2(SCAN_DIV)-1:0] scan_counter;
    logic [1:0]  scan_row;
    logic [3:0]  cols_sync1, cols_sync2;
    logic [15:0] key_raw, key_sample, key_stable, key_prev;
    logic [2:0]  stable_count;

    // Sincronización de columnas
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cols_sync1 <= 4'b1111;
            cols_sync2 <= 4'b1111;
        end else begin
            cols_sync1 <= cols;
            cols_sync2 <= cols_sync1;
        end
    end

    // Contador de escaneo
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_counter <= '0;
            scan_row     <= '0;
        end else begin
            if (scan_counter == SCAN_DIV - 1) begin
                scan_counter <= '0;
                scan_row     <= scan_row + 1;
            end else begin
                scan_counter <= scan_counter + 1;
            end
        end
    end

    always_comb begin
        case (scan_row)
            2'd0: rows = 4'b1110;
            2'd1: rows = 4'b1101;
            2'd2: rows = 4'b1011;
            2'd3: rows = 4'b0111;
            default: rows = 4'b1111;
        endcase
    end

    // Captura de teclas crudas
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_raw <= 16'h0000;
        end else begin
            if (scan_counter == SCAN_DIV - 1) begin
                case (scan_row)
                    2'd0: key_raw[ 3: 0] <= ~cols_sync2;
                    2'd1: key_raw[ 7: 4] <= ~cols_sync2;
                    2'd2: key_raw[11: 8] <= ~cols_sync2;
                    2'd3: key_raw[15:12] <= ~cols_sync2;
                endcase
            end
        end
    end

    // Anti-rebote
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_sample   <= 16'h0000;
            key_stable   <= 16'h0000;
            stable_count <= '0;
        end else begin
            if (scan_counter == SCAN_DIV - 1) begin
                if (key_raw == key_sample) begin
                    if (stable_count < 3'd5)
                        stable_count <= stable_count + 1;
                    else
                        key_stable <= key_sample;
                end else begin
                    key_sample   <= key_raw;
                    stable_count <= '0;
                end
            end
        end
    end

    // Detección de borde
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_pressed <= 16'h0000;
            key_prev    <= 16'h0000;
            key_event   <= 1'b0;
        end else begin
            key_pressed <= key_stable;
            key_prev    <= key_pressed;
            key_event   <= (key_pressed != 16'h0000) && (key_prev == 16'h0000);
        end
    end

endmodule
