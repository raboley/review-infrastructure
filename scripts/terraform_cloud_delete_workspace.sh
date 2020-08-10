#!/bin/bash

curl \
  --header "Authorization: Bearer $TERRAFORM_CLOUD_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request DELETE \
  "https://app.terraform.io/api/v2/organizations/$TERRAFORM_CLOUD_ORG_NAME/workspaces/$TERRAFORM_CLOUD_WORKSPACE_NAME"