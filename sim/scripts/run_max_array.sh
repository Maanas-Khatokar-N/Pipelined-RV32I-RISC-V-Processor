#!/bin/bash

echo ""
echo "================================"
echo "Running Max Array Test"
echo "================================"
echo ""

cd ../..

mkdir -p sim/build
mkdir -p sim/waveforms

iverilog -Wall -o sim/build/max_array.vvp \
rtl/core/*.v \
rtl/pipeline/hazard/*.v \
rtl/pipeline/registers/*.v \
rtl/pipeline/stages/*.v \
rtl/pipeline/*.v \
tb/programs/max_array_tb.v

if [ $? -ne 0 ]; then
    echo ""
    echo "Compilation failed."
    exit 1
fi

vvp sim/build/max_array.vvp

echo ""
echo "Max Array simulation completed."
echo ""