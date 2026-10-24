# Part 1 – FP8 Arithmetic Units

## Overview

Part 1 implements and verifies two FP8 E3M4 arithmetic units:

- FP8 Adder
- FP8 Multiplier

The FP8 E3M4 format consists of one sign bit, three exponent bits, and four fraction bits. Both arithmetic units are implemented using SystemVerilog and verified using VCS and Verdi.

## FP8 Adder Simulation

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

## FP8 Multiplier Simulation

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

## Command Summary

| Task | Commands |
|---|---|
| FP8 Adder Simulation | `make clean` → `make adder_verdi` → `./simv` → `make waves_adder` |
| FP8 Multiplier Simulation | `make clean` → `make multiplier_verdi` → `./simv` → `make waves_multiplier` |
