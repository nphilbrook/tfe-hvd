data "aws_route53_zone" "public_zone" {
  name = local.r53_zone
}

data "aws_lb" "primary" {
  tags = {
    "elbv2.k8s.aws/cluster" = "primary-tfe-eks-cluster"
  }
}

data "aws_lb" "pi" {
  tags = {
    "elbv2.k8s.aws/cluster" = "pi-tfe-eks-cluster"
  }
}

resource "aws_route53_record" "tfe" {
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = local.tfe_fqdn
  type    = "CNAME"
  ttl     = 300
  records = [data.aws_lb.primary.dns_name]
}

resource "aws_route53_record" "tfe_pi" {
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = local.tfe_pi_fqdn
  type    = "CNAME"
  ttl     = 300
  records = [data.aws_lb.pi.dns_name]
}

data "aws_lb" "irsa_new" {
  tags = {
    "elbv2.k8s.aws/cluster" = "irsa-new-tfe-eks-cluster"
  }
}

resource "aws_route53_record" "irsa_new" {
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = local.tfe_irsa_new_fqdn
  type    = "CNAME"
  ttl     = 300
  records = [data.aws_lb.irsa_new.dns_name]
}
