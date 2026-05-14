# Makefile for RISC-V Formal Verification Framework

# Variables
SBY ?= sby
FORMAL_DIR := ../formal
REPORTS_DIR := ../reports
COVERAGE_DIR := ../coverage
DEBUG_DIR := ../debug

.PHONY: all bmc prove clean regression setup report debug_trace

all: bmc prove report

setup:
	mkdir -p $(REPORTS_DIR)
	mkdir -p $(COVERAGE_DIR)
	mkdir -p $(DEBUG_DIR)

bmc: setup
	cd $(FORMAL_DIR) && $(SBY) -f rv32i_bmc.sby

prove: setup
	cd $(FORMAL_DIR) && $(SBY) -f rv32i_prove.sby

regression: setup
	python ../scripts/run_regression.py

report: setup
	@echo "========================================"
	@echo "    Formal Verification Report          "
	@echo "========================================"
	@cat $(REPORTS_DIR)/summary.txt || echo "Run 'make regression' first to generate report."
	@echo "========================================"

debug_trace:
	@echo "Opening GTKWave with trace..."
	# Usually sby produces traces in engine_*/trace.vcd.
	# Example: gtkwave ../formal/rv32i_bmc_dir/engine_0/trace.vcd
	gtkwave ../formal/rv32i_bmc_dir/engine_0/trace.vcd &

clean:
	rm -rf $(FORMAL_DIR)/rv32i_bmc_dir
	rm -rf $(FORMAL_DIR)/rv32i_prove_dir
	rm -rf $(REPORTS_DIR)/*
	rm -rf $(COVERAGE_DIR)/*
	rm -rf $(DEBUG_DIR)/*
