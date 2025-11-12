provider "aws" {
  region = var.region
}

# Fetch default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch all subnets in default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# EC2 Instance
resource "aws_instance" "mysql_instance" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install docker python3 -y
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              docker run -d --name mysql -e MYSQL_ROOT_PASSWORD=root -p 3306:3306 mysql:latest
              EOF

  tags = {
    Name = "Terraform-MySQL"
  }
}
Security.tf
resource "aws_security_group" "mysql_sg" {
  name        = "allow_ssh_mysql"
  description = "Allow SSH and MySQL"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MySQL access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_mysql"
  }
}
  Variables.tf
variable "region" {
  default = "ap-south-1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "ami" {
  # Amazon Linux 2 AMI - ap-south-1
  default = "ami-071edcf66e251a763"
}

variable "key_name" {
  description = "Your AWS key pair name"
  type        = string
}
