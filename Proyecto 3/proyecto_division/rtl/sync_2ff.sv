//==================================================
// archivo: sync_2ff.sv
// Descripcion: Sincronizador de dos flip-flops para señales externas.
// Previene metaestabilidad al cruzar dominios de reloj.
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

module sync_2ff #(
    parameter WIDTH = 1
)(
    input  logic             clk,
    input  logic             rst_n,
    input  logic [WIDTH-1:0] async_in,
    output logic [WIDTH-1:0] sync_out
);

    logic [WIDTH-1:0] stage1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1   <= '0;
            sync_out <= '0;
        end else begin
            stage1   <= async_in;
            sync_out <= stage1;
        end
    end

endmodule
