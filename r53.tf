data "aws_route53_zone" "public_zone" {
  name = local.r53_zone
}

resource "aws_route53_record" "bastion" {
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = "bastion.nick-philbrook.sbx.hashidemos.io"
  type    = "CNAME"
  ttl     = 300
  records = [module.prereqs.bastion_public_dns]
}

data "aws_lb" "new" {
  tags = {
    "elbv2.k8s.aws/cluster" = module.tfe_new.eks_cluster_name
  }
}

resource "aws_route53_record" "tfe" {
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = local.tfe_pi_new_fqdn
  type    = "CNAME"
  ttl     = 300
  records = [data.aws_lb.new.dns_name]
}
