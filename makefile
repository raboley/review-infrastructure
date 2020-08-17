setup:
	ln -s -f ../../.pre-commit.sh .git/hooks/pre-commit
	. ./scripts/install-pdd.sh
	az login
	#initialize terraform workspace
	terraform login
	cd terraform && terraform init
	#Install envsubst for macos
	brew install gettext
	brew link --force gettext
	brew install jq
	export environment="dev"
	export TERRAFORM_CLOUD_TOKEN=$(cat ~/.terraform.d/credentials.tfrc.json | jq '.credentials."app.terraform.io".token')
	. .github/actions/envsubst-backend-hcl.sh
	. .github/actions/envsubst-auto-tfvars.sh
	# installing rab for easy pipeline secret additions
	brew install libsodium
	go get github.com/raboley/rab

init:
	cd terraform && terraform init --backend-config=backend.hcl

plan:
	cd terraform && terraform plan

apply:
	cd terraform && terraform apply --auto-approve

destroy:
	cd terraform && terraform destroy --auto-approve

pdd:
	ln -s -f ../../.pre-commit.sh .git/hooks/pre-commit
	. ./scripts/install-pdd.sh

serve-docs:
	go-slate server docs localhost:8080 --monitor-changes