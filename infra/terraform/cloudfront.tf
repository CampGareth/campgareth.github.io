# ---------------------------------------------------------------------------
# CloudFront: the public front door. It terminates TLS, serves globally from
# edge caches, and reads privately from S3 via Origin Access Control (OAC).
# ---------------------------------------------------------------------------

# OAC is how CloudFront authenticates to the private S3 bucket. It replaces the
# older Origin Access Identity (OAI) and uses SigV4 request signing.
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = local.content_bucket_name
  description                       = "OAC for ${local.apex_domain}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# The viewer-request function (see cloudfront_function.js.tftpl).
resource "aws_cloudfront_function" "rewrite" {
  name    = "${var.site_name}-viewer-request"
  runtime = "cloudfront-js-2.0"
  comment = "www->apex redirect and directory-index rewrite"
  publish = true
  code = templatefile("${path.module}/cloudfront_function.js.tftpl", {
    domain_name = local.apex_domain
  })
}

# Sensible security headers applied to every response, so we don't have to bake
# them into the site. HSTS tells browsers to always use HTTPS for this domain.
resource "aws_cloudfront_response_headers_policy" "security" {
  name = "${var.site_name}-security-headers"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000 # 1 year
      include_subdomains         = false    # you run other subdomains; don't force them
      preload                    = false
      override                   = true
    }
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = local.apex_domain
  default_root_object = "index.html"
  price_class         = var.cloudfront_price_class
  aliases             = [local.apex_domain, local.www_domain]
  tags                = local.tags

  origin {
    origin_id                = "s3-content"
    domain_name              = aws_s3_bucket.content.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-content"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # AWS-managed "CachingOptimized" policy id — good defaults for static sites.
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.rewrite.arn
    }
  }

  # Serve the Jekyll 404 page (with a real 404 status) for missing objects.
  custom_error_response {
    error_code            = 403 # S3/OAC returns 403 for missing keys
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 60
  }
  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 60
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.site.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# Bucket policy: allow ONLY this distribution to read objects. This is what makes
# the private bucket reachable through CloudFront and nothing else.
data "aws_iam_policy_document" "content_bucket" {
  statement {
    sid       = "AllowCloudFrontOACRead"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.content.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "content" {
  bucket = aws_s3_bucket.content.id
  policy = data.aws_iam_policy_document.content_bucket.json
}
