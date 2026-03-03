#!/bin/bash

# This script runs in a container to scan Moveit2 using Fortify.

set -e

cd /opt/moveit2_ws

# Build and load environment variables
bash install/setup.sh
colcon build \
    --event-handlers desktop_notification- status- \
    --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=yes --parallel-workers 2
bash install/setup.sh

PATH=$PATH:/opt/Fortify/bin

# Initialize
sourceanalyzer -b moveit2_sast -clean

# Specify source codes written in Python
sourceanalyzer -b moveit2_sast -python-version 3 -python-path $PYTHONPATH \
    $(find ./src/moveit2 -name "*.py")
# Specify source codes written in C++
sourceanalyzer -b moveit2_sast build/compile_commands.json

# Analyze
echo "Start analysis"
sourceanalyzer -b moveit2_sast -scan -Xmx12G -D com.fortify.sca.rules.IsLibrary=true -sc classic -f /opt/results/moveit2_sast_result.fpr
echo "Finished analysis"
