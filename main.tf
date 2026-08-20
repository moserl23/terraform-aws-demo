data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # S3 bucket names are globally unique, so the account ID and region make the
  # demo name reusable across learners without adding another provider.
  bucket_name = "${local.name_prefix}-${data.aws_caller_identity.current.account_id}-${var.aws_region}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "Terraform AWS learning demo"
    },
    var.extra_tags
  )

  demo_object_content = <<-EOT
    Hello from Terraform.

    Project: ${var.project_name}
    Environment: ${var.environment}
    AWS account: ${data.aws_caller_identity.current.account_id}
    Region: ${data.aws_region.current.region}

    This object was created from Terraform configuration.
  EOT
}

resource "aws_s3_bucket" "demo" {
  bucket = local.bucket_name

  tags = merge(
    local.common_tags,
    {
      Name = local.bucket_name
    }
  )
}

resource "aws_s3_bucket_public_access_block" "demo" {
  bucket = aws_s3_bucket.demo.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id

  versioning_configuration {
    status = var.enable_bucket_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_object" "hello" {
  bucket       = aws_s3_bucket.demo.id
  key          = "hello-terraform.txt"
  content      = local.demo_object_content
  content_type = "text/plain"
  etag         = md5(local.demo_object_content)

  tags = local.common_tags
}
