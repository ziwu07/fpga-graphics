#!/bin/sh
export FPGA_FAM=xc7
export F4PGA_INSTALL_DIR="$HOME/repos/f4pga"
export YOSYS_PREFIX="$CONDA_PREFIX"
export PATH="$HOME/repos/f4pga/xc7/conda/envs/xc7/bin:$PATH"
f4pga build -f flow.json "$@"
# https://storage.googleapis.com/symbiflow-arch-defs/artifacts/prod/foss-fpga-tools/symbiflow-arch-defs/continuous/install/20230411-180123/symbiflow-arch-defs-xc7a50t_test-5e974a8.tar.xz
# https://storage.googleapis.com/symbiflow-arch-defs/artifacts/prod/foss-fpga-tools/symbiflow-arch-defs/continuous/install/20230411-180123/symbiflow-arch-defs-install-xc7-5e974a8.tar.xz
