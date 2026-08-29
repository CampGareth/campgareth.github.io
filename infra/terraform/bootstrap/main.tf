# ---------------------------------------------------------------------------
# Bootstrap: the S3 bucket that stores Terraform remote state.
#
# This is a chicken-and-egg problem: the main stack keeps its state in S3, but
# something has to create that bucket first. So this tiny stack uses LOCAL state
# (there's almost nothing here, and it rarely changes) to create the state
# bucket. Run this once, then the main stack's S3 backend points at it.
#
#   cd infra/terraform/bootstrap
#   terraform init && terraform apply
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Local state on purpose — see the header comment.
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  default     = "eu-west-2" # London
  description = "Region for the Terraform state bucket."
}

variable "state_bucket_name" {
  type        = string
  default     = "campgareth-tfstate"
  description = "Globally-unique name for the S3 bucket that holds Terraform state."
}

resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name

  # State files can contain sensitive values and must never be lost — keep the
  # bucket even if `terraform destroy` is run against it by accident.
  lifecycle {
    prevent_destroy = true
  }
}

# Versioning lets us recover a previous state file if an apply goes wrong.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt state at rest.
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# State is private, always. No public access under any circumstances.
resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "state_bucket_name" {
  value       = aws_s3_bucket.state.id
  description = "Put this in the main stack's backend \"s3\" { bucket = ... } block."
}
