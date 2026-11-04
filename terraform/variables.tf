
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing AWS key pair"
  type        = string
  default     = "cloudnative-key"
}

variable "ssh_cidr" {
  description = "Your public IP for SSH access"
  type        = string
  default     = "223.237.186.4/32"
}
