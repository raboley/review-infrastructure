---
title: API Reference

language_tabs: # must be one of https://git.io/vQNgJ
  - shell
  - powershell

toc_footers:
  - <a href='#'>Sign Up for a Developer Key</a>
  - <a href='https://github.com/lord/slate'>Documentation Powered by Slate</a>

includes:
  - errors

search: true
---

# Introduction

Review Infrastructure is a way of deploying and developing infrastrutuce as code, using gitops principals. 
The idea is that whenever something is merged to main branch it will be deployed through the path to production.
When someone needs to work on a feature, or make a change they would branch off main, make their change and then create a pull request
back to main which will stand up an isolated set of "review" infrastructure for testing and review purpose. Once the change has been validated, code reviewed
and passes all automated tests it will merge to main, destroy the review infrastructure and make updates to the infrastucture in the path to production.

By standing up isolated instances of infrastructure for each change we can ensure that no one makes breaking changes to infrastructure that is relied upon, 
and many engineers can work on the same infrastructure in parallel without breaking each other's infrastructure. We also get the added benefit of making infrastructure work follow the same workflow that modern software development teams use.

This is possible by dynamically naming infrastructure, and managing that infrastructure state with terraform cloud.

In this repo we use Azure resource groups as an example of how to achieve this.

The resource group is named using a prefix variable, so depending on if this is run off main branch, or during a PR, we can dynamically create new names for each
resource group so there is no collision.

We use terraform to deploy the infrastructure and terraform cloud to manage remote state. This allows us to generate new backend remote state files for each PR run, and maintain the 
main branch states all separately. Due to terraform cloud's state management we are able to update only what has changed for our given branch,
 and when we are done, know what needs to be cleaned up.
                                                                                                                                                      
That makes the workflow for infrastructure

branch -> change -> PR -> review -> merge

due to the review phase of the process creating live infrastructure that can be viewed, and tested it gives the code
review process a lot more tangible things to interact with. If this all sounds great then how do you do it? Next

We will see how to implement Review Infrastructure using Github Actions, and Terraform Cloud on Microsoft Azure.

# [Tutorial] Setting Up Review Infrastructure using Github Actions, Terraform Cloud and Microsoft Azure

At the end of this tutorial you will have a CI/CD pipeline setup using Github Actions that will deploy resource groups
for dev, prod and review branches with all state stored in separate state files on terraform cloud. This concept can easily
be expanded to azure functions, kubernetes, app service plans or even adapted for aws with minimal effort.

## Account Signups

First thing you will need to have is a [Microsoft Azure Subscription](https://azure.microsoft.com/en-us/resources/videos/sign-up-for-microsoft-azure/) you can use, and a [terraform cloud account](https://app.terraform.io/signup/account). You
can sign up for both for free on their respective websites.

## local desktop setup.

This tutorial will use the following technologies, and having them installed will be a pre-req:

* Azure cli 
* Terraform
* Github Actions
* Terraform Cloud

The aim of this repo isn't to be a 101 on any one of these tools, but to also provide enough context to allow someone
with little to no understanding to be successful at following this tutorial. Make sure you have installed the tools to the right.
This is written from a mac os perspective, but if you are using windows either try Windows Subsystem For Linux, or
toggle to the powershell tab.
 
if you have make installed you can just run `make setup` and it will take care of all pre-reqs on a mac machine.

```shell
# Install Azure cli
brew update && brew install azure-cli

# Install terraform
brew install terraform
```

```powershell
// Install Azure cli
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi

// Install Terraform
choco install terraform
```

Next you will want to authenticate with Terraform Cloud and Azure locally

```script
# Authenticate with Azure
az login

# Authenticate with Terraform Cloud
terraform login
```

When signing in with Azure make sure you select a subscription if you have multiple

```shell
subscription_name=<subscription name>
az account set --subscription=$subscription_name
```

```powershell
$subscription_name=<subscription name>
az account set --subscription=$subscription_name
```

## The Roadmap

There are a few pieces to get this to all work which we will tackle in this order.

1. Setup the terraform to create a resource group in azure with a local backend
1. Configure a dynamic Terraform Cloud Remote state backend
1. Create a Github Actions workflow for deploying the Terraform for a PR and for merges to trunk

### Setup Terraform to Create a Resource Group In Azure With a Local Terraform Backend

First step will be to create a folder for the terraform to reside in. Create a directory to store this project in, 
and then change directory into it and make a terraform folder.

```shell
mkdir my-review-infrastructure
cd my-review-infrastructure
git init

mkdir terraform
touch terraform/main.tf
git add .
git commit -m 'init'
```

That will create a new folder for terraform, and a main.tf file to start it and all this to git and commit it. 
Now with the new repository we will setup terraform to authenticate with Azure. By default if you have used
`az login` to authenticate with Azure, terraform will read your enviornment variables to authenticate with the terraform
provider.

Since you have already done that you can add the azurerm provider to main.tf

```terraform
# terraform/main.tf

provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.20.0"
  features {}
}
``` 

This will set it up so terraform knows to use azurerm to create azure resources. Next we will create the resource group,
by adding this resource block to the main.tf under the provider.

```terraform
# terraform/main.tf

resource "azurerm_resource_group" "i" {
  name     = "dev-infrastructure-rg"
  location = "West US"
}
```

we can now initialize, plan and apply the resource group in our subscription.

```script
cd terraform
terraform init
terraform plan
terraform apply
```

The plan should show terraform creating a new resource group called `dev-infrastructure-rg`
and terraform apply should actually create it. If that succeeds then terraform and azure are all setup correctly! Now we need
to make the environment at the beginning of the resource group dynamic, so it can change in each environment.

We can just create a variable in the main.tf file called environment, and replace that with where it says dev in
the resource group name of the terraform.

```terraform
# terraform/main.tf

variable "environment" {
  default = "dev"
}

resource "azurerm_resource_group" "i" {
  name     = "${environment}-infrastructure-rg"
  location = "West US"
}
```

That will give us the option to change the name of the resource group in our pipeline later. Running a `terraform plan`
we should see no changes since the default is the same as what we had hard coded earlier. Next we need to setup a remote
backend so our pipeline and us can use the same state. For that we will use a Terraform Cloud Workspace.

## Configure a Dynamic Terraform Cloud Remote State Backend

Remote state is how we can have multiple computers work with the same set of infrastructure without causing problems. To set
that up is pretty simple. We will use Terraform Cloud to create a workspace, and use a backend configuration file
to allow it to be dynamic later.

Add the remote backend in the main.tf file with an empty workspace delaration.

```terraform
# terraform/main.tf

terraform {
  required_version = "~> 0.12.0"

  backend "remote" {}
}
```

This sets two things:

1. Pins the required terraform version (as of writing there is a bug with dynamic backends in tf 0.13 so this is important)
1. Establishes the backend type of terraform to remote from the default of local.

That isn't quite enough to set it up, we need to create a workspace config file to define what the workspace name will be.
To do that create a file called backend.hcl in the terraform directory, and add it to the .gitignore. We don't want to
check this into source control because our pipeline will dynamically create this file.

```hcl
# terraform/backend.hcl

workspaces { name = "dev-infrastructure" }
hostname     = "app.terraform.io"
organization = "russellboley"
```

Make sure to substitute organization for your own terraform cloud organization, everything else can stay the same.

Once you have this static backend setup you can init terraform again with the new remote backend.

```script
# cd terraform
terraform init -backend-config=backend.hcl
```

It will ask you if you want to migrate the old state that was in this directory, and you can say yes.

Next if you try and say `terraform apply` you will get an error about authorizing terraform with azure! There are
multiple ways to fix this described next.

### Setting Up Terraform Cloud to use Local Execution Mode

This is because currently we are doing auth using environment variables produced from az login, which terraform cloud has no access to
since your terraform commands are now being run on a different machine. Essentially what happens is terraform zips up the 
terraform directory, and will use all the `.tf` and `auto.tfvars` in that directory to configure your terraform run.

There are a couple options to fix this issue.

1. Set the terraform cloud plan/apply execution mode to local
1. Update the Azure Terraform Provider block to take in service principal credentials as variables, and define them in an auto.tfvars file
1. Add the Azure credentials as secrets in the terraform cloud workspace

I chose to fix this by just setting remote execution mode to local, since this means plans and applys only use terraform cloud for
the remote state, and can use all the environment variables of the machine calling it. This has drawbacks at scale since you will run into
state locking issues if multiple people try to plan/apply using the same state, but for demo purposes this is fine.

To setup local execution mode you can go to the settings in the terraform cloud workspace and toggle the switch to local,
but that won't work once we are dynamically creating an arbitrary amount of workspaces, so I suggest taking advantage
of the terraform api. Running the command below after setting the environment variables indicated below will result
in it switching to local execution mode.

```shell
# set in env
# TERRAFORM_CLOUD_TOKEN=
# TERRAFORM_CLOUD_ORG_NAME="russellboley"
# TERRAFORM_CLOUD_WORKSPACE_NAME="dev-infrastructure"

curl \
  --header "Authorization: Bearer $TERRAFORM_CLOUD_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request PATCH \
  -d '{"data": { "type": "workspaces", "attributes": {"operations": false}}}' \
  "https://app.terraform.io/api/v2/organizations/$TERRAFORM_CLOUD_ORG_NAME/workspaces/$TERRAFORM_CLOUD_WORKSPACE_NAME"
```

The cloud token is what you copied and saved from the `terraform login` command, and if you forgot it you can 
check in the `credentials.tfrc.json` file for your account.


```shell
cat ~/.terraform.d/credentials.tfrc.json
```

The org name and workspace name should match what is in your `terraform/backend.hcl` file 

Now that it has been toggled to local execution mode you should be able to run terraform plan and apply with no problems.

```shell
terraform apply
```

## Create a Github Actions workflow for deploying Azure Infrastructure using Terraform

Deploying infrastructure on your desktop is cool, but you are never actually done until it is fully automated in a CI/CD pipeline.

Github has introduced Actions as their answer to other CI/CD pipeline tools, and it allows for a powerful framework, that
is free for open source projects.

To create our first pipeline we need to create it in the structure github expects. Any `.yml` file 
you place in `.github/workflows/` directory will be interpreted by github as a pipeline. Lets start by creating the
pipeline that will run when you merge code to main. Make the directory structure `.github/workflows` and then make a file
`terraform-deploy.yml`

```shell 
mkdir -p .github/workflows
touch .github/workflows/terraform-deploy.yml
``` 

In a workflow we will cover two major sections:

1. Triggers that will tell Github to start the pipeline
1. Actions it should take when the pipeline is triggered

First we will define the name of the pipeline and the triggers for it. We only want this to trigger when code is
pushed to trunk, in this case the main branch.

```yaml
name: Terraform Deploy
# This workflow is triggered on pushes to the repository.
on:
  push:
    branches:
      - main
```

Now we have our pipeline trigger squared away, we need to tell it what to do when it is triggered. The goal here
will be to run the same terraform init and apply we did locally on our desktop, but in our pipeline.

The first step will be to determine the kind of agent we want running this code, and then checkout our code.

```yaml
jobs:
  terraform:
    name: 'Terraform'
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
```

this will place us in the root directory of the repository for future commands and give us availability to everything
that is in our repo.

Next we need to setup our workspace with the correct version of terraform.

```yaml
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
        with:
          cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}
          # turn off the terraform wrapper since this breaks terratest
          terraform_wrapper: false
          terraform_version: 0.12.29
```

This step made by Hashicorp will install the version of terraform you specify, and add your terraform cloud 
token to the authentication
so that you can connect with terraform cloud.

To make this step work we need to add our terraform cloud token as a secret in github. To do that


# Authentication

> To authorize, use this code:

```ruby
require 'kittn'

api = Kittn::APIClient.authorize!('meowmeowmeow')
```

```python
import kittn

api = kittn.authorize('meowmeowmeow')
```

```shell
# With shell, you can just pass the correct header with each request
curl "api_endpoint_here"
  -H "Authorization: meowmeowmeow"
```

```javascript
const kittn = require('kittn');

let api = kittn.authorize('meowmeowmeow');
```

> Make sure to replace `meowmeowmeow` with your API key.

Kittn uses API keys to allow access to the API. You can register a new Kittn API key at our [developer portal](http://example.com/developers).

Kittn expects for the API key to be included in all API requests to the server in a header that looks like the following:

`Authorization: meowmeowmeow`

<aside class="notice">
You must replace <code>meowmeowmeow</code> with your personal API key.
</aside>

# Kittens

## Get All Kittens

```ruby
require 'kittn'

api = Kittn::APIClient.authorize!('meowmeowmeow')
api.kittens.get
```

```python
import kittn

api = kittn.authorize('meowmeowmeow')
api.kittens.get()
```

```shell
curl "http://example.com/api/kittens"
  -H "Authorization: meowmeowmeow"
```

```javascript
const kittn = require('kittn');

let api = kittn.authorize('meowmeowmeow');
let kittens = api.kittens.get();
```

> The above command returns JSON structured like this:

```json
[
  {
    "id": 1,
    "name": "Fluffums",
    "breed": "calico",
    "fluffiness": 6,
    "cuteness": 7
  },
  {
    "id": 2,
    "name": "Max",
    "breed": "unknown",
    "fluffiness": 5,
    "cuteness": 10
  }
]
```

This endpoint retrieves all kittens.

### HTTP Request

`GET http://example.com/api/kittens`

### Query Parameters

Parameter | Default | Description
--------- | ------- | -----------
include_cats | false | If set to true, the result will also include cats.
available | true | If set to false, the result will include kittens that have already been adopted.

<aside class="success">
Remember — a happy kitten is an authenticated kitten!
</aside>

## Get a Specific Kitten

```ruby
require 'kittn'

api = Kittn::APIClient.authorize!('meowmeowmeow')
api.kittens.get(2)
```

```python
import kittn

api = kittn.authorize('meowmeowmeow')
api.kittens.get(2)
```

```shell
curl "http://example.com/api/kittens/2"
  -H "Authorization: meowmeowmeow"
```

```javascript
const kittn = require('kittn');

let api = kittn.authorize('meowmeowmeow');
let max = api.kittens.get(2);
```

> The above command returns JSON structured like this:

```json
{
  "id": 2,
  "name": "Max",
  "breed": "unknown",
  "fluffiness": 5,
  "cuteness": 10
}
```

This endpoint retrieves a specific kitten.

<aside class="warning">Inside HTML code blocks like this one, you can't use Markdown, so use <code>&lt;code&gt;</code> blocks to denote code.</aside>

### HTTP Request

`GET http://example.com/kittens/<ID>`

### URL Parameters

Parameter | Description
--------- | -----------
ID | The ID of the kitten to retrieve

## Delete a Specific Kitten

```ruby
require 'kittn'

api = Kittn::APIClient.authorize!('meowmeowmeow')
api.kittens.delete(2)
```

```python
import kittn

api = kittn.authorize('meowmeowmeow')
api.kittens.delete(2)
```

```shell
curl "http://example.com/api/kittens/2"
  -X DELETE
  -H "Authorization: meowmeowmeow"
```

```javascript
const kittn = require('kittn');

let api = kittn.authorize('meowmeowmeow');
let max = api.kittens.delete(2);
```

> The above command returns JSON structured like this:

```json
{
  "id": 2,
  "deleted" : ":("
}
```

This endpoint deletes a specific kitten.

### HTTP Request

`DELETE http://example.com/kittens/<ID>`

### URL Parameters

Parameter | Description
--------- | -----------
ID | The ID of the kitten to delete

