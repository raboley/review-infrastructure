hooks:
	ln -s -f scripts/.pre-commit.sh .git/hooks/pre-commit
setup:
	. ./scripts/install-pdd.sh
	az login
	terraform login
	cd terraform && terraform init

init:
	cd terraform && terraform init --backend-config=backend.hcl

plan:
	cd terraform && terraform plan

apply:
	cd terraform && terraform apply --auto-approve

destroy:
	cd terraform && terraform destroy --auto-approve