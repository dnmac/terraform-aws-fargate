locals {
    validations = {
        for option in aws_acm_certificate.certificate.domain_validation_options :
        option.domain_name => option
    }
}


resource "aws_acm_certificate" "certificate" {

    domain_name                 = var.certificate_domain
    subject_alternative_names   = var.certificate_sans
    validation_method           = "DNS"

    lifecycle {
        create_before_destroy = true
    }

}

resource "aws_route53_record" "validation" {

    for_each = toset(concat([var.certificate_domain], var.certificate_sans))

    allow_overwrite = true
    zone_id = data.aws_route53_zone.zone.zone_id
    ttl = 60

    name    = local.validations[each.key].resource_record_name
    type    = local.validations[each.key].resource_record_type
    records = [ local.validations[each.key].resource_record_value ]

}

resource "aws_acm_certificate_validation" "check_validation" {
    certificate_arn = aws_acm_certificate.certificate.arn
    validation_record_fqdns = aws_acm_certificate.certificate.domain_validation_options[*].resource_record_name
}

resource "aws_route53_record" "project_dc_alb_record" {
  allow_overwrite = true
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${var.sub_domain}.${var.route53_hosted_zone_name}"

  type    = "CNAME"
  ttl = "60"
  records = [aws_alb.public_alb.dns_name]
}

resource "aws_route53_record" "project_dc_private_alb_record" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${var.sub_domain_api}.${var.route53_hosted_zone_name}"
  type    = "A"

  alias {
    name                   = aws_alb.private_alb.dns_name
    zone_id                = aws_alb.private_alb.zone_id
    evaluate_target_health = true
  }
}