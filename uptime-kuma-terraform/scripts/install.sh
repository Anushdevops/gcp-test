#!/usr/bin/env bash
set -Eeuo pipefail
terraform fmt -recursive
terraform init
terraform validate
terraform plan
terraform apply
