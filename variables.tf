variable "aws_region" {
  description = "AWS region used for this demo."
  type        = string
  default     = "eu-north-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", var.aws_region)) && length(var.aws_region) <= 15
    error_message = "Use an AWS region name such as eu-north-1 or us-east-1."
  }
}

variable "project_name" {
  description = "Short lowercase project name used in tags and the S3 bucket name."
  type        = string
  default     = "terraform-aws-demo"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,22}[a-z0-9]$", var.project_name))
    error_message = "Use 3-24 characters: lowercase letters, numbers, and hyphens. Start and end with a letter or number."
  }
}

variable "environment" {
  description = "Short environment label used in names and tags."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,6}[a-z0-9]$", var.environment))
    error_message = "Use 2-8 characters: lowercase letters, numbers, and hyphens. Start and end with a letter or number."
  }
}

variable "enable_bucket_versioning" {
  description = "Whether to enable S3 versioning for the demo bucket. Disabled by default to keep cleanup simple."
  type        = bool
  default     = false
}

variable "extra_tags" {
  description = "Optional additional tags to add to the demo resources."
  type        = map(string)
  default     = {}
}
