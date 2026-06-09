# 1D CNN Source Modifications

## RTL ASIC Compatibility

- Removed FPGA-only memory initialization assumptions from `Dual_Port_BRAM`.
- Added explicit reset handling for `Dual_Port_BRAM` read outputs.
- Added `RST` inputs to `Instruction_Memory`, `Weight_Bank_Memory`, `Bias_Bank_Memory`, and `Ping_Pong_FMAP_Bank_Memory`.
- Reset memory wrapper read-valid delay registers so valid outputs are deterministic after reset.
- Wired top-level `RST` from `CNN_1D_Core` into all memory wrappers.
- Reset `OUT_CH_counter_d4_r` and `OUT_CH_counter_d5_r` in `Controller`.
- Reworked controller address calculations to use explicit intermediate widths and explicit address slices.

## sky130hd SRAM Flow

- Added `flow/designs/src/1d_cnn_sky130hd/Dual_Port_BRAM_sram.v`.
- The sky130hd SRAM wrapper maps only `DWIDTH >= 64` logical `Dual_Port_BRAM` instances to tiled `sky130_sram_1rw1r_64x256_8` hard macros.
- The 64-bit instruction memory uses four depth banks of the 256-word SRAM macro.
- 16-bit weight, bias, ping, and pong memories now synthesize as logic to avoid a 68-SRAM macro floorplan.
- Set `SYNTH_MEMORY_MAX_BITS = 16384` in the sky130hd common config so one 1024x16 inferred logic memory is allowed by ORFS.
- The wrapper routes writes from either logical port to the macro RW port and reads from either logical port to the macro read-only port. This relies on the 1D CNN host/load, execute, and readback phases not issuing conflicting same-cycle accesses.
- Added `flow/designs/sky130hd/1d_cnn/pdn.tcl` to connect SRAM `vdd/gnd` pins and use a coarser PDN mesh.
- Added `flow/designs/sky130hd/1d_cnn/tapcell.tcl` with a relaxed tapcell distance for exploratory macro runs.

## sky130hd IO and Run Variants

- Added `flow/designs/sky130hd/1d_cnn/io.tcl`.
- The IO constraint script distributes non-clock top-level input/output pins round-robin across left, right, top, and bottom edges.
- Added `flow/designs/sky130hd/1d_cnn/config_common.mk` for shared source, macro, SDC, and IO setup.
- Kept `flow/designs/sky130hd/1d_cnn/config.mk` as the default balanced run.
- Added `config_area.mk` for area-oriented runs.
- Added `config_fmax.mk` for Fmax-oriented runs.
- Added `config_both.mk` as an explicit balanced area/timing run with a separate `DESIGN_NICKNAME`.
- Added area and Fmax SDC files with 150 ns and 20 ns clock periods, respectively.
- Updated the Fmax run to use a larger floorplan, lower placement density, ABC speed mode, a 20 ns SDC clock period, wider macro halos, and tighter timing-repair/CTS settings.

## Local Checks

- Passed RTL lint with:
  `verilator --lint-only --top-module CNN_1D_Core flow/designs/src/1d_cnn/*.v`
- Passed macro-backed lint with:
  `verilator --lint-only --timing -Wno-TIMESCALEMOD --top-module CNN_1D_Core ...`
- OpenROAD synthesis could not be run in this checkout because `tools/install/yosys/bin/yosys` is missing.
