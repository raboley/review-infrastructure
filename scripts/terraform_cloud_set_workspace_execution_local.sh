#!/bin/bash

# set in env
# TERRAFORM_CLOUD_TOKEN=
# TERRAFORM_CLOUD_ORG_NAME="russellboley"
# TERRAFORM_CLOUD_WORKSPACE_NAME="local-rab-review-infrastructure"

curl \
  --header "Authorization: Bearer $TERRAFORM_CLOUD_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request PATCH \
  -d '{"data": { "type": "workspaces", "attributes": {"operations": false}}}' \
  "https://app.terraform.io/api/v2/organizations/$TERRAFORM_CLOUD_ORG_NAME/workspaces/$TERRAFORM_CLOUD_WORKSPACE_NAME"
