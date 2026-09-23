# GCP Jenkins VM Terraform Configuration

This Terraform configuration creates a Google Cloud Platform VM instance with Jenkins installed and accessible via ports 22 (SSH) and 8080 (HTTP).

## Prerequisites

1. [Terraform](https://www.terraform.io/downloads) installed (v1.0+)
2. [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed and authenticated
3. A GCP project with billing enabled
4. SSH key pair (default uses `~/.ssh/id_rsa.pub`)

## Usage

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and update the values:
   - `project_id`: Your GCP project ID
   - `region`: GCP region (e.g., us-central1)
   - `zone`: GCP zone (e.g., us-central1-a)
   - `prefix`: Optional prefix for resource names (default: jenkins)
   - `machine_type`: VM machine type (default: e2-medium)
   - `public_key_path`: Path to your public SSH key

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Review the planned changes:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

6. After successful apply, note the outputs:
   - Jenkins URL: Access Jenkins at `http://<EXTERNAL_IP>:8080`
   - SSH access: `ssh -i <PRIVATE_KEY> ubuntu@<EXTERNAL_IP>`

## Destroying Resources

To destroy all created resources:
```bash
terraform destroy
```

## Notes

- The VM uses Ubuntu 20.04 LTS as the base image
- Jenkins is installed via the official Debian package repository
- Firewall rules allow access to ports 22 and 8080 from any source (0.0.0.0/0)
- For production use, consider restricting the source IP ranges in the firewall rule