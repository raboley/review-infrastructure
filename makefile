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

docs:
	go-slate site docs/ build/