//==================================================
// archivo: tb_binary_to_bcd.sv
// Descripcion: Testbench para binary_to_bcd (double-dabble).
// Verifica la conversion correcta para todos los rangos relevantes
// del proyecto: 0-63 (base) y 0-127 (extra).
// Proyecto: EL-3307 Diseño Logico I-2026
//==================================================

`timescale 1ns/1ps

module tb_binary_to_bcd;

    // ---- Version base: 6 bits, 2 digitos ----
    logic [5:0] bin6;
    logic [7:0] bcd8;   // 2 digitos x 4 bits

    binary_to_bcd #(.INPUT_WIDTH(6), .BCD_DIGITS(2)) dut_base (
        .bin_i(bin6),
        .bcd_o(bcd8)
    );

    // ---- Version extra: 7 bits, 3 digitos ----
    logic [6:0]  bin7;
    logic [11:0] bcd12;  // 3 digitos x 4 bits

    binary_to_bcd #(.INPUT_WIDTH(7), .BCD_DIGITS(3)) dut_extra (
        .bin_i(bin7),
        .bcd_o(bcd12)
    );

    // Funcion de referencia: bin -> digitos decimales
    function automatic logic [7:0] ref_bcd2(input integer val);
        return {4'(val / 10), 4'(val % 10)};
    endfunction

    function automatic logic [11:0] ref_bcd3(input integer val);
        return {4'(val / 100), 4'((val / 10) % 10), 4'(val % 10)};
    endfunction

    integer i;
    integer pass_cnt, fail_cnt;

    initial begin
        $dumpfile("tb_binary_to_bcd.vcd");
        $dumpvars(0, tb_binary_to_bcd);

        pass_cnt = 0;
        fail_cnt = 0;

        $display("=== Test binary_to_bcd version base (6 bits, 2 digitos) ===");
        for (i = 0; i <= 63; i++) begin
            bin6 = i[5:0];
            #10;
            if (bcd8 == ref_bcd2(i)) begin
                pass_cnt++;
            end else begin
                $error("FAIL: bin=%0d => bcd=%h (esperado %h)",
                    i, bcd8, ref_bcd2(i));
                fail_cnt++;
            end
        end
        $display("  Base: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);

        pass_cnt = 0; fail_cnt = 0;

        $display("=== Test binary_to_bcd version extra (7 bits, 3 digitos) ===");
        for (i = 0; i <= 127; i++) begin
            bin7 = i[6:0];
            #10;
            if (bcd12 == ref_bcd3(i)) begin
                pass_cnt++;
            end else begin
                $error("FAIL: bin=%0d => bcd=%h (esperado %h)",
                    i, bcd12, ref_bcd3(i));
                fail_cnt++;
            end
        end
        $display("  Extra: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);

        $display("=== Testbench BCD completado ===");
        $finish;
    end

endmodule
