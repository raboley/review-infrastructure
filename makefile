init:
	cd terraform && terraform init

plan:
	cd terraform && terraform plan

apply:
	cd terraform && terraform apply --auto-approve

destroy:
	cd terraform && terraform destroy --auto-approve