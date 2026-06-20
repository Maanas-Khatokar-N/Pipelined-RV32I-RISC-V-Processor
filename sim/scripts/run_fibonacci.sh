#!/bin/bash

echo ""
echo "================================"
echo "Running Fibonacci Test"
echo "================================"
echo ""

# Go to repo root from sim/scripts
cd ../..

# Create output folders
mkdir -p sim/build
mkdir -p sim/waveforms

# Compile RTL + Fibonacci testbench
iverilog -Wall -o sim/build/fibonacci.vvp \
rtl/core/*.v \
rtl/pipeline/hazard/*.v \
rtl/pipeline/registers/*.v \
rtl/pipeline/stages/*.v \
rtl/pipeline/*.v \
tb/programs/fibonacci_pipelined_tb.v

# Stop if compilation fails
if [ $? -ne 0 ]; then
    echo ""
    echo "Compilation failed."
    exit 1
fi

# Run simulation
vvp sim/build/fibonacci.vvp

echo ""
echo "Fibonacci simulation completed."
echo ""