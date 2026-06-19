// ============================================================
//  binary_to_bcd.sv — Basic version using only + - and comparisons
//  Works for 0-127, no division or modulo
// ============================================================
module binary_to_bcd #(
    parameter INPUT_WIDTH = 7,
    parameter BCD_DIGITS  = 3
)(
    input  logic [INPUT_WIDTH-1:0]   bin_i,
    output logic [BCD_DIGITS*4-1:0]  bcd_o
);
    always_comb begin
        logic [7:0] n;
        logic [7:0] temp;

        n = bin_i;

        // Hundreds digit (0 or 1)
        if (n >= 100) begin
            bcd_o[11:8] = 4'd1;
            temp = n - 100;
        end else begin
            bcd_o[11:8] = 4'd0;
            temp = n;
        end

        // Tens digit
        if (temp >= 90) begin
            bcd_o[7:4] = 4'd9;
            temp = temp - 90;
        end else if (temp >= 80) begin
            bcd_o[7:4] = 4'd8;
            temp = temp - 80;
        end else if (temp >= 70) begin
            bcd_o[7:4] = 4'd7;
            temp = temp - 70;
        end else if (temp >= 60) begin
            bcd_o[7:4] = 4'd6;
            temp = temp - 60;
        end else if (temp >= 50) begin
            bcd_o[7:4] = 4'd5;
            temp = temp - 50;
        end else if (temp >= 40) begin
            bcd_o[7:4] = 4'd4;
            temp = temp - 40;
        end else if (temp >= 30) begin
            bcd_o[7:4] = 4'd3;
            temp = temp - 30;
        end else if (temp >= 20) begin
            bcd_o[7:4] = 4'd2;
            temp = temp - 20;
        end else if (temp >= 10) begin
            bcd_o[7:4] = 4'd1;
            temp = temp - 10;
        end else begin
            bcd_o[7:4] = 4'd0;
        end

        // Units digit
        bcd_o[3:0] = temp[3:0];   // since temp is now < 10
    end
endmodule