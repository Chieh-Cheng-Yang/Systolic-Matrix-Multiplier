# Lab 3 – FP8 Arithmetic and Systolic Matrix Multiplication

## Overview

This project implements FP8 E3M4 arithmetic units and integrates them into a 4×4 systolic matrix multiplication design.

Part 1 implements and verifies an FP8 adder and FP8 multiplier.

Part 2 replaces the original integer multiply-accumulate (MAC) operation in the provided systolic matrix multiplier with FP8 arithmetic. The FP8 multiplier and adder developed in Part 1 are used to perform:

C_new = C_old + (A × B)

FP8 exception flags are also propagated through the systolic matrix multiplication design.

---

# How to Run

Before running simulation or synthesis, make sure the required Synopsys environment has been configured.

## Part 1 – FP8 Adder Simulation

Go to the Part 1 simulation directory:

```bash
cd PART1/sim
```

Clean previously generated files:

```bash
make clean
```

Compile the FP8 adder and its testbench and generate the Verdi KDB database:

```bash
make adder_verdi
```

Run the simulation:

```bash
./simv
```

The simulation executes the FP8 adder test cases, prints PASS/FAIL results, and generates the FSDB waveform database.

Open the waveform in Verdi:

```bash
make waves_adder
```

---

## Part 1 – FP8 Multiplier Simulation

Go to the Part 1 simulation directory:

```bash
cd PART1/sim
```

Clean previously generated files:

```bash
make clean
```

Compile the FP8 multiplier and its testbench and generate the Verdi KDB database:

```bash
make multiplier_verdi
```

Run the simulation:

```bash
./simv
```

The simulation executes the FP8 multiplier test cases, prints PASS/FAIL results, and generates the FSDB waveform database.

Open the waveform in Verdi:

```bash
make waves_multiplier
```

---

# Part 2

## Part 2 – FP8 Matrix Multiplication Simulation

Go to the FP8 matrix multiplication simulation directory:

```bash
cd PART2/fp8_matmul/sim
```

Clean previously generated files:

```bash
make clean
```

Compile the FP8 matrix multiplication design, RAM wrapper, and testbench and generate the Verdi KDB database:

```bash
make compile_verdi
```

Run the simulation:

```bash
./simv
```

The testbench automatically executes two test cases:

1. Normal FP8 matrix multiplication with no exception.
2. FP8 matrix multiplication containing positive infinity to verify exception propagation.

The simulation prints PASS/FAIL results and generates the FSDB waveform database.

Open the waveform in Verdi:

```bash
make waves_verdi
```

The waveform can be used to observe the input RAM reads, `start`, `done`, exception flags, and output RAM writes.

---

## Part 2 – INT8 Baseline Synthesis

The baseline integer design is used only for synthesis comparison.

Go to the baseline synthesis directory:

```bash
cd PART2/baseline/synth
```

Clean previous synthesis results:

```bash
make clean
```

Run synthesis:

```bash
make synth
```

The baseline synthesis uses `matmul_ori.v` with `matmul_4x4_systolic` as the top-level module.

The following synthesis reports are generated:

- `area.rep`
- `timing.rep`
- `cell.rep`
- `power.rep`

---

## Part 2 – FP8 Matrix Multiplication Synthesis

Go to the FP8 synthesis directory:

```bash
cd PART2/fp8_matmul/synth
```

Clean previous synthesis results:

```bash
make clean
```

Run synthesis:

```bash
make synth
```

The FP8 synthesis uses:

- `matmul.sv`
- `fp8_adder.sv`
- `fp8_multiplier.sv`

with `matmul_4x4_systolic` as the top-level module.

The following synthesis reports are generated:

- `area.rep`
- `timing.rep`
- `cell.rep`
- `power.rep`

The generated reports can be used to compare the area and timing performance of the baseline integer and FP8 implementations.

---

## Command Summary

| Part | Task | Commands |
|---|---|---|
| Part 1 | FP8 Adder Simulation | `make clean` → `make adder_verdi` → `./simv` → `make waves_adder` |
| Part 1 | FP8 Multiplier Simulation | `make clean` → `make multiplier_verdi` → `./simv` → `make waves_multiplier` |
| Part 2 | FP8 Matrix Multiplication Simulation | `make clean` → `make compile_verdi` → `./simv` → `make waves_verdi` |
| Part 2 | INT8 Baseline Synthesis | `make clean` → `make synth` |
| Part 2 | FP8 Matrix Multiplication Synthesis | `make clean` → `make synth` |
