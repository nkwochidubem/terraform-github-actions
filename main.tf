terraform {

  # backend "remote" {
  #   organization = "nkwochidubem"
  #   workspaces {
  #     name = "playground-workspace"
  #   }
  # }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.12.1"
    }
  }

  required_version = ">= 1.2.0"
}



#Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

#Create EC2 Instance
resource "aws_instance" "instance1" {
  ami                    = "ami-04581fbf744a7d11f"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  tags = {
    Name = var.instance_name
  }

  #Bootstrap Jenkins installation and start  
  user_data = <<-EOF
  #!/bin/bash
  sudo yum update -y
  sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
  sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
  sudo yum upgrade
  sudo amazon-linux-extras install java-openjdk11 -y
  sudo yum install jenkins -y
  sudo systemctl enable jenkins
  sudo systemctl start jenkins
  
  
  EOF

  user_data_replace_on_change = true
}

#Create security group 
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "Open ports 22, 8080, and 443"

  #Allow incoming TCP requests on port 22 from any IP
  ingress {
    description = "Incoming SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow incoming TCP requests on port 8080 from any IP
  ingress {
    description = "Incoming 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow incoming TCP requests on port 443 from any IP


  ingress {
    description = "Incoming 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins_sg"
  }
}

#Create S3 bucket for Jenkins artifacts
resource "aws_s3_bucket" "jenkins-artifacts" {
  bucket = "jenkins-artifacts-${random_id.randomness.hex}"

  tags = {
    Name = "jenkins_artifacts"
  }
}

#Make S3 bucket private
resource "aws_s3_bucket_acl" "private_bucket" {
  bucket = aws_s3_bucket.jenkins-artifacts.id
  acl    = "private"
}

#Create random number for S3 bucket name
resource "random_id" "randomness" {
  byte_length = 16
}