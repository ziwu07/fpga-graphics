#!/bin/sh
export FPGA_FAM=xc7
export F4PGA_INSTALL_DIR="$HOME/repos/f4pga"
export YOSYS_PREFIX="$CONDA_PREFIX"
export PATH="$HOME/repos/f4pga/xc7/conda/envs/xc7/bin:$PATH"
f4pga build -f flow.json "$@"
