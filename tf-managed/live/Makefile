# Creates a new environment for development from the base one.
environment:
	$(eval export ENVIRONMENT=dev-$(shell cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1))
	@cp -r environments/dev environments/$(ENVIRONMENT)
	@echo "Environment: $(ENVIRONMENT). Happy hacking!"

.PHONY: environment
