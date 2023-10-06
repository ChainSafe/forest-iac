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
	@echo "  init_calib or init_main                Initialize Terraform for either Forest mainnet or calibnet"
	@echo "  plan_calib or plan_main            	Generate and show an execution plan for either Forest mainnet or calibnet"
	@echo "  apply_main or apply_calib              Apply the changes for either Forest mainnet or calibnet"
	@echo "  destroy_main or destroy_calib          Destroy the Terraform-managed infrastructure for either Forest mainnet or calibnet"
	@echo "  help                                   Shows this help message"

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
