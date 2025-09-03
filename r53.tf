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
    "service.k8s.aws/stack" = "tfe/terraform-enterprise"
  }
}

resource "aws_route53_record" "tfe" {
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = local.tfe_pi_new_fqdn
  type    = "CNAME"
  ttl     = 300
  records = [data.aws_lb.new.dns_name]
}

# Create a private hosted zone for internal TFE resolution
resource "aws_route53_zone" "tfe_internal" {
  name = "nick-philbrook.sbx.hashidemos.io"

  vpc {
    vpc_id = module.prereqs.vpc_id
  }

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.new_friendly_name_prefix}-tfe-internal-zone"
      Purpose = "Internal DNS resolution for TFE"
    }
  )
}

# Data source to find the internal NLB by tags
data "aws_lb" "internal" {
  tags = {
    "elbv2.k8s.aws/cluster" = module.tfe_new.eks_cluster_name
    "service.k8s.aws/stack" = "tfe/terraform-enterprise-internal"
  }
}

# Create a CNAME record that points to the internal NLB
resource "aws_route53_record" "tfe_internal" {
  zone_id = aws_route53_zone.tfe_internal.zone_id
  name    = local.tfe_pi_new_fqdn
  type    = "CNAME"
  ttl     = 300
  records = [data.aws_lb.internal.dns_name]
}
