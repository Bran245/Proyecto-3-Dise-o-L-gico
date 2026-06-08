//==================================================
// archivo: display_controller.sv
// Descripcion: Controlador de seleccion de resultado para el display.
// Permite seleccionar entre cociente y residuo mediante un boton
// o una tecla del teclado (boton_sel).
//
// El display muestra 2 digitos para el resultado (max 2 decimales).
// Para la version base:  cociente max 63, residuo max 14.
// Para la version extra: cociente max 127, residuo max 30.
//
// Señales:
//   sel_i        : 0 = cociente, 1 = residuo
//   done_i       : resultado valido (desde subsistema de division)
//   quotient_bcd : cociente en BCD (desde binary_to_bcd)
//   remainder_bcd: residuo en BCD (desde binary_to_bcd)
//
// Salida: digit[3:0] para display_mux
//   digit[1:0] = decenas y unidades del numero seleccionado
//   digit[3:2] = apagados (o indicador de modo)
//
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

module display_controller #(
    parameter BCD_DIGITS_Q = 2,   // digitos BCD cociente  (base=2, extra=3)
    parameter BCD_DIGITS_R = 2    // digitos BCD residuo   (base=2, extra=2)
)(
    input  logic                        clk,
    input  logic                        rst_n,
    // Control
    input  logic                        sel_i,     // 0=cociente, 1=residuo
    input  logic                        done_i,    // resultado valido
    // Datos BCD
    input  logic [BCD_DIGITS_Q*4-1:0]  quotient_bcd_i,
    input  logic [BCD_DIGITS_R*4-1:0]  remainder_bcd_i,
    // Hacia display_mux (4 digitos)
    output logic [3:0]                  digit [3:0]
);

    logic [3:0] q_digits [BCD_DIGITS_Q-1:0];
    logic [3:0] r_digits [BCD_DIGITS_R-1:0];

    // Desempacar BCD en arreglos de digitos
    genvar k;
    generate
        for (k = 0; k < BCD_DIGITS_Q; k++) begin : unpack_q
            assign q_digits[k] = quotient_bcd_i[k*4 +: 4];
        end
        for (k = 0; k < BCD_DIGITS_R; k++) begin : unpack_r
            assign r_digits[k] = remainder_bcd_i[k*4 +: 4];
        end
    endgenerate

    // Registro de salida hacia display
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            digit[0] <= 4'd0;
            digit[1] <= 4'd0;
            digit[2] <= 4'd0;
            digit[3] <= 4'd0;
        end else begin
            if (done_i) begin
                if (!sel_i) begin
                    // Mostrar cociente
                    digit[0] <= q_digits[0];  // unidades
                    digit[1] <= q_digits[1];  // decenas
                    // digit[2] para version extra (centenas del cociente)
                    // Solo acceder si BCD_DIGITS_Q >= 3
                    digit[2] <= 4'd0;
                    digit[3] <= 4'd0;
                end else begin
                    // Mostrar residuo
                    digit[0] <= r_digits[0];
                    digit[1] <= r_digits[1];
                    digit[2] <= 4'd0;
                    digit[3] <= 4'd0;
                end
            end
        end
    end

endmodule
