#!/bin/bash

echo ""
echo "================================"
echo "Running Array Sum Test"
echo "================================"
echo ""

cd ../..

mkdir -p sim/build
mkdir -p sim/waveforms

iverilog -Wall -o sim/build/array_sum.vvp \
rtl/core/*.v \
rtl/pipeline/hazard/*.v \
rtl/pipeline/registers/*.v \
rtl/pipeline/stages/*.v \
rtl/pipeline/*.v \
tb/programs/array_sum_tb.v

if [ $? -ne 0 ]; then
    echo ""
    echo "Compilation failed."
    exit 1
fi

vvp sim/build/array_sum.vvp

echo ""
echo "Array Sum simulation completed."
echo ""