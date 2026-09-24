# Uptime Kuma GCP DevSecOps - Complete Terraform

This project converts the supplied AWS-oriented Uptime Kuma CI/CD architecture to Google Cloud Platform.

## Creates

- Custom GCP VPC
- Regional subnet
- Cloud Router
- Static external IP
- Firewall rules for SSH, Jenkins, SonarQube, Uptime Kuma and webhook
- Dedicated Compute Engine service account
- Ubuntu 24.04 Compute Engine VM
- 30 GB balanced persistent disk
- Jenkins
- Java 17
- Docker Engine + Compose plugin
- Node.js 18
- Trivy
- SonarQube container
- Uptime Kuma container
- Twilio Flask/Gunicorn webhook container
- Jenkins pipeline
- Automated startup/bootstrap

The supplied source describes the original solution with Jenkins on 8080, SonarQube on 9000, Uptime Kuma on 3001, and the Twilio webhook on 5000. Those ports are retained here. fileciteturn0file0L100-L128 fileciteturn0file0L194-L204 fileciteturn0file0L593-L618

## Prerequisites

```bash
gcloud auth application-default login
gcloud auth login
gcloud config set project YOUR_GCP_PROJECT_ID
```

Your project must have billing enabled.

## First deployment

```bash
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars

terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Get URLs:

```bash
terraform output
```

SSH:

```bash
gcloud compute ssh uptime-kuma-devsecops --zone=asia-south1-a
```

Bootstrap logs:

```bash
sudo tail -f /var/log/uptime-kuma-bootstrap.log
```

## Required Terraform variables

```hcl
project_id = "your-gcp-project-id"
region     = "asia-south1"
zone       = "asia-south1-a"
```

For a safer deployment, set `allowed_admin_cidr`, `jenkins_cidr`, `sonarqube_cidr`, and `uptime_kuma_cidr` to your trusted public IP as `/32`.

## Optional secrets

The demo supports Docker Hub and Twilio values through Terraform variables, but secrets are stored in Terraform state when supplied this way.

For production, replace these variables with Secret Manager and grant the VM service account access to only the required secrets.

## Architecture

```text
                    Google Cloud
                         |
                  Custom VPC Network
                         |
                 Public Subnet
                         |
              External Static IP
                         |
              Compute Engine VM
                         |
       +-----------------+------------------+
       |                 |                  |
    Jenkins          SonarQube         Uptime Kuma
     :8080              :9000               :3001
       |                                     |
       +------------ CI/CD -----------------+
                                             |
                                       Webhook :5000
                                             |
                                           Twilio
                                             |
                                        Phone Alert
```

## CI/CD flow

```text
Git repository
      |
      v
   Jenkins
      |
      +--> npm install
      +--> SonarQube analysis
      +--> Quality Gate
      +--> OWASP Dependency Check
      +--> Trivy filesystem scan
      +--> Docker build
      +--> Trivy image scan
      +--> Docker push
      +--> Docker deployment
      |
      v
Application / Uptime Kuma
```

The pipeline stages mirror the supplied source pipeline. fileciteturn0file0L372-L449

## Uptime Kuma phone notification

After Uptime Kuma starts:

1. Open Uptime Kuma.
2. Configure your monitored service.
3. Add a Webhook notification.
4. Use:

```text
http://GCP_EXTERNAL_IP:5000/trigger-calls
```

5. Enable notification for the monitor.

The supplied source uses the same webhook concept: Uptime Kuma sends an alert to a Flask webhook, which uses Twilio to initiate calls. fileciteturn0file0L515-L618

## Security

Do not use `0.0.0.0/0` for SSH/Jenkins/SonarQube administration unless this is a disposable lab.

For production:

- Use HTTPS with a Google-managed certificate.
- Put public services behind a load balancer/reverse proxy.
- Restrict SSH.
- Use Secret Manager.
- Use OS Login/IAP instead of a publicly exposed SSH port where possible.
- Use Cloud Armor where appropriate.
- Separate Jenkins/SonarQube/Uptime Kuma into separate hosts or managed services if required.
- Use a remote Terraform backend such as GCS.

## Destroy

```bash
terraform destroy
```
