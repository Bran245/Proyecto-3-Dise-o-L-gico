//==================================================
// archivo: divider_datapath.sv
// Descripcion: Ruta de datos para el divisor iterativo de enteros sin signo.
//
// Implementa el algoritmo de Harris & Harris seccion 5.2.7:
//   R' = 0
//   for i = N-1 downto 0:
//     R = {R' << 1, A[i]}
//     D = R - B
//     if D < 0: Q[i]=0, R'=R
//     else:     Q[i]=1, R'=D
//
// Arquitectura: Datapath controlado por señales de la FSM.
//
// Parametros:
//   DIVIDEND_WIDTH : ancho del dividendo (base=6, extra=7)
//   DIVISOR_WIDTH  : ancho del divisor   (base=4, extra=5)
//
// Señales de control (desde FSM):
//   load       : carga A y B en los registros internos
//   shift      : ejecuta un paso de iteracion
//   sel_result : 1=resultado valido (del registro), 0=cargando
//
// Salidas de estado (hacia FSM):
//   iter_done  : se completaron todas las N iteraciones
//
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

module divider_datapath #(
    parameter DIVIDEND_WIDTH = 6,
    parameter DIVISOR_WIDTH  = 4
)(
    input  logic                      clk,
    input  logic                      rst_n,
    // Operandos
    input  logic [DIVIDEND_WIDTH-1:0] dividend_i,
    input  logic [DIVISOR_WIDTH-1:0]  divisor_i,
    // Señales de control (desde FSM)
    input  logic                      load,
    input  logic                      shift,      // ejecutar un paso
    // Estado hacia FSM
    output logic                      iter_done,
    // Resultados
    output logic [DIVIDEND_WIDTH-1:0] quotient,
    output logic [DIVISOR_WIDTH-1:0]  remainder
);

    // ------- Registros internos -------
    logic [DIVIDEND_WIDTH-1:0] A_reg;   // dividendo
    logic [DIVISOR_WIDTH-1:0]  B_reg;   // divisor
    logic [DIVIDEND_WIDTH-1:0] Q_reg;   // cociente acumulado
    // R necesita DIVISOR_WIDTH+1 bits para detectar signo en resta
    logic [DIVISOR_WIDTH:0]    R_reg;   // residuo parcial (1 bit extra para carry)
    // Contador de iteracion: de N-1 hasta 0
    logic [$clog2(DIVIDEND_WIDTH):0] iter_cnt;

    // ------- Logica combinacional de un paso -------
    logic [DIVISOR_WIDTH:0]    R_shift;   // R desplazado
    logic [DIVISOR_WIDTH:0]    D_sub;     // R - B (con bit de signo)
    logic                      q_bit;     // bit de cociente de esta iteracion

    // Formacion de R desplazado: {R_reg[DIVISOR_WIDTH-1:0], A_reg[iter_cnt]}
    // Usamos un mux one-hot sobre los bits del dividendo para sintetizabilidad
    logic a_bit_sel;
    always_comb begin : sel_a_bit
        integer k;
        a_bit_sel = 1'b0;
        for (k = 0; k < DIVIDEND_WIDTH; k++) begin
            if (iter_cnt == k[$clog2(DIVIDEND_WIDTH):0])
                a_bit_sel = A_reg[k];
        end
    end

    always_comb begin
        // Shift left de R y entrada del bit i del dividendo
        R_shift = {R_reg[DIVISOR_WIDTH-1:0], a_bit_sel};
        // Resta: D = R_shift - B_reg (extendido a DIVISOR_WIDTH+1 bits)
        D_sub   = R_shift - {1'b0, B_reg};
        // Si el bit de signo (MSB de D_sub) es 0 => D >= 0 => Q[i]=1, R'=D
        q_bit   = ~D_sub[DIVISOR_WIDTH];
    end

    // ------- Logica secuencial -------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_reg    <= '0;
            B_reg    <= '0;
            Q_reg    <= '0;
            R_reg    <= '0;
            iter_cnt <= '0;
        end else begin
            if (load) begin
                A_reg    <= dividend_i;
                B_reg    <= divisor_i;
                Q_reg    <= '0;
                R_reg    <= '0;
                iter_cnt <= DIVIDEND_WIDTH - 1;
            end else if (shift) begin
                // Actualizar R' segun resultado de comparacion
                if (q_bit) begin
                    // D >= 0: Q[i]=1, R' = D
                    R_reg <= D_sub;
                    // Setear bit iter_cnt del cociente via mux
                    for (int k = 0; k < DIVIDEND_WIDTH; k++) begin
                        if (iter_cnt == k[$clog2(DIVIDEND_WIDTH):0])
                            Q_reg[k] <= 1'b1;
                    end
                end else begin
                    // D < 0:  Q[i]=0, R' = R_shift
                    R_reg <= R_shift;
                    for (int k = 0; k < DIVIDEND_WIDTH; k++) begin
                        if (iter_cnt == k[$clog2(DIVIDEND_WIDTH):0])
                            Q_reg[k] <= 1'b0;
                    end
                end
                // Decrementar contador (con saturacion en 0)
                if (iter_cnt != 0)
                    iter_cnt <= iter_cnt - 1;
            end
        end
    end

    // ------- Señal iter_done -------
    // Se activa cuando el contador llega a 0 Y se acaba de ejecutar shift
    // La FSM detecta esto para pasar a DONE
    assign iter_done = (iter_cnt == 0);

    // ------- Salidas -------
    assign quotient  = Q_reg;
    assign remainder = R_reg[DIVISOR_WIDTH-1:0];

endmodule
