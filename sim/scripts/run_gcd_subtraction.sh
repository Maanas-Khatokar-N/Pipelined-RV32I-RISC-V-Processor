#!/bin/bash

echo ""
echo "================================"
echo "Running GCD Subtraction Test"
echo "================================"
echo ""

cd ../..

mkdir -p sim/build
mkdir -p sim/waveforms

iverilog -Wall -o sim/build/gcd_subtraction.vvp \
rtl/core/*.v \
rtl/pipeline/hazard/*.v \
rtl/pipeline/registers/*.v \
rtl/pipeline/stages/*.v \
rtl/pipeline/*.v \
tb/programs/gcd_subtraction_tb.v

if [ $? -ne 0 ]; then
    echo ""
    echo "Compilation failed."
    exit 1
fi

vvp sim/build/gcd_subtraction.vvp

echo ""
echo "GCD Subtraction simulation completed."
echo ""