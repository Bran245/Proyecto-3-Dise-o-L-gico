//==================================================
// archivo: input_controller_fsm.sv
// Descripcion: FSM de control del subsistema de lectura.
// Captura secuencialmente:
//   1) Dividendo A (hasta 2 digitos decimales, max 63)
//   2) Una tecla de confirmacion (# = 4'hF)
//   3) Divisor B (hasta 2 digitos decimales, max 15)
//   4) Una tecla de confirmacion final
// Señales especiales:
//   4'hE = tecla '*' -> borrar (reiniciar captura actual)
//   4'hF = tecla '#' -> confirmar (pasar al siguiente campo)
// Genera señal 'data_valid' cuando ambos operandos estan listos.
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

module input_controller_fsm #(
    parameter DIVIDEND_WIDTH = 6,   // max 63
    parameter DIVISOR_WIDTH  = 4    // max 15
)(
    input  logic                     clk,
    input  logic                     rst_n,
    // Interfaz con keypad_scanner
    input  logic [3:0]               key_value,
    input  logic                     key_valid,
    // Salidas registradas
    output logic [DIVIDEND_WIDTH-1:0] dividend,  // A en binario
    output logic [DIVISOR_WIDTH-1:0]  divisor,   // B en binario
    output logic                      data_valid  // A y B listos
);

    // ------- Tipos de estado -------
    typedef enum logic [2:0] {
        S_IDLE        = 3'd0,
        S_ENTER_A     = 3'd1,   // capturando dividendo
        S_CONFIRM_A   = 3'd2,   // espera '#' para confirmar A
        S_ENTER_B     = 3'd3,   // capturando divisor
        S_CONFIRM_B   = 3'd4,   // espera '#' para confirmar B
        S_VALID       = 3'd5    // datos validos, espera al divisor
    } state_t;

    state_t state, next_state;

    // ------- Registros de acumulacion decimal -------
    // Acumulamos en BCD: digito_decenas * 10 + digito_unidades
    logic [6:0] acc_a;   // acumulador dividendo (7 bits para overflow check)
    logic [4:0] acc_b;   // acumulador divisor
    logic [3:0] digit_count_a, digit_count_b;

    // ------- Registro de estado -------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // ------- Logica de siguiente estado -------
    always_comb begin
        next_state = state;
        case (state)
            S_IDLE: begin
                next_state = S_ENTER_A;
            end
            S_ENTER_A: begin
                if (key_valid && key_value == 4'hF)
                    next_state = S_CONFIRM_A;  // '#' confirma
            end
            S_CONFIRM_A: begin
                next_state = S_ENTER_B;
            end
            S_ENTER_B: begin
                if (key_valid && key_value == 4'hF)
                    next_state = S_VALID;
            end
            S_VALID: begin
                // Permanece valido hasta reset o nueva entrada
                if (key_valid && key_value == 4'hE)
                    next_state = S_IDLE;   // '*' reinicia
            end
            default: next_state = S_IDLE;
        endcase
    end

    // ------- Datapath de captura decimal -------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_a         <= '0;
            acc_b         <= '0;
            digit_count_a <= '0;
            digit_count_b <= '0;
            dividend      <= '0;
            divisor       <= '0;
            data_valid    <= 1'b0;
        end else begin
            data_valid <= 1'b0;

            case (state)
                S_IDLE: begin
                    acc_a         <= '0;
                    acc_b         <= '0;
                    digit_count_a <= '0;
                    digit_count_b <= '0;
                end

                S_ENTER_A: begin
                    if (key_valid) begin
                        if (key_value == 4'hE) begin
                            // Borrar: reiniciar captura de A
                            acc_a         <= '0;
                            digit_count_a <= '0;
                        end else if (key_value <= 4'h9 && digit_count_a < 2) begin
                            // Digito decimal valido (0-9), max 2 digitos
                            // acc_a = acc_a * 10 + key_value
                            // Verificar que no exceda 63
                            if ((acc_a * 10 + key_value) <= 7'd63) begin
                                acc_a         <= acc_a * 10 + key_value;
                                digit_count_a <= digit_count_a + 1;
                            end
                        end
                        // '#' -> transicion manejada en FSM
                    end
                end

                S_CONFIRM_A: begin
                    dividend <= acc_a[DIVIDEND_WIDTH-1:0];
                    acc_b    <= '0;
                    digit_count_b <= '0;
                end

                S_ENTER_B: begin
                    if (key_valid) begin
                        if (key_value == 4'hE) begin
                            acc_b         <= '0;
                            digit_count_b <= '0;
                        end else if (key_value <= 4'h9 && digit_count_b < 2) begin
                            // Divisor max 15
                            if ((acc_b * 10 + key_value) <= 5'd15) begin
                                acc_b         <= acc_b * 10 + key_value;
                                digit_count_b <= digit_count_b + 1;
                            end
                        end
                    end
                end

                S_VALID: begin
                    divisor    <= acc_b[DIVISOR_WIDTH-1:0];
                    data_valid <= 1'b1;
                end

                default: ;
            endcase
        end
    end

endmodule
