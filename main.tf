terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = "terraform-s3-ec2-demo"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  bucket_name = "tf-s3-ec2-demo-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
}

resource "aws_s3_bucket" "demo" {
  bucket        = local.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "demo" {
  bucket = aws_s3_bucket.demo.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "tf-s3-ec2-demo-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.demo.arn]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.demo.arn}/*"]
  }
}

resource "aws_iam_role_policy" "s3_access" {
  name   = "tf-s3-ec2-demo-s3-access"
  role   = aws_iam_role.ec2.id
  policy = data.aws_iam_policy_document.s3_access.json
}

resource "aws_iam_instance_profile" "ec2" {
  name = "tf-s3-ec2-demo-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_security_group" "ec2" {
  name        = "tf-s3-ec2-demo-sg"
  description = "No inbound access; outbound only for package install and S3 upload"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "processor" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2.name

  instance_initiated_shutdown_behavior = "stop"

  user_data = <<-EOF
#!/bin/bash
set -euxo pipefail

command -v aws >/dev/null 2>&1 || dnf install -y awscli || dnf install -y awscli-2

mkdir -p /tmp/demo/raw /tmp/demo/processed

cat > /tmp/demo/raw/input.txt <<'DATA'
hello terraform
hello aws
hello interview
DATA

tr '[:lower:]' '[:upper:]' < /tmp/demo/raw/input.txt > /tmp/demo/processed/output.txt

aws s3 cp /tmp/demo/raw/input.txt "s3://${aws_s3_bucket.demo.bucket}/raw/input.txt"
aws s3 cp /tmp/demo/processed/output.txt "s3://${aws_s3_bucket.demo.bucket}/processed/output.txt"

shutdown -h +10 "Terraform demo finished; stopping EC2 instance to reduce cost."
EOF

  tags = {
    Name = "tf-s3-ec2-demo-processor"
  }
}
