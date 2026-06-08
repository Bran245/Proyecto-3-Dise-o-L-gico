//==================================================
// archivo: seven_seg_decoder.sv
// Descripcion: Decodificador de digito BCD (0-9) a señales de 7 segmentos.
// Codificacion: activo bajo (anodo comun, tipico en FPGA boards).
// Segmentos: {g, f, e, d, c, b, a} = seg_o[6:0]
//
//   Segmento:
//       aaa
//      f   b
//      f   b
//       ggg
//      e   c
//      e   c
//       ddd
//
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

module seven_seg_decoder (
    input  logic [3:0] bcd_i,    // digito BCD (0-9)
    output logic [6:0] seg_o     // {g,f,e,d,c,b,a} activo bajo
);

    always_comb begin
        case (bcd_i)
            //                   gfedcba
            4'd0: seg_o = 7'b1000000;  // 0
            4'd1: seg_o = 7'b1111001;  // 1
            4'd2: seg_o = 7'b0100100;  // 2
            4'd3: seg_o = 7'b0110000;  // 3
            4'd4: seg_o = 7'b0011001;  // 4
            4'd5: seg_o = 7'b0010010;  // 5
            4'd6: seg_o = 7'b0000010;  // 6
            4'd7: seg_o = 7'b1111000;  // 7
            4'd8: seg_o = 7'b0000000;  // 8
            4'd9: seg_o = 7'b0010000;  // 9
            default: seg_o = 7'b1111111;  // apagado
        endcase
    end

endmodule
