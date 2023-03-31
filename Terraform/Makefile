# Define variables for Terraform
TF      = terraform
TF_MAIN_DIR  = mainnet
TF_CALIB_DIR = calibnet

# Define the default target
.DEFAULT_GOAL := help

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  init      Initialize Terraform"
	@echo "  plan      Generate and show an execution plan"
	@echo "  apply     Apply the changes"
	@echo "  destroy   Destroy the Terraform-managed infrastructure"
	@echo "  help      Show this help message"

init_calib:
	@cd $(TF_CALIB_DIR) && $(TF) init

plan_calib:
	@cd $(TF_CALIB_DIR) && $(TF) plan --var-file="terraform.tfvars"

apply_calib:
	@cd $(TF_CALIB_DIR) && $(TF) apply --var-file="terraform.tfvars" --auto-approve

destroy_calib:
	@cd $(TF_CALIB_DIR) && $(TF) destroy  --var-file="terraform.tfvars"

init_main:
	@cd $(TF_MAIN_DIR) && $(TF) init

plan_main:
	@cd $(TF_MAIN_DIR) && $(TF) plan -var-file="terraform.tfvars"

apply_main:
	@cd $(TF_MAIN_DIR) && $(TF) apply -var-file="terraform.tfvars" --auto-approve

destroy_main:
	@cd $(TF_MAIN_DIR) && $(TF) destroy  --var-file="terraform.tfvars"
