#!/bin/bash

echo ""
echo "================================"
echo "Running Forwarding Stress Test"
echo "================================"
echo ""

cd ../..

mkdir -p sim/build
mkdir -p sim/waveforms

iverilog -Wall -o sim/build/forwarding_stress.vvp \
rtl/core/*.v \
rtl/pipeline/hazard/*.v \
rtl/pipeline/registers/*.v \
rtl/pipeline/stages/*.v \
rtl/pipeline/*.v \
tb/programs/forwarding_stress_tb.v

if [ $? -ne 0 ]; then
    echo ""
    echo "Compilation failed."
    exit 1
fi

vvp sim/build/forwarding_stress.vvp

echo ""
echo "Forwarding Stress simulation completed."
echo ""