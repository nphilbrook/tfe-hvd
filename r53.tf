data "aws_route53_zone" "public_zone" {
  name = local.r53_zone
}

resource "aws_route53_record" "tfe" {
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = local.tfe_fqdn
  type    = "CNAME"
  ttl     = 300
  records = ["k8s-tfe-terrafor-04ceae181f-acbb33607c5d8af0.elb.us-west-2.amazonaws.com"]
}
