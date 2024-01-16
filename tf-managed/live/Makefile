# General-purpose Makefile for the managing the environments.

DEV_ENVIRONMENT_FILE=.dev_environment

# Creates a new environment. The name of the environment is generated
# randomly and stored in the .environment file.
${DEV_ENVIRONMENT_FILE}:
	$(eval export ENVIRONMENT=dev-$(shell cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1))
	@cp -r environments/dev environments/$(ENVIRONMENT)
	@echo "Environment: $(ENVIRONMENT). Happy hacking!"
	@echo $(ENVIRONMENT) > ${DEV_ENVIRONMENT_FILE}

# Creates a new environment.
create-environment: ${DEV_ENVIRONMENT_FILE}

# Deploys the entire development environment. Feel free to remove the
# services you don't need.
deploy-dev: ${DEV_ENVIRONMENT_FILE}
	$(eval export ENVIRONMENT=$(shell cat ${DEV_ENVIRONMENT_FILE}))
	@test -n "$(ENVIRONMENT)" || (echo "ENVIRONMENT is not set" && exit 1)
	@echo "Deploying $(ENVIRONMENT)..."
	@cd environments/$(ENVIRONMENT) && terragrunt run-all apply
	@echo "Environment $(ENVIRONMENT) deployed."

# Tears down the entire development environment and removes the
# environment directory.
destroy-dev: ${DEV_ENVIRONMENT_FILE}
	$(eval export ENVIRONMENT=$(shell cat ${DEV_ENVIRONMENT_FILE}))
	@test -n "$(ENVIRONMENT)" || (echo "ENVIRONMENT is not set" && exit 1)
	@echo "Destroying $(ENVIRONMENT)..."
	@cd environments/$(ENVIRONMENT) && terragrunt run-all destroy
	@rm -rf environments/$(ENVIRONMENT)
	@rm ${DEV_ENVIRONMENT_FILE}
	@echo "Environment $(ENVIRONMENT) destroyed."

# Deploys the entire production environment.
deploy-prod:
	@echo "Deploying to production..."
	cd environments/prod && terragrunt run-all apply

.PHONY: create-environment deploy-dev destroy-dev deploy-prod
