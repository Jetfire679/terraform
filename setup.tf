provider "aws" {
  region = "us-east-2"
}

provider "tls" {
}

#Create key-pair for logging into EC2 in us-east-1
resource "aws_key_pair" "webserver-key" {
  key_name   = "webserver-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

#Get Linux AMI ID using SSM Parameter endpoint in us-east-1
data "aws_ssm_parameter" "webserver-ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = join("-", [var.vApp, var.vEnv, "vpc"])
  cidr = "10.0.0.0/16"

  azs            = ["us-east-2a"]
  public_subnets = ["10.0.1.0/24"]

  # azs            = ["us-east-2a", "us-east-2b", "us-east-2c"]
  # public_subnets = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
  # private_subnets = ["10.0.10.0/24","10.0.20.0/24","10.0.30.0/24"]

  # enable_nat_gateway = true
  # enable_vpn_gateway = true

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

}

#Get all available AZ's in VPC for master region
data "aws_availability_zones" "azs" {
  state = "available"
}

#Create Dynamic SG using variables 
resource "aws_security_group" "sg" {
  name        = join("-", [var.vApp, var.vEnv, "sg"])
  description = "Allow TCP/80 & TCP/22"
  vpc_id      = module.vpc.vpc_id
  dynamic "ingress" {
    for_each = var.ec2-ingress-rules
    content {
      from_port   = ingress.value["port"]
      to_port     = ingress.value["port"]
      protocol    = ingress.value["proto"]
      cidr_blocks = ingress.value["cidr_blocks"]
    }
  }
  dynamic "egress" {
    for_each = var.ec2-egress-rules
    content {
      from_port   = egress.value["port"]
      to_port     = egress.value["port"]
      protocol    = egress.value["proto"]
      cidr_blocks = egress.value["cidr_blocks"]
    }
  }

  tags = {
    Name = join("-", [var.vApp, var.vEnv, "sg"])
  }
}

output "Webserver-Public-IP" {
  value = aws_instance.dockerserver.public_ip
}
