resource "aws_security_group" "api_gateway" {
  name        = "${var.project}-api-gateway-sg"
  description = "API Gateway VM"
  vpc_id      = var.vpc_id

  ingress {
    description = "iii HTTP engine - public API"
    from_port   = 3111
    to_port     = 3111
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "iii WebSocket - workers only"
    from_port   = 49134
    to_port     = 49134
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr]
  }

  ingress {
    description = "SSH admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-api-gateway-sg" }
}

resource "aws_security_group" "workers" {
  name        = "${var.project}-workers-sg"
  description = "Private workers - no internet inbound"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH via bastion (VM1 only)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.api_gateway.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-workers-sg" }
}
