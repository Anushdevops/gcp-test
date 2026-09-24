# Uptime Kuma AWS DevSecOps — Terraform Automation

This project automates the AWS/EC2/Jenkins/Docker/SonarQube/Trivy/Uptime Kuma/Twilio-webhook flow described in the supplied source. The source calls for Ubuntu 24.04, t2.large, 30 GB storage, Jenkins, Docker, SonarQube, Trivy, a Jenkins pipeline, and a Twilio webhook. fileciteturn0file0L38-L51 fileciteturn0file0L100-L128

## Deploy

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Then:

```bash
terraform output
ssh -i YOUR_KEY.pem ubuntu@$(terraform output -raw public_ip)
sudo tail -f /var/log/uptime-kuma-bootstrap.log
```

The CI/CD stages follow the supplied pipeline: checkout, npm install, SonarQube, quality gate, OWASP dependency scan, Trivy filesystem scan, Docker build/push, Trivy image scan, and deployment. fileciteturn0file0L372-L449

## Components

- VPC + public subnet + Internet Gateway
- Ubuntu 24.04 EC2
- Elastic IP
- Jenkins :8080
- SonarQube :9000
- Uptime Kuma :3001
- Twilio webhook :5000
- Docker + Trivy + Node.js 18 + Java 17
- Jenkins plugin bootstrap
- Jenkinsfile
- Twilio Flask webhook container

## Security

The source explicitly warns that allowing all traffic from `0.0.0.0/0` is insecure. This project therefore uses configurable trusted CIDRs instead. fileciteturn0file0L70-L82

Do not commit `terraform.tfvars`, credentials, tokens, or private keys. For production, use AWS Secrets Manager/SSM and HTTPS behind an ALB/reverse proxy.

## Teardown

```bash
terraform destroy
```
