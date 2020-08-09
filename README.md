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

this changes the init command to be

```shell script
terraform init -backend-config=backend.hcl
```

And we will want that file to be dynamically created, and not checked into source control

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

