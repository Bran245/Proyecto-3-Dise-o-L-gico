// ============================================================
//  display_7seg.sv - With timing fix
// ============================================================
module display_7seg #(
    parameter REFRESH_COUNT = 20000   // Lowered
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable,
    input  logic [3:0]  dig3, dig2, dig1, dig0,
    output logic [3:0]  anodos,
    output logic [6:0]  segmentos
);

    localparam CNT_BITS = 16;

    logic [CNT_BITS-1:0] cnt_refresh;
    logic [1:0]          sel_digito;
    logic [3:0]          anodos_r;
    logic [6:0]          segmentos_r;

    // Registered versions to break long paths
    logic [3:0] digito_activo_r;
    logic [6:0] seg_comb_r;
    logic       blank_digit_r;

    assign anodos    = anodos_r;
    assign segmentos = segmentos_r;

    // Register the input digits
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            digito_activo_r <= 4'd0;
        else
            digito_activo_r <= (sel_digito == 2'd0) ? dig0 :
                               (sel_digito == 2'd1) ? dig1 :
                               (sel_digito == 2'd2) ? dig2 : dig3;
    end

    // Segment decoder
    always_comb begin
        case (digito_activo_r)
            4'd0: seg_comb_r = 7'b1111110;
            4'd1: seg_comb_r = 7'b0110000;
            4'd2: seg_comb_r = 7'b1101101;
            4'd3: seg_comb_r = 7'b1111001;
            4'd4: seg_comb_r = 7'b0110011;
            4'd5: seg_comb_r = 7'b1011011;
            4'd6: seg_comb_r = 7'b1011111;
            4'd7: seg_comb_r = 7'b1110000;
            4'd8: seg_comb_r = 7'b1111111;
            4'd9: seg_comb_r = 7'b1111011;
            4'hE: seg_comb_r = 7'b1001111;
            default: seg_comb_r = 7'b0000000;
        endcase
    end

    // Refresh counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_refresh <= '0;
            sel_digito  <= '0;
        end else begin
            if (cnt_refresh == REFRESH_COUNT - 1) begin
                cnt_refresh <= '0;
                sel_digito  <= sel_digito + 1;
            end else begin
                cnt_refresh <= cnt_refresh + 1;
            end
        end
    end

    // Blanking logic (registered)
    logic all_zero;
    assign all_zero = (dig3 == 0) && (dig2 == 0) && (dig1 == 0) && (dig0 == 0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            blank_digit_r <= 1'b1;
        end else begin
            blank_digit_r <= !enable || all_zero ||
                             (sel_digito == 2'd3 && dig3 == 0) ||
                             (sel_digito == 2'd2 && dig3 == 0 && dig2 == 0) ||
                             (sel_digito == 2'd1 && dig3 == 0 && dig2 == 0 && dig1 == 0);
        end
    end

    // Output register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            anodos_r    <= 4'b0000;
            segmentos_r <= 7'b0000000;
        end else if (blank_digit_r) begin
            anodos_r    <= 4'b0000;
            segmentos_r <= 7'b0000000;
        end else begin
            case (sel_digito)
                2'd0: anodos_r <= 4'b0001;
                2'd1: anodos_r <= 4'b0010;
                2'd2: anodos_r <= 4'b0100;
                2'd3: anodos_r <= 4'b1000;
                default: anodos_r <= 4'b0000;
            endcase
            segmentos_r <= seg_comb_r;
        end
    end

endmodule