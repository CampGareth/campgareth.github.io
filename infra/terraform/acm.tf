# ---------------------------------------------------------------------------
# TLS certificate for CloudFront. Must live in us-east-1 (a hard CloudFront
# requirement), hence the aliased provider. One cert covers both the apex and
# www; validation is done automatically via DNS records in Route 53.
# ---------------------------------------------------------------------------

resource "aws_acm_certificate" "site" {
  provider = aws.us_east_1

  domain_name               = local.apex_domain
  subject_alternative_names = [local.www_domain]
  validation_method         = "DNS"

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# One validation CNAME per name on the cert. for_each keeps this correct even if
# the two names ever share a validation record (AWS de-duplicates them).
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.site.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.primary.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# Blocks until the certificate is validated, so CloudFront won't try to use a
# cert that isn't ready yet.
resource "aws_acm_certificate_validation" "site" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}
