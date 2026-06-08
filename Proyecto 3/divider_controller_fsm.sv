//==================================================
// archivo: divider_controller_fsm.sv
// Descripcion: FSM de control del subsistema de division entera.
//
// Estados:
//   IDLE    : Espera señal 'valid_i' del subsistema de lectura.
//             Las señales de datapath permanecen inactivas.
//
//   LOAD    : Activa 'load' por un ciclo para cargar A y B en
//             los registros del datapath. Inicializa el contador.
//
//   ITERATE : Activa 'shift' cada ciclo. El datapath ejecuta un
//             paso del algoritmo por ciclo. Se repite DIVIDEND_WIDTH
//             veces (N iteraciones).
//
//   DONE    : Resultado estable. Activa 'done_o' para el subsistema
//             de display. Permanece aqui hasta que valid_i se desactive.
//
// Señales de control generadas:
//   load  -> habilita carga de registros en datapath
//   shift -> habilita un paso de iteracion en datapath
//   done_o -> resultado valido para siguiente subsistema
//
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

module divider_controller_fsm (
    input  logic clk,
    input  logic rst_n,
    // Interfaz con subsistema de lectura
    input  logic valid_i,      // datos de entrada validos
    // Interfaz con datapath
    input  logic iter_done,    // datapath: iteraciones completas
    output logic load,         // control: cargar registros
    output logic shift,        // control: ejecutar un paso
    // Interfaz con subsistema de display
    output logic done_o        // resultado valido
);

    // ------- Definicion de estados -------
    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        LOAD    = 2'b01,
        ITERATE = 2'b10,
        DONE    = 2'b11
    } state_t;

    state_t state, next_state;

    // ------- Registro de estado -------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ------- Logica de siguiente estado -------
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (valid_i)
                    next_state = LOAD;
            end
            LOAD: begin
                // Un ciclo de carga, luego iteramos
                next_state = ITERATE;
            end
            ITERATE: begin
                // Cuando iter_done Y acabamos de hacer el ultimo shift
                if (iter_done)
                    next_state = DONE;
            end
            DONE: begin
                // Espera a que valid_i baje (nuevo dato) o reset
                if (!valid_i)
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // ------- Logica de salidas (Moore) -------
    always_comb begin
        load   = 1'b0;
        shift  = 1'b0;
        done_o = 1'b0;

        case (state)
            IDLE: begin
                // Sin accion
            end
            LOAD: begin
                load = 1'b1;
            end
            ITERATE: begin
                shift = 1'b1;
            end
            DONE: begin
                done_o = 1'b1;
            end
            default: ;
        endcase
    end

endmodule
