All Terragrunt configurations live here. To edit Terraform files, go to `../modules`.

# Summary
The Terragrunt configurations manage the actual environments and, in principle, should reflect the current state of the given environment.

# Development
As a developer, you should create your own environment, separated from the others. In this directory, execute `make environment`, which will create one for you. Do not work on the `dev` environment directly, as others may also be working on it.

```
❯ make create-environment
Environment: dev-7zryf85r. Happy hacking!
```

Inside the specific application in the environment, run:
```
❯ terragrunt plan
```
This command will show you the resources to be changed/created/destroyed.

```
❯ terragrunt apply
```

After ensuring the changes work correctly, merge the changes from your development environment to the base one and, possibly, `prod`.

Remember to clean up your environment. Use `terragrunt destroy` or use `make destroy-dev`. Refer to the [Makefile](./Makefile) for details.


# Conventions

## Environments

There is no notion of a `staging` environment, though one may be introduced in the future.

```
.
├── dev          # Development environment template for custom environments.
├── dev-<random> # Personal development environment
└── prod         # Production environment. It should reflect reality.
```

The `prod` environment should be deployed only by GH workers and not manually.

Each environment contains its respective `applications/`. A `base-infrastructure` may be created to denote resources shared between applications. Each application should include a single `terragrunt.hcl` file which only sets its configuration and, optionally, defines dependencies. The application code itself should be defined in `../modules`.


```
└── applications
    ├── snapshot-monitoring
    │   └── terragrunt.hcl
    ├── snapshot-service
    │   └── terragrunt.hcl
    └── sync-check
        └── terragrunt.hcl
```

The difference between a `prod` and a `dev` application should be minimal. This would include a different Slack notification channel (already handled by the root `terragrunt.hcl`) or using larger instances for the `prod` environment.

## Tags

Everywhere where it's applicable, the resources should include the following tags:
- `iac` - indicates the resource is governed by Terraform and should not be mutated outside of the infrastructure code,
- `<environment-name>` - indicates the environment name.

# Secrets

Several secrets need to be defined and provided for the services to work. You can find them in the team's password manager. Each service defines its own set of required variables, though all need access to DigitalOcean. See the modules' documentation for more details.

```
#################################
### Required for all services ###
#################################
# DigitalOcean personal access token: https://cloud.digitalocean.com/account/api/tokens
export TF_VAR_digitalocean_token=

# S3 access keys used by Terraform for the remote state.
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=

#################################
####### Service-specific ########
#################################

# Required for services with Slack notifications
export TF_VAR_slack_token=

# Required for access to Cloudflare R2
export TF_VAR_R2_ACCESS_KEY=
export TF_VAR_R2_SECRET_KEY=

# Required if NewRelic monitoring/alerting is enabled.
export TF_VAR_new_relic_api_key=
export TF_VAR_new_relic_account_id=
```
