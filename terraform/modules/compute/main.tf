resource "aws_key_pair" "this" {
  key_name   = "${var.project}-key"
  public_key = var.ssh_public_key
}

resource "aws_instance" "api_gateway" {
  ami                    = var.ami_id
  instance_type          = "t3.small"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.api_gateway_sg_id]
  key_name               = aws_key_pair.this.key_name

  user_data = templatefile("${path.module}/../../user_data/vm1_api_gateway.sh.tpl", {
    iii_version = var.iii_version
  })

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = { Name = "${var.project}-api-gateway", Role = "api-gateway" }
}

resource "aws_instance" "caller_worker" {
  ami                    = var.ami_id
  instance_type          = "t3.medium"
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.workers_sg_id]
  key_name               = aws_key_pair.this.key_name

  user_data = templatefile("${path.module}/../../user_data/vm2_caller_worker.sh.tpl", {
    engine_private_ip = aws_instance.api_gateway.private_ip
    repo_url          = var.repo_url
  })

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = { Name = "${var.project}-caller-worker", Role = "caller-worker" }

  depends_on = [aws_instance.api_gateway]
}

resource "aws_instance" "inference_worker" {
  ami                    = var.ami_id
  instance_type          = "t3.xlarge"
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.workers_sg_id]
  key_name               = aws_key_pair.this.key_name

  user_data = templatefile("${path.module}/../../user_data/vm3_inference_worker.sh.tpl", {
    engine_private_ip = aws_instance.api_gateway.private_ip
    repo_url          = var.repo_url
  })

  root_block_device {
    volume_size = 40
    volume_type = "gp3"
  }

  tags = { Name = "${var.project}-inference-worker", Role = "inference-worker" }

  depends_on = [aws_instance.api_gateway]
}
