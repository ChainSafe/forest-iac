# Terraform-managed

This directory contains services and assets managed via Terraform/Terragrunt.

# Structure

```
├── scripts # common code, shared between all modules
├── live    # actual environment definitions, managed by Terragrunt
└── modules # Terraform modules, from which the environment is built
```

# Requirements

### Software

* [terraform](https://developer.hashicorp.com/terraform/install),
* [terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)

For recommended versions, please refer to the [workflow file](../composite-action/terragrunt/action.yml).

### Secrets

Refer to [environment README](./live/README.md) or module-specific README.

# Adding new services

1. Create a Terraform module in [modules](./modules). A suggested structure of such a module is:
  * `main.tf` - the core resources around the service.
  * `variable.tf` - inputs to the module, e.g., enable Slack notifications.
  * `outputs.tf` - outputs of the module, e.g., created VPS IP.
  * `provider.tf` - `terraform` and `provider` blocks to keep the versioning in one place.
  * `service/` - directory with the actual service implementation.
  * Other files and directories based on needs, e.g., `monitoring` to generate monitoring resources.
Ensure that names in the module, when needed, contain the environment. This provides a basic level of separation.

2. Create a Terragrunt service in your own development environment and assert that it works correctly:
  * inside [live](./live), execute `make create-environment`. Go to that directory.
  * inside the `applications/`, create your `fancy-app` directory and a `terragrunt.hcl` file. There, you will invoke the created module with input variables.
  * run `terragrunt plan` to assert that all variables are set correctly and that the plan output matches your expectations,
  * run `terragrunt apply` to apply the plan.
  * perform necessary assertions (the resources are created, the server responds to requests, and monitoring outputs make sense).
  * if all is good, teardown the service with `terragrunt destroy`.

3. Copy the tested service to [dev](./live/environments/dev/applications) and to [prod](./live/environments/prod/applications). Remove your environment directory.

4. Make a PR!
