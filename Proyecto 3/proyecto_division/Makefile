# ==================================================
# Makefile para proyecto EL-3307 Division de Enteros
# Herramientas: iverilog + vvp  (flujo abierto)
# Uso:
#   make sim_divider     -> simular tb_divider_top
#   make sim_bcd         -> simular tb_binary_to_bcd
#   make sim_display     -> simular tb_display_subsystem
#   make sim_top         -> simular tb_top
#   make all             -> todos los testbenches
#   make clean           -> limpiar archivos generados
# ==================================================

RTL  = rtl
TB   = tb
IVLOG = iverilog
VVP   = vvp

# Archivos RTL comunes
RTL_FILES = \
    $(RTL)/sync_2ff.sv \
    $(RTL)/debouncer.sv \
    $(RTL)/keypad_scanner.sv \
    $(RTL)/input_controller_fsm.sv \
    $(RTL)/input_subsystem.sv \
    $(RTL)/divider_datapath.sv \
    $(RTL)/divider_controller_fsm.sv \
    $(RTL)/divider_top.sv \
    $(RTL)/divider_pipeline_stage.sv \
    $(RTL)/divider_pipeline.sv \
    $(RTL)/binary_to_bcd.sv \
    $(RTL)/seven_seg_decoder.sv \
    $(RTL)/display_mux.sv \
    $(RTL)/display_controller.sv \
    $(RTL)/display_subsystem.sv \
    $(RTL)/top.sv

.PHONY: all sim_divider_dp sim_divider_ctrl sim_divider sim_bcd sim_display sim_top clean

all: sim_divider_dp sim_divider_ctrl sim_divider sim_bcd sim_display sim_top

sim_divider_dp:
	$(IVLOG) -g2012 -o sim_divider_dp.vvp \
	    $(RTL_FILES) $(TB)/tb_divider_datapath.sv
	$(VVP) sim_divider_dp.vvp

sim_divider_ctrl:
	$(IVLOG) -g2012 -o sim_divider_ctrl.vvp \
	    $(RTL_FILES) $(TB)/tb_divider_controller.sv
	$(VVP) sim_divider_ctrl.vvp

sim_divider:
	$(IVLOG) -g2012 -o sim_divider.vvp \
	    $(RTL_FILES) $(TB)/tb_divider_top.sv
	$(VVP) sim_divider.vvp

sim_bcd:
	$(IVLOG) -g2012 -o sim_bcd.vvp \
	    $(RTL_FILES) $(TB)/tb_binary_to_bcd.sv
	$(VVP) sim_bcd.vvp

sim_display:
	$(IVLOG) -g2012 -o sim_display.vvp \
	    $(RTL_FILES) $(TB)/tb_display_subsystem.sv
	$(VVP) sim_display.vvp

sim_top:
	$(IVLOG) -g2012 -o sim_top.vvp \
	    $(RTL_FILES) $(TB)/tb_top.sv
	$(VVP) sim_top.vvp

clean:
	rm -f *.vvp *.vcd
