# ==========================================
# Part 1 FP8 Simulation Makefile
# ==========================================

all: adder multiplier


# ------------------------------------------
# FP8 Adder
# Compile all Verilog/SystemVerilog files,
# but only run fp8_adder_tb
# ------------------------------------------
adder:
	${VCS_HOME}/bin/vcs -R -full64 -sverilog \
	../*.sv \
	-top fp8_adder_tb \
	-debug_access+all \
	|& tee adder_sim.log


# ------------------------------------------
# FP8 Multiplier
# Compile all Verilog/SystemVerilog files,
# but only run fp8_multiplier_tb
# ------------------------------------------
multiplier:
	${VCS_HOME}/bin/vcs -R -full64 -sverilog \
	../*.sv \
	-top fp8_multiplier_tb \
	-debug_access+all \
	|& tee multiplier_sim.log


# ------------------------------------------
# Compile Adder for Verdi
# ------------------------------------------
adder_verdi:
	${VCS_HOME}/bin/vcs -full64 -sverilog \
	../*.sv \
	-top fp8_adder_tb \
	-debug_access+all -kdb -lca \
	|& tee adder_verdi.log


# ------------------------------------------
# Compile Multiplier for Verdi
# ------------------------------------------
multiplier_verdi:
	${VCS_HOME}/bin/vcs -full64 -sverilog \
	../*.sv \
	-top fp8_multiplier_tb \
	-debug_access+all -kdb -lca \
	|& tee multiplier_verdi.log


# ------------------------------------------
# Launch Verdi
# ------------------------------------------
verdi:
	$(VERDI_HOME)/bin/verdi \
	-dbdir ./simv.daidir \
	-nologo

waves_multiplier:
	$(VERDI_HOME)/bin/verdi \
	-dbdir ./simv.daidir \
	-ssf multiplier.fsdb \
	-nologo

waves_adder:
	$(VERDI_HOME)/bin/verdi \
	-dbdir ./simv.daidir \
	-ssf adder.fsdb \
	-nologo


# ------------------------------------------
# Clean generated files
# ------------------------------------------
clean:
	\rm -rf *.log *.h csrc DVEFiles simv.daidir simv ucli.key \
	*.vpd *.syn *.pvl *.mr *.svf command.log *.txt \
	novas.conf novas.rc verdi_config_file verdiLog \
	novas.fsdb novas.log novas_dump.log
