#!/usr/bin/env bash
set -Eeuo pipefail
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
