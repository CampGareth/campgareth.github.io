# ---------------------------------------------------------------------------
# Content bucket. This holds the built site (_site/). It is PRIVATE: nobody
# reaches it directly. CloudFront reads from it via Origin Access Control (OAC),
# and the bucket policy below trusts only this one CloudFront distribution.
#
# This is the modern best practice — no public buckets, no static-website
# endpoint, no "block public access = off". The bucket is an implementation
# detail behind the CDN.
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "content" {
  bucket = local.content_bucket_name
  tags   = local.tags
}

# Versioning gives you a quick rollback if a bad deploy overwrites files.
resource "aws_s3_bucket_versioning" "content" {
  bucket = aws_s3_bucket.content.id
  versioning_configuration {
    status = "Enabled"
  }
}

# The deploy syncs with --delete, so every overwritten or removed file leaves a
# noncurrent version behind. Keep 30 days' worth for rollback, then let them go.
resource "aws_s3_bucket_lifecycle_configuration" "content" {
  bucket = aws_s3_bucket.content.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {} # all objects

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.content]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "content" {
  bucket = aws_s3_bucket.content.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# The whole point: this bucket is never public. CloudFront's OAC is the only
# reader (see the bucket policy in cloudfront.tf).
resource "aws_s3_bucket_public_access_block" "content" {
  bucket                  = aws_s3_bucket.content.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
