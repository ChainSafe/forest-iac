init:
	@terraform init \
 	-backend-config="access_key=$SPACES_ACCESS_TOKEN" \
 	-backend-config="secret_key=$SPACES_SECRET_KEY" \
	-backend-config="bucket=$SPACE_BUCKET_NAME"

plan:
	@terraform plan -var-file="terraform.tfvars" 

apply:
	@terraform apply -var-file="terraform.tfvars" --auto-approve

destroy:
	@terraform destroy -var-file="terraform.tfvars" 