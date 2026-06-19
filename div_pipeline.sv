// ============================================================
//  div_pipeline.sv  —  EL-3307 Proyecto corto III
//
//  Divisor entero sin signo, pipeline de A_BITS etapas.
//
//  Parámetros por defecto:
//    A_BITS=7, B_BITS=5  →  máx 127 ÷ 31  (puntaje extra)
//
//  Latencia fija: A_BITS ciclos de reloj.
//  Protocolo   : valid=1 un ciclo → done=1 A_BITS ciclos después.
// ============================================================

module div_cell (
    input  logic R_in_bit,
    input  logic B_in_bit,
    input  logic Cin,
    input  logic N,
    output logic R_out,
    output logic D,
    output logic Cout
);
    logic [1:0] sum2;
    assign sum2  = {1'b0, R_in_bit} + {1'b0, ~B_in_bit} + {1'b0, Cin};
    assign Cout  = sum2[1];
    assign D     = sum2[0];
    assign R_out = N ? R_in_bit : D;
endmodule

module div_row #(
    parameter B_BITS = 5
)(
    input  logic [B_BITS-1:0] R_in,
    input  logic              A_bit,
    input  logic [B_BITS-1:0] B_in,
    output logic              Q_bit,
    output logic [B_BITS-1:0] R_out
);
    logic [B_BITS:0] R_sh;
    assign R_sh = {R_in, A_bit};

    logic [B_BITS-1:0] carry;
    logic              cout_top;
    logic              N;
    logic [B_BITS:0]   D_int;
    logic [B_BITS:0]   R_out_int;

    div_cell u0 (
        .R_in_bit(R_sh[0]), .B_in_bit(B_in[0]), .Cin(1'b1),
        .N(N), .R_out(R_out_int[0]), .D(D_int[0]), .Cout(carry[0])
    );

    genvar i;
    generate
        for (i = 1; i < B_BITS; i++) begin : GEN_MID
            div_cell u (
                .R_in_bit(R_sh[i]), .B_in_bit(B_in[i]), .Cin(carry[i-1]),
                .N(N), .R_out(R_out_int[i]), .D(D_int[i]), .Cout(carry[i])
            );
        end
    endgenerate

    div_cell u_top (
        .R_in_bit(R_sh[B_BITS]), .B_in_bit(1'b0), .Cin(carry[B_BITS-1]),
        .N(N), .R_out(R_out_int[B_BITS]), .D(D_int[B_BITS]), .Cout(cout_top)
    );

    assign N     = ~cout_top;
    assign Q_bit = cout_top;
    assign R_out = R_out_int[B_BITS-1:0];
endmodule

module div_pipeline #(
    parameter A_BITS = 7,
    parameter B_BITS = 5
)(
    input  logic              clk,
    input  logic              rst,
    input  logic              valid,
    input  logic [A_BITS-1:0] A,
    input  logic [B_BITS-1:0] B,
    output logic              done,
    output logic [A_BITS-1:0] Q,
    output logic [B_BITS-1:0] R
);
    logic [B_BITS-1:0] r_in0;
    logic [B_BITS-1:0] b_in0;
    logic [A_BITS-1:0] a_in0;
    logic [A_BITS-1:0] q_in0;
    logic              v_in0;

    always_comb begin
        r_in0 = '0;
        b_in0 = B;
        a_in0 = A;
        q_in0 = '0;
        v_in0 = valid;
    end

    logic [B_BITS-1:0] r_pipe [1:A_BITS];
    logic [B_BITS-1:0] b_pipe [1:A_BITS];
    logic [A_BITS-1:0] a_pipe [1:A_BITS];
    logic [A_BITS-1:0] q_pipe [1:A_BITS];
    logic              v_pipe [1:A_BITS];

    logic [B_BITS-1:0] r_row  [0:A_BITS-1];
    logic              q_row  [0:A_BITS-1];
    logic [A_BITS-1:0] q_next [0:A_BITS-1];

    genvar s;
    generate
        for (s = 0; s < A_BITS; s++) begin : STAGE

            div_row #(.B_BITS(B_BITS)) row_inst (
                .R_in  (s == 0 ? r_in0           : r_pipe[s]),
                .A_bit (s == 0 ? a_in0[A_BITS-1] : a_pipe[s][A_BITS-1-s]),
                .B_in  (s == 0 ? b_in0            : b_pipe[s]),
                .Q_bit (q_row[s]),
                .R_out (r_row[s])
            );

            always_comb begin
                q_next[s]             = (s == 0) ? q_in0 : q_pipe[s];
                q_next[s][A_BITS-1-s] = q_row[s];
            end

            always_ff @(posedge clk) begin
                if (rst) begin
                    r_pipe[s+1] <= '0;
                    b_pipe[s+1] <= '0;
                    a_pipe[s+1] <= '0;
                    q_pipe[s+1] <= '0;
                    v_pipe[s+1] <= 1'b0;
                end else begin
                    r_pipe[s+1] <= r_row[s];
                    b_pipe[s+1] <= (s == 0) ? b_in0 : b_pipe[s];
                    a_pipe[s+1] <= (s == 0) ? a_in0 : a_pipe[s];
                    q_pipe[s+1] <= q_next[s];
                    v_pipe[s+1] <= (s == 0) ? v_in0 : v_pipe[s];
                end
            end
        end
    endgenerate

    assign Q    = q_pipe[A_BITS];
    assign R    = r_pipe[A_BITS];
    assign done = v_pipe[A_BITS];
endmodule
