variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "alchemyst"
}

variable "iii_version" {
  type    = string
  default = "v0.10.0"
}

variable "ssh_public_key" {
  type        = string
  description = "contents of ~/.ssh/id_rsa.pub"
}

variable "admin_cidr" {
  type        = string
  description = "your IP/32 for SSH access"
  default     = "0.0.0.0/0"
}

variable "repo_url" {
  type    = string
  default = "https://github.com/srinithiyadev/iii-aws-deployment.git"
}
