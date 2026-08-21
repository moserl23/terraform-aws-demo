variable "aws_region" {
  description = "AWS region for this small demo."
  type        = string
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "Small EC2 instance type. t3.micro is free-tier eligible in many accounts/regions."
  type        = string
  default     = "t3.micro"
}
