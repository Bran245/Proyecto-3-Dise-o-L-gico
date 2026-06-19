// ============================================================
//  top.sv  —  EL-3307 Proyecto corto III: División de enteros
// ============================================================

module top (
    input  logic       clk,
    input  logic       rst_n,

    output logic [3:0] rows,
    input  logic [3:0] cols,

    output logic [5:0] led,
    output logic [3:0] anodos,
    output logic [6:0] segmentos
);

    localparam A_BITS = 7;
    localparam B_BITS = 5;
    localparam A_MAX  = 127;
    localparam B_MAX  = 31;

    // ----------------------------------------------------------
    //  Teclado
    // ----------------------------------------------------------
    logic [15:0] key_pressed;
    logic        key_event;

    keypad_4x4 #(
        .CLK_FREQ(27_000_000),
        .SCAN_HZ (500)
    ) u_keypad (
        .clk        (clk),
        .rst_n      (rst_n),
        .rows       (rows),
        .cols       (cols),
        .key_pressed(key_pressed),
        .key_event  (key_event)
    );

    // Decodificación de teclas
    logic [3:0] digit_val;
    logic       is_digit;
    logic       is_clear;    // *
    logic       is_confirm;  // #

    always_comb begin
        digit_val  = 4'd0;
        is_digit   = 1'b0;
        is_clear   = 1'b0;
        is_confirm = 1'b0;
        case (key_pressed)
            16'h0001: begin digit_val = 4'd1; is_digit = 1'b1; end
            16'h0002: begin digit_val = 4'd4; is_digit = 1'b1; end
            16'h0004: begin digit_val = 4'd7; is_digit = 1'b1; end
            16'h0010: begin digit_val = 4'd2; is_digit = 1'b1; end
            16'h0020: begin digit_val = 4'd5; is_digit = 1'b1; end
            16'h0040: begin digit_val = 4'd8; is_digit = 1'b1; end
            16'h0100: begin digit_val = 4'd3; is_digit = 1'b1; end
            16'h0200: begin digit_val = 4'd6; is_digit = 1'b1; end
            16'h0400: begin digit_val = 4'd9; is_digit = 1'b1; end
            16'h0800: is_clear   = 1'b1;
            16'h2000: begin digit_val = 4'd0; is_digit = 1'b1; end
            16'h4000: is_confirm = 1'b1;
            default: ;
        endcase
    end

    // ----------------------------------------------------------
    //  FSM principal
    // ----------------------------------------------------------
    typedef enum logic [1:0] {
        STATE_NUM_A  = 2'b00,
        STATE_NUM_B  = 2'b01,
        STATE_RESULT = 2'b10
    } state_t;

    state_t     state,      state_next;
    logic [7:0] num_a,      num_a_next;
    logic [7:0] num_b,      num_b_next;
    logic [1:0] dcnt_a,     dcnt_a_next;
    logic [1:0] dcnt_b,     dcnt_b_next;
    logic       calcular,   calcular_next;
    logic       show_rem,   show_rem_next;
    logic       err_flag,   err_flag_next;

    // Cálculo combinacional de nuevo valor
    logic [9:0] new_a;
    logic [7:0] new_b;
    assign new_a = num_a * 10'd10 + {6'd0, digit_val};
    assign new_b = num_b * 8'd10 + {4'd0, digit_val};

    always_comb begin
        // Defaults
        state_next    = state;
        num_a_next    = num_a;
        num_b_next    = num_b;
        dcnt_a_next   = dcnt_a;
        dcnt_b_next   = dcnt_b;
        calcular_next = 1'b0;
        show_rem_next = show_rem;
        err_flag_next = err_flag;

        if (key_event) begin
            case (state)

                // ---- Ingreso de A ----
                STATE_NUM_A: begin
                    if (is_clear) begin
                        num_a_next  = '0;
                        dcnt_a_next = '0;
                        err_flag_next = 1'b0;
                    end else if (is_digit) begin
                        if (dcnt_a == 0 && digit_val == 0) begin
                            // ignorar ceros a la izquierda
                        end else if (dcnt_a < 2'd3) begin
                            if (new_a > 10'd127) begin
                                err_flag_next = 1'b1;
                            end else begin
                                err_flag_next = 1'b0;
                                num_a_next    = new_a;
                                dcnt_a_next   = dcnt_a + 1;
                            end
                        end
                    end else if (is_confirm) begin
                        if (dcnt_a == 0) begin
                            err_flag_next = 1'b1;
                        end else if (!err_flag) begin
                            state_next    = STATE_NUM_B;
                            num_b_next    = '0;
                            dcnt_b_next   = '0;
                            err_flag_next = 1'b0;
                        end
                    end
                end

                // ---- Ingreso de B ----
                STATE_NUM_B: begin
                    if (is_clear) begin
                        state_next    = STATE_NUM_A;
                        num_a_next    = '0;
                        dcnt_a_next   = '0;
                        err_flag_next = 1'b0;
                    end else if (is_digit) begin
                        if (dcnt_b == 0 && digit_val == 0) begin
                            err_flag_next = 1'b1;
                        end else if (dcnt_b < 2'd2) begin
                            if (new_b > B_MAX || new_b == 0) begin
                                err_flag_next = 1'b1;
                            end else begin
                                err_flag_next = 1'b0;
                                num_b_next    = new_b;
                                dcnt_b_next   = dcnt_b + 1;
                            end
                        end
                    end else if (is_confirm) begin
                        if (dcnt_b == 0 || num_b == 0) begin
                            err_flag_next = 1'b1;
                        end else if (!err_flag) begin
                            calcular_next = 1'b1;
                            show_rem_next = 1'b0;
                        end
                    end
                end

                // ---- Resultado ----
                STATE_RESULT: begin
                    if (is_clear || is_digit) begin
                        state_next    = STATE_NUM_A;
                        num_a_next    = '0;
                        num_b_next    = '0;
                        dcnt_a_next   = '0;
                        dcnt_b_next   = '0;
                        err_flag_next = 1'b0;
                        if (is_digit) begin
                            num_a_next  = {4'd0, digit_val};
                            dcnt_a_next = 2'd1;
                        end
                    end else if (is_confirm) begin
                        show_rem_next = ~show_rem;
                    end
                end

                default: state_next = STATE_NUM_A;
            endcase
        end

        // Transición automática cuando el divisor termina
        if (state == STATE_NUM_B && done) begin
            state_next = STATE_RESULT;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= STATE_NUM_A;
            num_a    <= '0;
            num_b    <= '0;
            dcnt_a   <= '0;
            dcnt_b   <= '0;
            calcular <= 1'b0;
            show_rem <= 1'b0;
            err_flag <= 1'b0;
        end else begin
            state    <= state_next;
            num_a    <= num_a_next;
            num_b    <= num_b_next;
            dcnt_a   <= dcnt_a_next;
            dcnt_b   <= dcnt_b_next;
            calcular <= calcular_next;
            show_rem <= show_rem_next;
            err_flag <= err_flag_next;
        end
    end

    // ----------------------------------------------------------
    //  Pipeline divisor
    // ----------------------------------------------------------
    logic [A_BITS-1:0] quotient;
    logic [B_BITS-1:0] remainder;
    logic              done;

    div_pipeline #(
        .A_BITS(A_BITS),
        .B_BITS(B_BITS)
    ) u_divider (
        .clk  (clk),
        .rst  (~rst_n),
        .valid(calcular),
        .A    (num_a[A_BITS-1:0]),
        .B    (num_b[B_BITS-1:0]),
        .done (done),
        .Q    (quotient),
        .R    (remainder)
    );

    logic [A_BITS-1:0] Q_latch;
    logic [B_BITS-1:0] R_latch;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Q_latch <= '0;
            R_latch <= '0;
        end else if (done) begin
            Q_latch <= quotient;
            R_latch <= remainder;
        end
    end

    // ----------------------------------------------------------
    //  Conversión BCD
    // ----------------------------------------------------------
    logic [11:0] bcd_a;
    logic [7:0]  bcd_b;
    logic [11:0] bcd_q;
    logic [7:0]  bcd_r;

    binary_to_bcd #(.INPUT_WIDTH(A_BITS), .BCD_DIGITS(3)) conv_a (
        .bin_i(num_a[A_BITS-1:0]), .bcd_o(bcd_a)
    );
    binary_to_bcd #(.INPUT_WIDTH(B_BITS), .BCD_DIGITS(2)) conv_b (
        .bin_i(num_b[B_BITS-1:0]), .bcd_o(bcd_b)
    );
    binary_to_bcd #(.INPUT_WIDTH(A_BITS), .BCD_DIGITS(3)) conv_q (
        .bin_i(Q_latch), .bcd_o(bcd_q)
    );
    binary_to_bcd #(.INPUT_WIDTH(B_BITS), .BCD_DIGITS(2)) conv_r (
        .bin_i(R_latch[B_BITS-1:0]), .bcd_o(bcd_r)
    );

    // ----------------------------------------------------------
    //  Lógica de display
    // ----------------------------------------------------------
    logic [3:0] dig3, dig2, dig1, dig0;

    always_comb begin
        dig3 = 4'd0; dig2 = 4'd0; dig1 = 4'd0; dig0 = 4'd0;

        case (state)
            STATE_NUM_A: begin
                if (err_flag) begin
                    {dig3, dig2, dig1, dig0} = 16'hEEEE;
                end else begin
                    dig3 = bcd_a[11:8];
                    dig2 = bcd_a[7:4];
                    dig1 = bcd_a[3:0];
                    dig0 = 4'd0;
                end
            end
            STATE_NUM_B: begin
                if (err_flag) begin
                    {dig3, dig2, dig1, dig0} = 16'hEEEE;
                end else begin
                    dig3 = bcd_b[7:4];
                    dig2 = bcd_b[3:0];
                    dig1 = 4'd0;
                    dig0 = 4'd0;
                end
            end
            STATE_RESULT: begin
                if (!show_rem) begin
                    dig3 = bcd_q[11:8];
                    dig2 = bcd_q[7:4];
                    dig1 = bcd_q[3:0];
                    dig0 = 4'd0;
                end else begin
                    dig3 = bcd_r[7:4];
                    dig2 = bcd_r[3:0];
                    dig1 = 4'd0;
                    dig0 = 4'd0;
                end
            end
            default: ;
        endcase
    end

    // Registro de dígitos para evitar glitches en el display
    logic [3:0] dig3_r, dig2_r, dig1_r, dig0_r;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dig3_r <= 4'd0; dig2_r <= 4'd0;
            dig1_r <= 4'd0; dig0_r <= 4'd0;
        end else begin
            dig3_r <= dig3; dig2_r <= dig2;
            dig1_r <= dig1; dig0_r <= dig0;
        end
    end

    display_7seg #(
        .REFRESH_COUNT(20000)
    ) u_display (
        .clk      (clk),
        .rst_n    (rst_n),
        .enable   (1'b1),
        .dig3     (dig3_r),
        .dig2     (dig2_r),
        .dig1     (dig1_r),
        .dig0     (dig0_r),
        .anodos   (anodos),
        .segmentos(segmentos)
    );

    // ----------------------------------------------------------
    //  LEDs
    // ----------------------------------------------------------
    assign led[0] = ~key_event;
    assign led[1] = ~(state == STATE_NUM_A);
    assign led[2] = ~(state == STATE_NUM_B);
    assign led[3] = ~(state == STATE_RESULT);
    assign led[4] = ~show_rem;
    assign led[5] = ~done;

endmodule