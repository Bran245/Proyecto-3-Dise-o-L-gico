//==================================================
// archivo: keypad_scanner.sv
// Descripcion: Escanea un teclado matricial 4x4 hexadecimal.
// Genera señales de fila (col_drive) y lee columnas (row_sense).
// Produce el valor de la tecla presionada y un pulso key_valid.
// Divisor de frecuencia incluido para escaneo lento (~1 kHz).
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

module keypad_scanner #(
    parameter CLK_FREQ   = 27_000_000,  // 27 MHz TangNano
    parameter SCAN_FREQ  = 1_000        // 1 kHz escaneo
)(
    input  logic       clk,
    input  logic       rst_n,
    input  logic [3:0] row,         // filas del teclado (entrada, activo bajo)
    output logic [3:0] col,         // columnas de escaneo (salida, activo bajo)
    output logic [3:0] key_value,   // valor de la tecla [0..F]
    output logic       key_valid    // pulso: tecla detectada
);

    // --- Divisor de frecuencia para escaneo ---
    localparam SCAN_DIV = CLK_FREQ / SCAN_FREQ / 4;  // /4 columnas
    logic [$clog2(SCAN_DIV)-1:0] scan_cnt;
    logic scan_tick;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_cnt  <= '0;
            scan_tick <= 1'b0;
        end else begin
            if (scan_cnt == SCAN_DIV - 1) begin
                scan_cnt  <= '0;
                scan_tick <= 1'b1;
            end else begin
                scan_cnt  <= scan_cnt + 1;
                scan_tick <= 1'b0;
            end
        end
    end

    // --- Columna activa (escaneo round-robin) ---
    logic [1:0] col_sel;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            col_sel <= 2'd0;
        else if (scan_tick)
            col_sel <= col_sel + 1;
    end

    // Decodificador one-hot para columna activa (activo bajo)
    always_comb begin
        case (col_sel)
            2'd0: col = 4'b1110;
            2'd1: col = 4'b1101;
            2'd2: col = 4'b1011;
            2'd3: col = 4'b0111;
            default: col = 4'b1111;
        endcase
    end

    // --- Lectura de fila y decodificacion de tecla ---
    // Layout teclado hex 4x4:
    //       col0 col1 col2 col3
    // row0:  1    2    3    A
    // row1:  4    5    6    B
    // row2:  7    8    9    C
    // row3:  *    0    #    D
    // (Mapeamos * -> E (borrar), # -> F (enter/confirmar))

    logic [3:0] key_raw;
    logic       key_detected;
    logic [3:0] row_sync;

    // Sincronizar filas
    sync_2ff #(.WIDTH(4)) u_row_sync (
        .clk(clk), .rst_n(rst_n),
        .async_in(row),
        .sync_out(row_sync)
    );

    always_comb begin
        key_raw      = 4'hF;
        key_detected = 1'b0;

        if (scan_tick) begin
            case ({col_sel, ~row_sync})
                // col_sel=0, col=4'b1110
                {2'd0, 4'b0001}: begin key_raw = 4'h1; key_detected = 1'b1; end
                {2'd0, 4'b0010}: begin key_raw = 4'h4; key_detected = 1'b1; end
                {2'd0, 4'b0100}: begin key_raw = 4'h7; key_detected = 1'b1; end
                {2'd0, 4'b1000}: begin key_raw = 4'hE; key_detected = 1'b1; end // '*' = borrar
                // col_sel=1, col=4'b1101
                {2'd1, 4'b0001}: begin key_raw = 4'h2; key_detected = 1'b1; end
                {2'd1, 4'b0010}: begin key_raw = 4'h5; key_detected = 1'b1; end
                {2'd1, 4'b0100}: begin key_raw = 4'h8; key_detected = 1'b1; end
                {2'd1, 4'b1000}: begin key_raw = 4'h0; key_detected = 1'b1; end
                // col_sel=2, col=4'b1011
                {2'd2, 4'b0001}: begin key_raw = 4'h3; key_detected = 1'b1; end
                {2'd2, 4'b0010}: begin key_raw = 4'h6; key_detected = 1'b1; end
                {2'd2, 4'b0100}: begin key_raw = 4'h9; key_detected = 1'b1; end
                {2'd2, 4'b1000}: begin key_raw = 4'hF; key_detected = 1'b1; end // '#' = enter
                // col_sel=3, col=4'b0111
                {2'd3, 4'b0001}: begin key_raw = 4'hA; key_detected = 1'b1; end
                {2'd3, 4'b0010}: begin key_raw = 4'hB; key_detected = 1'b1; end
                {2'd3, 4'b0100}: begin key_raw = 4'hC; key_detected = 1'b1; end
                {2'd3, 4'b1000}: begin key_raw = 4'hD; key_detected = 1'b1; end
                default: begin key_raw = 4'h0; key_detected = 1'b0; end
            endcase
        end
    end

    // Registrar salida
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_value <= 4'h0;
            key_valid <= 1'b0;
        end else begin
            key_value <= key_raw;
            key_valid <= key_detected;
        end
    end

endmodule
