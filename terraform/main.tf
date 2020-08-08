// https://www.terraform.io/docs/providers/azuredevops/index.html

provider "azuredevops" {
  version = ">= 0.0.1"
  
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

