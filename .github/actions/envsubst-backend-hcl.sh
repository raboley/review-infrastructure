#!/bin/bash
# ENV vars must be exported for this to pick them up
# just doing
# var=value
# Will not work
envsubst < "terraform/backend.hcltemplate" > "terraform/backend.hcl"
