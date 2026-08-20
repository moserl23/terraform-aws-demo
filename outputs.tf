output "aws_account_id" {
  description = "AWS account ID returned by the aws_caller_identity data source."
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS region currently used by the AWS provider."
  value       = data.aws_region.current.region
}

output "bucket_name" {
  description = "Name of the S3 bucket created by Terraform."
  value       = aws_s3_bucket.demo.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket created by Terraform."
  value       = aws_s3_bucket.demo.arn
}

output "bucket_region" {
  description = "Region where the demo bucket is managed."
  value       = data.aws_region.current.region
}

output "bucket_versioning_status" {
  description = "Versioning state configured for the demo bucket."
  value       = aws_s3_bucket_versioning.demo.versioning_configuration[0].status
}

output "demo_object_s3_uri" {
  description = "S3 URI of the small text object uploaded by Terraform."
  value       = "s3://${aws_s3_bucket.demo.bucket}/${aws_s3_object.hello.key}"
}
