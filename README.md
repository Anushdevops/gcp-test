# GCP Jenkins VM + Uptime-Kuma Monitoring Terraform Configuration

This Terraform configuration creates Google Cloud Platform VM instances for:
1. Jenkins CI/CD server
2. Uptime-Kuma monitoring server (to monitor Jenkins and other services)

## Resources Created

### Jenkins VM:
- VPC Network and Subnet
- Firewall Rule (allowing TCP ports 22, 8080 from 0.0.0.0/0)
- Compute Engine VM Instance with:
  - Debian GNU/Linux 11 boot disk (10 GB, balanced persistent disk)
  - Startup script that installs OpenJDK 11 and Jenkins
  - SSH key configuration for access
  - External IP address for public access

### Uptime-Kuma VM:
- Uses the same VPC Network and Subnet
- Additional Firewall Rule (allowing TCP ports 22, 80, 443, 3001 from 0.0.0.0/0)
- Compute Engine VM Instance with:
  - Debian GNU/Linux 11 boot disk (10 GB, balanced persistent disk)
  - Startup script that installs Docker and deploys Uptime-Kuma via Docker Compose
  - SSH key configuration for access
  - External IP address for public access

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_id` | GCP project ID | - |
| `region` | GCP region | `us-central1` |
| `zone` | GCP zone | `us-central1-a` |
| `prefix` | Prefix for resource names | `jenkins` |
| `machine_type` | Machine type for the VM instances | `e2-medium` |
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
   - `jenkins_vm_external_ip`: External IP address of the Jenkins VM
   - `jenkins_url`: URL to access Jenkins web interface (http://EXTERNAL_IP:8080)
   - `jenkins_ssh_command`: SSH command to connect to the Jenkins VM
   - `uptime_kuma_vm_external_ip`: External IP address of the Uptime-Kuma VM
   - `uptime_kuma_url`: URL to access Uptime-Kuma web interface (http://EXTERNAL_IP:3001)
   - `uptime_kuma_ssh_command`: SSH command to connect to the Uptime-Kuma VM

## Monitoring Setup with Uptime-Kuma

Uptime-Kuma is deployed to monitor your CI/CD pipeline and services:

1. **Access Uptime-Kuma**: Open a web browser and navigate to the Uptime-Kuma URL
2. **Initial Setup**: Create your admin account on first visit
3. **Add Monitoring Targets**:
   - **Jenkins CI/CD**: Monitor your Jenkins instance at `http://[JENKINS_IP]:8080`
   - **Other Services**: Add additional HTTP(s), TCP, or Ping monitors as needed
4. **Configure Notifications**: Set up alerts via email, Slack, Discord, etc. for real-time downtime notifications

## CI/CD Pipeline Monitoring

With this setup, you can:
- Monitor Jenkins server availability and response times
- Track build/deployment pipeline health
- Get real-time alerts when your CI/CD services go down
- Monitor other services in your infrastructure
- Create status pages for your team or customers

## Destroying Resources

To destroy all created resources:
```bash
terraform destroy
```

## Notes

- Both VMs will take a few minutes to fully initialize after startup
- Jenkins will be accessible on port 8080
- Uptime-Kuma will be accessible on port 3001
- SSH access is configured using the provided SSH public key
- All resources are tagged with the prefix for easy identification
- Uses Debian GNU/Linux 11 with 10 GB balanced persistent disks for both VMs