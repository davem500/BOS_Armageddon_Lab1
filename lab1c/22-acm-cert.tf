
############################################
# ACM Certificate (TLS) for app.bos-growl.com
############################################

# Explanation: TLS is the diplomatic passport — browsers trust you, and bos stops growling at plaintext.
resource "aws_acm_certificate" "larrryharrisaws_cert" {
  domain_name       = local.bos_fqdn
  validation_method = var.certificate_validation_method

  # TODO: students can add subject_alternative_names like var.domain_name if desired

  tags = {
    Name = "larrryharrisaws76-cert"
  }
}

# Explanation: DNS validation records are the “prove you own the planet” ritual — Route53 makes this elegant.
# TODO: students implement aws_route53_record(s) if they manage DNS in Route53.
# resource "aws_route53_record" "bos_acm_validation" { ... }

# Explanation: Once validated, ACM becomes the “green checkmark” — until then, ALB HTTPS won’t work.
# 3. Create the validation CNAME records automatically
resource "aws_route53_record" "larrryharrisaws_acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.larrryharrisaws_cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = "Z0825167K1N04S2RCG6V"
}

# 4. Waiter that blocks until ACM validates and issues the certificate
resource "aws_acm_certificate_validation" "larrryharrisaws_cert_validation" {
  certificate_arn         = aws_acm_certificate.larrryharrisaws_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.larrryharrisaws_acm_validation : record.fqdn]

  timeouts {
    create = "30m"  # optional: give more time if propagation is slow
  }
}