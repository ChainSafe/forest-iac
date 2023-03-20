init:
	@terraform init

plan:
	@terraform plan -var="digitalocean_token=$DIGITALOCEAN_TOKEN"
apply:
	@terraform apply --auto-approve -var="digitalocean_token=$DIGITALOCEAN_TOKEN"

destroy:
	@terraform destroy -var="digitalocean_token=$DIGITALOCEAN_TOKEN"
