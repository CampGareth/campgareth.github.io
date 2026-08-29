# ---------------------------------------------------------------------------
# Route 53. The hosted zone for campgareth.co.uk already exists (you host other
# services on subdomains), so we look it up rather than create it. We only ADD
# records: alias records for the apex and www pointing at CloudFront. Your
# existing subdomain records are untouched and coexist fine — serving the apex
# via an ALIAS record is exactly how you point a zone root at a CDN without the
# "you can't CNAME an apex" problem.
# ---------------------------------------------------------------------------

data "aws_route53_zone" "primary" {
  name         = "${var.domain_name}."
  private_zone = false
}

# Apex (canonical): campgareth.co.uk -> CloudFront
resource "aws_route53_record" "apex_a" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = local.apex_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex_aaaa" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = local.apex_domain
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

# www -> CloudFront (the CloudFront function 301-redirects it to the apex).
resource "aws_route53_record" "www_a" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = local.www_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_aaaa" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = local.www_domain
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}
