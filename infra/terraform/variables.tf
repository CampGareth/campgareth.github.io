variable "aws_region" {
  type        = string
  default     = "eu-west-2" # London
  description = "Region for the content S3 bucket and IAM. (CloudFront is global; ACM is pinned to us-east-1 separately.)"
}

variable "domain_name" {
  type        = string
  default     = "campgareth.co.uk"
  description = "Apex domain. The site is served here; www.<domain> 301-redirects to it."
}

variable "site_name" {
  type        = string
  default     = "campgareth-blog"
  description = "Prefix for the content bucket name (account id is appended for uniqueness)."
}

variable "github_repo" {
  type        = string
  default     = "CampGareth/campgareth.github.io"
  description = "owner/repo allowed to assume the deploy role via OIDC."
}

variable "github_repository_id" {
  type        = string
  default     = "1084221805" # CampGareth/campgareth.github.io
  description = "Immutable numeric repo ID (gh api repos/OWNER/REPO --jq .id). Pinned alongside the name so a renamed or re-registered namespace can't assume the deploy role."
}

variable "github_branch" {
  type        = string
  default     = "main"
  description = "Branch allowed to deploy."
}

variable "create_github_oidc_provider" {
  type        = bool
  default     = true
  description = "Set false if an IAM OIDC provider for token.actions.githubusercontent.com already exists in this account (there can only be one)."
}

variable "cloudfront_price_class" {
  type        = string
  default     = "PriceClass_100" # NA + Europe — cheapest, fine for a UK blog
  description = "CloudFront price class (PriceClass_100 | PriceClass_200 | PriceClass_All)."
}
