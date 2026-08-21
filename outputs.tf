output "bucket_name" {
  description = "S3 bucket used by the EC2 processor."
  value       = aws_s3_bucket.demo.bucket
}

output "raw_input_s3_uri" {
  description = "Expected raw input object."
  value       = "s3://${aws_s3_bucket.demo.bucket}/raw/input.txt"
}

output "processed_output_s3_uri" {
  description = "Expected processed output object."
  value       = "s3://${aws_s3_bucket.demo.bucket}/processed/output.txt"
}

output "ec2_instance_id" {
  description = "EC2 instance that runs the startup processing script."
  value       = aws_instance.processor.id
}
