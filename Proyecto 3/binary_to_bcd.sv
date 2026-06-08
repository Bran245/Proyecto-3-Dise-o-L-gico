//==================================================
// archivo: binary_to_bcd.sv
// Descripcion: Conversion de numero binario a representacion BCD
// mediante el algoritmo "double-dabble" (shift-and-add-3).
//
// El algoritmo funciona de la siguiente forma:
//   1. Se desplaza el numero binario bit a bit hacia el registro BCD.
//   2. Antes de cada desplazamiento, si algun digito BCD es >= 5,
//      se le suman 3 (para corregir el desbordamiento BCD).
//   3. Se repite INPUT_WIDTH veces.
//
// Esta es una implementacion combinacional (unrolled), apropiada para
// FPGA con anchos de datos pequeños como los de este proyecto.
//
// Parametros:
//   INPUT_WIDTH  : ancho del numero binario (6 para cociente, 4 para residuo)
//   BCD_DIGITS   : numero de digitos BCD requeridos
//     max(63)  -> 2 digitos BCD
//     max(127) -> 3 digitos BCD
//
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

module binary_to_bcd #(
    parameter INPUT_WIDTH = 6,
    parameter BCD_DIGITS  = 2   // numero de digitos decimales de salida
)(
    input  logic [INPUT_WIDTH-1:0]    bin_i,
    output logic [BCD_DIGITS*4-1:0]  bcd_o
);

    // ------- Implementacion double-dabble combinacional -------
    // Se crean INPUT_WIDTH niveles de corrección
    // Cada nivel tiene BCD_DIGITS digitos de 4 bits + el binario restante

    // Array de trabajo: [nivel][BCD_DIGITS digitos + bits del binario]
    // Dimension total por nivel: BCD_DIGITS*4 + INPUT_WIDTH bits
    localparam TOTAL_BITS = BCD_DIGITS * 4 + INPUT_WIDTH;

    logic [TOTAL_BITS-1:0] work [INPUT_WIDTH:0];

    // Inicializar: el binario en los bits bajos, BCD en cero
    always_comb begin : double_dabble
        integer lvl, d;

        // Nivel inicial: BCD=0, binario=bin_i
        work[0] = {{(BCD_DIGITS*4){1'b0}}, bin_i};

        for (lvl = 0; lvl < INPUT_WIDTH; lvl++) begin
            // Paso 1: Correccion (add-3 si digito >= 5)
            work[lvl+1] = work[lvl];
            for (d = 0; d < BCD_DIGITS; d++) begin
                // Indice del digito en work: bits [INPUT_WIDTH + d*4 + 3 : INPUT_WIDTH + d*4]
                if (work[lvl+1][INPUT_WIDTH + d*4 +: 4] >= 4'd5)
                    work[lvl+1][INPUT_WIDTH + d*4 +: 4] =
                        work[lvl+1][INPUT_WIDTH + d*4 +: 4] + 4'd3;
            end
            // Paso 2: Desplazamiento a la izquierda (shift left 1)
            work[lvl+1] = work[lvl+1] << 1;
        end

        // Extraer digitos BCD del resultado final
        bcd_o = work[INPUT_WIDTH][TOTAL_BITS-1 : INPUT_WIDTH];
    end

endmodule
