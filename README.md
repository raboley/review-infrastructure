# Review Infrastructure

When developing an application, things like kubernetes and infrastructure as code
have enabled developers to create ephemeral instances of their application,
show it to others and test out that the functionality makes sense in a production like environment
all before ever doing a code review or going through an approval process. For application
developers who want fast feedback from either other developers, business users or
other stakeholders this has been an extremely powerful tool to get feedback before
anything is code reviewed and merged. It also gives the developer confidence that
their change will work exactly the way they expect after it is merged to trunk and
deployed in production.

This article brings that concept up a level to create review infrastructure. That means that the same
workflow enabled for software engineers, is enabled for infrastructure engineers. The workflow will be

1. Branch off main
1. make changes and create a Pull Request back to main
1. View results of PR validation build, see review infrastructure spin up
1. Have someone code review your change
1. Merge to main, see review infrastructure spin down

This repository example will show how to do that with an azure resource group using
terraform to spin up and spin down. 

## Local setup

1. Terraform version > 0.12 `brew install terraform`
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
