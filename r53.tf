data "aws_route53_zone" "public_zone" {
  name = local.r53_zone
}

resource "aws_route53_record" "tfe" {
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = local.tfe_fqdn
  type    = "CNAME"
  ttl     = 300
  # records = ["k8s-tfe-terrafor-9d178d5799-54e75854a36595fc.elb.us-west-2.amazonaws.com"]
  records = ["k8s-tfe-terrafor-1bca0dba44-09618d2838900dc1.elb.us-west-2.amazonaws.com."]
}
