# GCP CI/CD Pipeline for Uptime-Kuma Monitoring

This Terraform configuration creates a Google Cloud Platform VM instance with a complete CI/CD pipeline setup for monitoring with Uptime-Kuma, based on the MrCloudBlog tutorial.

## What This Creates

A single VM instance (equivalent to AWS EC2 t2.large) with:
- Ubuntu 24.04 LTS
- 30 GB balanced persistent disk
- e2-medium machine type (2 vCPU, 4 GB RAM)

## Software Installed & Configured

### Via Startup Script:
1. **Java (Temurin 17)** - Required for Jenkins
2. **Jenkins** - CI/CD server (accessible on port 8080)
3. **Docker** - Container platform
4. **SonarQube** - Code quality analysis (running in Docker on port 9000)
5. **Trivy** - Vulnerability scanner
6. **Uptime-Kuma** - Self-hosted monitoring tool (running in Docker Compose on port 3001)
7. **Node.js 18** - For npm operations in CI/CD pipelines
8. **Python 3 & pip** - For webhook scripts

## Network Configuration

- VPC Network and Subnet (10.0.0.0/24)
- Firewall rule allowing inbound traffic on ports:
  - 22 (SSH)
  - 80 (HTTP)
  - 443 (HTTPS)
  - 8080 (Jenkins)
  - 9000 (SonarQube)
  - 3001 (Uptime-Kuma)
  - 5000 (Twilio webhook)

## Monitoring Setup

This configuration creates the foundation for a CI/CD pipeline that:
1. Uses Jenkins to build, test, and deploy applications
2. Uses SonarQube for code quality analysis
3. Uses Trivy for vulnerability scanning
4. Uses Docker for containerization
5. Uses Uptime-Kuma to monitor the deployed application
6. Can trigger Twilio voice calls via webhook when downtime is detected

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_id` | GCP project ID | - |
| `region` | GCP region | `us-central1` |
| `zone` | GCP zone | `us-central1-a` |
| `prefix` | Prefix for resource names | `uptimekuma` |
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
   - `vm_external_ip`: External IP address of the VM
   - `jenkins_url`: URL to access Jenkins web interface (http://EXTERNAL_IP:8080)
   - `sonarqube_url`: URL to access SonarQube (http://EXTERNAL_IP:9000)
   - `uptime_kuma_url`: URL to access Uptime-Kuma (http://EXTERNAL_IP:3001)
   - `ssh_command`: SSH command to connect to the VM

## Post-Deployment Steps

### 1. Access Jenkins
- Open browser to: http://[EXTERNAL_IP]:8080
- Retrieve initial admin password: Check VM serial console or SSH into VM and run: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
- Install suggested plugins
- Create admin user

### 2. Access SonarQube
- Open browser to: http://[EXTERNAL_IP]:9000
- Login with: admin/admin
- Change password immediately

### 3. Access Uptime-Kuma
- Open browser to: http://[EXTERNAL_IP]:3001
- Create your admin account on first visit

### 4. Configure Your CI/CD Pipeline
In Jenkins:
1. Install required plugins: 
   - Eclipse Temurin Installer
   - SonarQube Scanner
   - NodeJs Plugin
   - Docker-related plugins
   - Owasp Dependency Check
2. Configure Global Tools:
   - JDK 17
   - Node.js 18
   - SonarQube Scanner
3. Create credentials for:
   - Docker Hub
   - SonarQube token
4. Create a pipeline job using the pipeline script from the tutorial

### 5. Configure Monitoring
In Uptime-Kuma:
1. Add a monitor for your application (HTTP(s) on your deployed app's URL)
2. Configure notification settings
3. Set up Twilio webhook for voice call alerts (requires Twilio account)

## Destroying Resources

To destroy all created resources:
```bash
terraform destroy
```

## Notes

- The VM takes 3-5 minutes to fully initialize after startup
- All services are installed and started via the startup script
- SSH access is configured using the provided SSH public key
- Uses Docker containers for SonarQube and Uptime-Kuma for easy management
- The configuration is based on the MrCloudBlog tutorial but adapted for GCP
- For production use, consider:
  - More restrictive firewall rules
  - Separate VMs for different services
  - Managed services for databases (SonarQube requires PostgreSQL)
  - HTTPS termination with SSL certificates