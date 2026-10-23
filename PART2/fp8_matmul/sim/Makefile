# ==========================================
# Part 2 FP8 4x4 Matrix Multiplication
# ==========================================

all: compile_and_sim


# Compile and run Part 2 simulation
compile_and_sim:
	${VCS_HOME}/bin/vcs -R -full64 -sverilog \
	../../fp8_adder.sv \
	../../fp8_multiplier.sv \
	../../matmul.sv \
	../../matmul_with_ram.v \
	../../matmul_with_ram_tb.v \
	-top matmul_tb \
	-debug_access+all \
	-timescale=1ns/1ps \
	|& tee compile_and_sim.log


# Compile only
compile:
	${VCS_HOME}/bin/vcs -full64 -sverilog \
	../../fp8_adder.sv \
	../../fp8_multiplier.sv \
	../../matmul.sv \
	../../matmul_with_ram.v \
	../../matmul_with_ram_tb.v \
	-top matmul_tb \
	-debug_access+all \
	-timescale=1ns/1ps \
	|& tee compile.log


# Compile and generate Verdi database
compile_verdi:
	${VCS_HOME}/bin/vcs -full64 -sverilog \
	../../fp8_adder.sv \
	../../fp8_multiplier.sv \
	../../matmul.sv \
	../../matmul_with_ram.v \
	../../matmul_with_ram_tb.v \
	-top matmul_tb \
	-debug_access+all -kdb -lca \
	-timescale=1ns/1ps \
	|& tee compile_verdi.log


# Run already-compiled simulation
sim:
	./simv


# Launch Verdi
verdi:
	$(VERDI_HOME)/bin/verdi \
	-dbdir ./simv.daidir \
	-nologo


# Launch Verdi with waveform database
waves_verdi:
	$(VERDI_HOME)/bin/verdi \
	-dbdir ./simv.daidir \
	-ssf novas.fsdb \
	-nologo


# Remove generated files
clean:
	\rm -rf *.log *.h csrc DVEFiles simv.daidir simv ucli.key \
	vcdplus.vpd *.syn *.pvl *.mr *.svf command.log *.txt \
	novas.conf novas.rc verdi_config_file verdiLog \
	novas.fsdb novas.log novas_dump.log
