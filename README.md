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

## Setting up the infrastructure code

I am deliberately making this example super simple, because the scaffolding around it is
complicated enough, and once you understand the concepts it is easy to apply it to anything. I 
will likely make a pt 2 that will show how to implement this process for an aks cluster.

in the main.tf file we will setup: 

1. azure provider for terraform
1. create an azure resource group using a dynamic name
1. take in a var of prefix
1. output the resulting resource group name

running this locally will create a resource group called `main-review-infrastructure-rg`

```shell script
make apply
```

That is great for creating one resource group one time, but how does
the review stuff all work? For that we need to have multiple workspaces for terraform
to use so that it understands the difference between review, and main instances.

The easiest way to do this is to leverage Terraform Cloud

## Setting up Terraform Cloud

Terraform Cloud has the concept of workspaces, which allows you to store
terraform state in isolated areas and act upon it in a dynamic way. The way
we will use it for review infrastructure is to have one workspace for when this is run on
main branch, and then dynamically create new ones when this is done via a review branch.

you can login or create a free account on [Terraform Cloud](https://www.terraform.io/docs/cloud/index.html) which will
allow you to have up to 4 users and run tf cloud for free with no concurrent runs.

Once you have a Terraform cloud account you need to setup your local machine to be able to connect to Terraform Cloud via a token
stored on your computer, which can be obtained using the terraform cli

```shell script
terraform login
```

That will put your credentials in a place specific to your os that terraform
will be able to locate and authenticate with terraform cloud.

So next step is creating the backend workspace in terraform cloud that will house main branch's state which we just created 
with the tf apply.

because we want our backend to be dynamic, we will create a backend.hcl file
and then let terraform know in the main.tf file that we want it to use a remote backend.

And we will want that file to be dynamically created, and not checked into source control so adding
a file like backend.hcl will help with that

```hcl
# terraform/backend.hcl
workspaces { name = "local-rab-review-infrastructure" }
hostname     = "app.terraform.io"
organization = "russellboley"
```

this changes the init command to be

```shell script
terraform init -backend-config=backend.hcl
```

We can push our original state up to the workspace by saying yes
to the prompt.

Then we will need to remove the local state file because it will cause a problem
with tf cloud.

```shell script
rm -rf terraform/.terraform
rm -rf terraform/terraform.tfstate
rm -rf terraform/terraform.tfstate.backup
```

and now you can run apply again and see what happens.

```shell script
make init
make apply
```

> Error: Error building AzureRM Client: Azure CLI Authorization Profile was not found. Please ensure the Azure CLI is installed and then log-in with `az login`.

This happens because now that we are using terraform cloud for the remote state, it is also running our plans on their agent, which cannot
access environment variables.

to fix this we can set the workspace to run locally, instead of remote. This can be configured via the rest api for terraform cloud

```sh
# scripts/terraform_cloud_set_workspace_execution_local.sh

#!/bin/bash

# set in env
# TERRAFORM_CLOUD_TOKEN=
# TERRAFORM_CLOUD_ORG_NAME="russellboley"
# TERRAFORM_CLOUD_WORKSPACE_NAME="local-rab-review-infrastructure"

curl \
  --header "Authorization: Bearer $TERRAFORM_CLOUD_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request PATCH \
  -d '{"data": { "type": "workspaces", "attributes": {"operations": true}}}' \
  "https://app.terraform.io/api/v2/organizations/$TERRAFORM_CLOUD_ORG_NAME/workspaces/$TERRAFORM_CLOUD_WORKSPACE_NAME"

```

if you don't remember your terraform cloud token you pasted for the terraform login step you can get it from
your `~/.terraform.d/credentials.tfrc.json` file


I am going to suggest just putting these values in your profile so you don't forget

```shell script
# ~/.bash_profile

export TERRAFORM_CLOUD_TOKEN="<token>"
export TERRAFORM_CLOUD_ORG_NAME="russellboley"
export TERRAFORM_CLOUD_WORKSPACE_NAME="review-infrastructure-main"
```

then source the file so it is read in your terminal

```shell script
source ~/.bash_profile
```

finally you can update the workspace for local execution

```shell script
source scripts/terraform_cloud_set_workspace_execution_local.sh
```

and then running apply should work `make apply`

## Setup the pipeline

Since this is hosted on github we will use github actions. to create a github actions pipeline you create a directory structure 
following:

.github
└── workflows
    └── terraform-deploy.yml

using terraform deploy as the pipeline to create the infra.

It will basically need to login to terraform cloud, get credentials for azure and then apply the infrastructure changes.

you will need to add that token as a secret called `TF_API_TOKEN`

Since we want to use a non-interactive login for a ci/cd pipeline and we aren't hosting our own infrastrucute we will use
a service principal to authenticate with azure. That can be created following the [terraform provider for creating a service
principal and secret for auth](https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html)

```shell script
az ad sp create-for-rbac --role="Contributor" #--scopes="/subscriptions/SUBSCRIPTION_ID"
```

which will outupt a bunch of info, we care specifically about the appId, password, and tenant Id

make all of those secrets in github, which will be exported as env vars in the steps that use them
```shell script
$ export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
$ export ARM_CLIENT_SECRET="00000000-0000-0000-0000-000000000000"
$ export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
$ export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"
```

you will get all those via this list, but will still need the subscription ID, so you can get that via the command

```shell script
az account list
```

and then pick your subscription and the `id` field is your sub id.


then you finally add them as env vars to your task which should allow auth to still work since we are running
TF cloud runs locally instead of on remote agents.

```yaml
      - name: Terraform apply
        run: terraform apply --auto-approve
        working-directory: terraform
        env:
          ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
```

## Setup Review branches in the pipeline

Now it actually works, so it is about setting variables between PR and non-pr runs. PR runs should have review-pr# associated with them

https://github.com/actions/checkout/issues/58

if it is a pr we can get it through this

```shell script
pull_number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
```

## Setting up tests

An important part of CI/CD and modern programming in general is setting up tests. For this use case I will setup a very simple test
that checks the output for an appropriately named resource after everything has run.

# to-do do the tests with terratest

## Local setup

1. Terraform version > 0.12 `brew install terraform`
1. make `brew install make`
1. [azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos?view=azure-cli-latest) `brew update && brew install azure-cli`

## First time easy setup

The setup command steps will be run using

```shell script
make setup
```

The azure terraform provider can source credentials from the env which are set by running

```shell script
az login
```

> note you may need to set your tenant and/or subscription if you have multiple of either
> if you only have one don't worry about the commands underneath

```shell script
# Setting the particular tenant and subscription if you have multiple
az login --tenant <tenant id>
az account set --subscription <subscription id or name>
```

the provider info is sourced from the az login command, so ensure you have done that prior to setting up

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


# Deploy the infrastructure

# Everything as Code

