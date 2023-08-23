# Define variables for Terraform
TF      = terraform
TF_MAIN_DIR  = forest-mainnet
TF_CALIB_DIR = forest-calibnet
TF_LT_MAIN_DIR = lotus-mainnet

# Define the default target
.DEFAULT_GOAL := help

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  init_calib, init_main, or init_lt_main                  Initialize Terraform for either Forest mainnet, calibnet, or lotus mainnet"
	@echo "  plan_calib, plan_main, or plan_lt_main                  Generate and show an execution plan for either Forest mainnet, calibnet, or lotus mainnet"
	@echo "  apply_main, apply_calib, or apply_lt_main               Apply the changes for either Forest mainnet, calibnet, or lotus mainnet"
	@echo "  destroy_main, destroy_calib or destroy_lt_main          Destroy the Terraform-managed infrastructure for either Forest mainnet, calibnet, or lotus mainnet"
	@echo "  help                                                    Shows this help message"

init_calib:
	@cd $(TF_CALIB_DIR) && $(TF) init

plan_calib:
	@cd $(TF_CALIB_DIR) && $(TF) plan

apply_calib:
	@cd $(TF_CALIB_DIR) && $(TF) apply --auto-approve

destroy_calib:
	@cd $(TF_CALIB_DIR) && $(TF) destroy

init_main:
	@cd $(TF_MAIN_DIR) && $(TF) init

plan_main:
	@cd $(TF_MAIN_DIR) && $(TF) plan

apply_main:
	@cd $(TF_MAIN_DIR) && $(TF) apply --auto-approve

destroy_main:
	@cd $(TF_MAIN_DIR) && $(TF) destroy

init_lt_main:
	@cd $(TF_LT_MAIN_DIR) && $(TF) init

plan_lt_main:
	@cd $(TF_LT_MAIN_DIR) && $(TF) plan

apply_lt_main:
	@cd $(TF_LT_MAIN_DIR) && $(TF) apply --auto-approve

destroy_lt_main:
	@cd $(TF_LT_MAIN_DIR) && $(TF) destroy

