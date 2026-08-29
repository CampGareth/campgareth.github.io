# ---------------------------------------------------------------------------
# Providers, backend, and shared locals for the static-site stack.
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.10" # 1.10 added native S3 state locking (use_lockfile)

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Remote state in S3. No DynamoDB table needed: `use_lockfile` uses a small
  # lock object in the same bucket (Terraform >= 1.10) to prevent concurrent
  # applies. The bucket is created by ./bootstrap — these values must match its
  # output. NOTE: backend blocks can't use variables, so they're literals here.
  backend "s3" {
    bucket       = "campgareth-tfstate"
    key          = "static-site/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

# Default provider: the region the content bucket lives in.
provider "aws" {
  region = var.aws_region
}

# CloudFront requires its ACM certificate in us-east-1, regardless of where the
# rest of the infrastructure lives. This aliased provider is used only for ACM.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

locals {
  # Canonical host is the apex (campgareth.co.uk); www redirects to it.
  apex_domain = var.domain_name
  www_domain  = "www.${var.domain_name}"

  # Bucket names are globally unique; suffixing with the account id avoids
  # collisions without you having to invent a unique name.
  content_bucket_name = "${var.site_name}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Project   = "campgareth-blog"
    ManagedBy = "terraform"
  }
}
