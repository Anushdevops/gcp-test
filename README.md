# GCP Jenkins VM Terraform Configuration

This Terraform configuration creates a Google Cloud Platform VM instance with Jenkins installed and configured.

## Resources Created

- VPC Network
- Subnet
- Firewall Rule (allowing TCP ports 22 and 8080 from 0.0.0.0/0)
- Compute Engine VM Instance with:
  - Debian GNU/Linux 13 (trixie) boot disk (10 GB, balanced persistent disk)
  - Startup script that installs OpenJDK 11 and Jenkins
  - SSH key configuration for access
  - External IP address for public access

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_id` | GCP project ID | - |
| `region` | GCP region | `us-central1` |
| `zone` | GCP zone | `us-central1-a` |
| `prefix` | Prefix for resource names | `jenkins` |
| `machine_type` | Machine type for the VM instance | `e2-medium` |
| `ssh_public_key` | SSH public key for VM access | - |

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the configuration:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

4. After successful deployment, you'll get outputs:
   - `vm_external_ip`: External IP address of the Jenkins VM
   - `jenkins_url`: URL to access Jenkins web interface (http://EXTERNAL_IP:8080)
   - `ssh_command`: SSH command to connect to the VM

5. Access Jenkins:
   - Open a web browser and navigate to the Jenkins URL
   - The initial admin password will be displayed in the VM's serial console output or can be retrieved via SSH
   - Use the SSH command output to connect to the VM if needed

## Destroying Resources

To destroy all created resources:
```bash
terraform destroy
```

## Notes

- The VM will take a few minutes to fully install Jenkins after startup
- Jenkins will be accessible on port 8080 of the VM's external IP
- SSH access is configured using the provided SSH public key
- All resources are tagged with the prefix for easy identification
- Uses Debian GNU/Linux 13 (trixie) with 10 GB balanced persistent disk