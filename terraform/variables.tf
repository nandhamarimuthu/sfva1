variable "aws_region" {
  description = "AWS region for isolated sandbox testing"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "skyforge-fixture"
}

variable "enable_expensive_ec2" {
  description = "Enable the intentionally oversized EC2 resource. Keep false for static scanner testing."
  type        = bool
  default     = false
}
