// https://www.terraform.io/docs/providers/azuredevops/index.html

provider "azuredevops" {
#   version = ">= 0.0.1"
  
  //// sourced from env
  // org_service_url 
  // sourced from AZDO_ORG_SERVICE_URL
  
  // personal_access_token
  // sourced from AZDO_PERSONAL_ACCESS_TOKEN
}

resource "azuredevops_project" "i" {
  project_name       = "tf-generated-project"
  description        = "Project generated via Terraform"
}

//resource "azuredevops_git_repository" "i" {
//  project_id = azuredevops_project.i.id
//  name       = "Sample-Empty-Git-Repository"
//
//  initialization {
//    init_type = "Import"
//    source_type = "GitHub"
//    source_url = "https://github.com/terraform-providers/terraform-provider-azuredevops.git" //data.azuredevops_git_repositories.tf_azure_devops.repositories[0].remote_url
//  }
//}

data "azuredevops_project" "learning" {
    project_name = "Learning"
}

data "azuredevops_git_repositories" "tf_azure_devops" {
  project_id = data.azuredevops_project.learning.id
  name       = "tf-azure-devops"
}

resource "azuredevops_build_definition" "b" {
  project_id = azuredevops_project.i.id
  name       = "Sample Build Definition"

  repository {
    repo_type = "TfsGit"
    repo_id   = data.azuredevops_git_repositories.tf_azure_devops.repositories[0].id
    yml_path  = "azure-pipelines.yml"
  }
}

//resource "azuredevops_branch_policy_build_validation" "i" {
//  project_id = azuredevops_project.i.id
//  settings {
//    build_definition_id = 0
//    display_name = ""
//    scope {}
//  }
//}

# resource "azuredevops_git_repository" "repo" {
#   project_id = azuredevops_project.i.id
#   name       = "Sample Fork an Existing Repository"
#   parent_id  = data.azuredevops_git_repositories.tf_azure_devops
#   is_fork = true
# }
