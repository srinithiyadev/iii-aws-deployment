terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "vpc" {
  source = "./modules/vpc"

  project             = var.project
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  az                  = "${var.aws_region}a"
}

module "security_groups" {
  source = "./modules/security-groups"

  project             = var.project
  vpc_id              = module.vpc.vpc_id
  private_subnet_cidr = module.vpc.private_subnet_cidr
  admin_cidr          = var.admin_cidr
}

module "compute" {
  source = "./modules/compute"

  project           = var.project
  ami_id            = data.aws_ami.al2023.id
  ssh_public_key    = var.ssh_public_key
  public_subnet_id  = module.vpc.public_subnet_id
  private_subnet_id = module.vpc.private_subnet_id
  api_gateway_sg_id = module.security_groups.api_gateway_sg_id
  workers_sg_id     = module.security_groups.workers_sg_id
  iii_version       = var.iii_version
  repo_url          = var.repo_url
}
