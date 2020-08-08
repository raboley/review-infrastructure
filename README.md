# This repo manages azure devops via terraform

## What it should do

1. Create a repo
1. Add a build?
1. Add a branch policy on the build
1. Add service connection?

## Local setup

1. Terraform `brew install terraform`
1. make `brew install make`


provider info is sourced from env vars.
I am adding them to the .profile

```bash
# ~/.bash_profile
export AZDO_ORG_SERVICE_URL="https://dev.azure.com/RussellBoley"
export AZDO_PERSONAL_ACCESS_TOKEN="<TOKEN>"
```

initialize terraform

```bash
cd terraform
terraform init
```

create the resources

```bash
terraform plan
terraform apply
```

> If you get error personal access token required, ensure that your env contains the AZDO_PERSONAL_ACCESS_TOKEN env variable with the PAT token in it.
> if it is in your profile you may need to restart terminal or source the profile
> `source ~/.bash_profile`
