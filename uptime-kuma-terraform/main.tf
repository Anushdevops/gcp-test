data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter { name = "name" values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"] }
  filter { name = "architecture" values = ["x86_64"] }
  filter { name = "root-device-type" values = ["ebs"] }
  filter { name = "virtualization-type" values = ["hvm"] }
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.project_name}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.this.id
  cidr_block = var.public_subnet_cidr
  availability_zone = var.availability_zone != "" ? var.availability_zone : data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "${var.project_name}-public" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route { cidr_block = "0.0.0.0/0" gateway_id = aws_internet_gateway.this.id }
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_security_group" "server" {
  name = "${var.project_name}-sg"
  description = "Jenkins SonarQube Uptime Kuma webhook"
  vpc_id = aws_vpc.this.id
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.server.id
  cidr_ipv4 = var.admin_cidr
  from_port = 22
  to_port = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "jenkins" {
  security_group_id = aws_security_group.server.id
  cidr_ipv4 = var.jenkins_cidr
  from_port = 8080
  to_port = 8080
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "sonar" {
  security_group_id = aws_security_group.server.id
  cidr_ipv4 = var.sonarqube_cidr
  from_port = 9000
  to_port = 9000
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "kuma" {
  security_group_id = aws_security_group.server.id
  cidr_ipv4 = var.uptime_kuma_cidr
  from_port = 3001
  to_port = 3001
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "webhook" {
  count = var.webhook_cidr == "" ? 0 : 1
  security_group_id = aws_security_group.server.id
  cidr_ipv4 = var.webhook_cidr
  from_port = 5000
  to_port = 5000
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.server.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_instance" "server" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.public.id
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.server.id]
  iam_instance_profile = aws_iam_instance_profile.ec2.name

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    project_name = var.project_name
    git_repository = var.git_repository
    git_branch = var.git_branch
    dockerhub_username = var.dockerhub_username
    dockerhub_token = var.dockerhub_token
    dockerhub_repository = var.dockerhub_repository
    twilio_account_sid = var.twilio_account_sid
    twilio_auth_token = var.twilio_auth_token
    twilio_from_number = var.twilio_from_number
    twilio_to_numbers = join(",", var.twilio_to_numbers)
    sonarqube_image = var.sonarqube_image
    uptime_kuma_image = var.uptime_kuma_image
  })

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"
  }

  tags = { Name = "${var.project_name}-server" }
}

resource "aws_eip" "server" {
  domain = "vpc"
  tags = { Name = "${var.project_name}-eip" }
}

resource "aws_eip_association" "server" {
  instance_id = aws_instance.server.id
  allocation_id = aws_eip.server.id
}
