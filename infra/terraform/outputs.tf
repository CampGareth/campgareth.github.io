# These feed the GitHub Actions workflow (set them as repo variables) and let you
# test the site via CloudFront before flipping DNS.

output "content_bucket_name" {
  value       = aws_s3_bucket.content.id
  description = "S3 bucket the site is deployed to. Repo variable: AWS_S3_BUCKET"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.site.id
  description = "Repo variable: AWS_CLOUDFRONT_DISTRIBUTION_ID"
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.site.domain_name
  description = "Test the site here (https://<this>) before DNS cutover."
}

output "deploy_role_arn" {
  value       = aws_iam_role.deploy.arn
  description = "Role GitHub Actions assumes. Repo variable: AWS_DEPLOY_ROLE_ARN"
}

output "aws_region" {
  value       = var.aws_region
  description = "Repo variable: AWS_REGION"
}
