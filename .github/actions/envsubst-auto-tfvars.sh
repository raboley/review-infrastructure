#!/bin/bash
# ENV vars must be exported for this to pick them up
# just doing
# var=value
# Will not work
envsubst < "terraform/env.auto.tfvarstemplate" > "terraform/env.auto.tfvars"
