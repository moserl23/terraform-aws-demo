# Terraform S3 + EC2 Demo

Tiny AWS data-processing demo for interview preparation.

```text
Terraform
   |
   v
Private S3 bucket
   |
   v
EC2 instance with IAM role
```

## Architecture

Terraform creates a private S3 bucket and one small EC2 instance. The EC2 instance gets bucket access through an IAM role, runs a short `user_data` script, writes `raw/input.txt`, converts it to uppercase, and uploads `processed/output.txt`.

The EC2 instance has no inbound access. It uses the default VPC/subnet and outbound internet access only for package install and S3 upload.

## What Terraform Creates

- AWS provider configuration
- Private S3 bucket with public access blocked
- IAM role, IAM policy, and instance profile for EC2 S3 access
- Security group with no inbound rules
- One small EC2 instance, defaulting to `t3.micro`

The instance schedules an automatic shutdown after the script finishes. Still run `terraform destroy` when done to remove the bucket, IAM resources, security group, EC2 instance, and EBS disk.

## Usage

Initialize Terraform:

```bash
terraform init
```

Review the plan:

```bash
terraform plan
```

Create the demo:

```bash
terraform apply
```

## Verify

After apply, wait a few minutes for EC2 `user_data` to finish. Then check S3:

```bash
aws s3 ls s3://$(terraform output -raw bucket_name)/ --recursive
aws s3 cp s3://$(terraform output -raw bucket_name)/processed/output.txt -
```

Expected objects:

```text
raw/input.txt
processed/output.txt
```

## Cleanup

Destroy everything when finished:

```bash
terraform destroy
```
