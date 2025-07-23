# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# For testing BYO EKS cluster with mixed IRSA/PI
#------------------------------------------------------------------------------
resource "aws_eks_cluster" "existing_mixed" {

  name     = "existing-cluster-mixed"
  role_arn = aws_iam_role.eks_cluster_mixed.arn

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = false
  }

  vpc_config {
    security_group_ids      = [aws_security_group.eks_cluster_allow_mixed.id]
    subnet_ids              = module.tfe_prereqs_w2.compute_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  kubernetes_network_config {
    ip_family = "ipv4"
  }

  tags = merge(
    { "Name" = "existing-cluster-mixed" }
  )
}

resource "aws_eks_access_entry" "tfe_cluster_creator_mixed" {
  cluster_name      = aws_eks_cluster.existing_mixed.name
  kubernetes_groups = null
  principal_arn     = data.aws_iam_session_context.current.issuer_arn
  type              = "STANDARD"
  user_name         = null

  tags = merge(
    { "Name" = "${aws_eks_cluster.existing_mixed.name}-access-entry" }
  )
}

resource "aws_eks_access_policy_association" "existing_cluster_creator_mixed" {
  access_scope {
    type       = "cluster"
    namespaces = []
  }

  cluster_name = aws_eks_cluster.existing_mixed.name

  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = data.aws_iam_session_context.current.issuer_arn
}

#------------------------------------------------------------------------------
# Security groups
#------------------------------------------------------------------------------
resource "aws_security_group" "eks_cluster_allow_mixed" {
  name   = "tfe-eks-cluster-allow-mixed"
  vpc_id = module.tfe_prereqs_w2.vpc_id

  tags = merge(
    { "Name" = "tfe-eks-allow-mixed" }
  )
}

resource "aws_security_group_rule" "eks_cluster_allow_ingress_nodegroup_mixed" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.tfe_eks_nodegroup_allow_mixed.id
  description              = "Allow TCP/443 (HTTPS) inbound to EKS cluster from node group."
  security_group_id        = aws_security_group.eks_cluster_allow_mixed.id
}

resource "aws_security_group_rule" "eks_cluster_allow_all_egress_mixed" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic from EKS cluster."
  security_group_id = aws_security_group.eks_cluster_allow_mixed.id
}


#------------------------------------------------------------------------------
# EKS cluster
#------------------------------------------------------------------------------
resource "aws_iam_role" "eks_cluster_mixed" {

  name        = "eks-cluster-role-${data.aws_region.current.name}-mixed"
  path        = "/"
  description = "IAM role for TFE EKS cluster."

  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role_mixed.json

}

data "aws_iam_policy_document" "eks_cluster_assume_role_mixed" {
  statement {
    sid     = "EksClusterAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_cluster_policy_mixed" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_mixed.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_service_policy_mixed" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_mixed.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_vpc_resource_controller_policy_mixed" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_mixed.name
}

#------------------------------------------------------------------------------
# EKS node group
#------------------------------------------------------------------------------
resource "aws_iam_role" "tfe_eks_nodegroup_mixed" {
  name        = "eks-node-group-role-${data.aws_region.current.name}-mixed"
  path        = "/"
  description = "IAM role for TFE EKS node group."

  assume_role_policy = data.aws_iam_policy_document.tfe_eks_nodegroup_assume_role_mixed.json

  tags = merge(
    { "Name" = "eks-node-group-role-${data.aws_region.current.name}-mixed" }
  )
}

data "aws_iam_policy_document" "tfe_eks_nodegroup_assume_role_mixed" {
  statement {
    sid     = "TfeEksNodeGroupAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "tfe_eks_nodegroup_worker_node_policy_mixed" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.tfe_eks_nodegroup_mixed.name
}

resource "aws_iam_role_policy_attachment" "tfe_eks_nodegroup_cni_policy_mixed" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.tfe_eks_nodegroup_mixed.name
}

resource "aws_iam_role_policy_attachment" "tfe_eks_nodegroup_container_registry_readonly_mixed" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.tfe_eks_nodegroup_mixed.name
}

#------------------------------------------------------------------------------
# EKS node group
#------------------------------------------------------------------------------
resource "aws_eks_node_group" "tfe_mixed" {
  cluster_name    = aws_eks_cluster.existing_mixed.name
  node_group_name = "existing-nodegroup-mixed"
  node_role_arn   = aws_iam_role.tfe_eks_nodegroup_mixed.arn
  subnet_ids      = module.tfe_prereqs_w2.compute_subnet_ids
  capacity_type   = "ON_DEMAND"
  instance_types  = ["m7i.large"]
  ami_type        = "AL2023_x86_64_STANDARD"

  launch_template {
    id      = aws_launch_template.tfe_eks_nodegroup_mixed.id
    version = aws_launch_template.tfe_eks_nodegroup_mixed.latest_version
  }

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  tags = merge(
    { "Name" = "existing-nodegroup-mixed" }
  )
}

#------------------------------------------------------------------------------
# Launch template
#------------------------------------------------------------------------------
data "aws_ami" "tfe_eks_nodegroup_default_mixed" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [lookup(local.eks_default_ami_map, "AL2023_x86_64_STANDARD")]
  }
}

resource "aws_launch_template" "tfe_eks_nodegroup_mixed" {
  name = "existing-launch-template-mixed"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.tfe_eks_nodegroup_allow_mixed.id]
  }

  block_device_mappings {
    device_name = data.aws_ami.tfe_eks_nodegroup_default_mixed.root_device_name

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      delete_on_termination = true
      encrypted             = true
    }
  }

  ebs_optimized = true

  // https://support.hashicorp.com/hc/en-us/articles/35213717169427-Terraform-Enterprise-FDO-fails-to-start-with-EKS-version-1-30
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    instance_metadata_tags      = "disabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "existing-eks-private-node-mixed"
    }
  }
}

#------------------------------------------------------------------------------
# Security groups
#------------------------------------------------------------------------------
resource "aws_security_group" "tfe_eks_nodegroup_allow_mixed" {
  name   = "existing-eks-nodegroup-allow-mixed"
  vpc_id = module.tfe_prereqs_w2.vpc_id
  tags   = merge({ "Name" = "existing-eks-nodegroup-allow-mixed" })
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_443_from_lb_mixed" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.tfe_byo_mixed.tfe_lb_security_group_id
  description              = "Allow TCP/443 (HTTPS) inbound to node group from TFE load balancer."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow_mixed.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_tfe_http_from_lb_mixed" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = module.tfe_byo_mixed.tfe_lb_security_group_id
  description              = "Allow TCP/8080 or specified port (TFE HTTP) inbound to node group from TFE load balancer."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow_mixed.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_tfe_https_from_lb_mixed" {
  type                     = "ingress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  source_security_group_id = module.tfe_byo_mixed.tfe_lb_security_group_id
  description              = "Allow TCP/8443 or specified port (TFE HTTPS) inbound to node group from TFE load balancer."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow_mixed.id
}

# resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_tfe_metrics_http_from_cidr" {
#   count = var.cidr_allow_ingress_tfe_metrics_http != null ? 1 : 0

#   type        = "ingress"
#   from_port   = var.tfe_metrics_http_port
#   to_port     = var.tfe_metrics_http_port
#   protocol    = "tcp"
#   cidr_blocks = var.cidr_allow_ingress_tfe_metrics_http
#   description = "Allow TCP/9090 or specified port (TFE HTTP metrics endpoint) inbound to node group from specified CIDR ranges."

#   security_group_id = aws_security_group.tfe_eks_nodegroup_allow[0].id
# }

# resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_tfe_metrics_https_from_cidr" {
#   count = var.cidr_allow_ingress_tfe_metrics_https != null ? 1 : 0

#   type        = "ingress"
#   from_port   = var.tfe_metrics_https_port
#   to_port     = var.tfe_metrics_https_port
#   protocol    = "tcp"
#   cidr_blocks = var.cidr_allow_ingress_tfe_metrics_https
#   description = "Allow TCP/9091 or specified port (TFE HTTPS metrics endpoint) inbound to node group from specified CIDR ranges."

#   security_group_id = aws_security_group.tfe_eks_nodegroup_allow[0].id
# }

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_443_from_cluster_mixed" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_allow_mixed.id
  description              = "Allow TCP/443 (Cluster API) inbound to node group from EKS cluster (cluster API)."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow_mixed.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_10250_from_cluster_mixed" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_allow_mixed.id
  description              = "Allow TCP/10250 (kubelet) inbound to node group from EKS cluster (cluster API)."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow_mixed.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_4443_from_cluster_mixed" {
  type                     = "ingress"
  from_port                = 4443
  to_port                  = 4443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_allow_mixed.id
  description              = "Allow TCP/4443 (webhooks) inbound to node group from EKS cluster (cluster API)."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow_mixed.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_9443_from_cluster_mixed" {
  type                     = "ingress"
  from_port                = 9443
  to_port                  = 9443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_allow_mixed.id
  description              = "Allow TCP/9443 (ALB controller, NGINX) inbound to node group from EKS cluster (cluster API)."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow_mixed.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_6443_from_cluster_mixed" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_allow_mixed.id
  description              = "Allow TCP/6443 (prometheus-adapter) inbound to node group from EKS cluster (cluster API)."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow_mixed.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_8443_from_cluster_mixed" {
  type                     = "ingress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_allow_mixed.id
  description              = "Allow TCP/8443 (Karpenter) inbound to node group from EKS cluster (cluster API)."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow_mixed.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_nodes_53_tcp_mixed" {
  type        = "ingress"
  from_port   = 53
  to_port     = 53
  protocol    = "tcp"
  self        = true
  description = "Allow TCP/53 (CoreDNS) inbound between nodes in node group."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow_mixed.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_nodes_53_udp_mixed" {
  type        = "ingress"
  from_port   = 53
  to_port     = 53
  protocol    = "udp"
  self        = true
  description = "Allow UDP/53 (CoreDNS) inbound between nodes in node group."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow_mixed.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_nodes_ephemeral_mixed" {
  type        = "ingress"
  from_port   = 1025
  to_port     = 65535
  protocol    = "tcp"
  self        = true
  description = "Allow TCP/1025-TCP/65535 (ephemeral ports) inbound between nodes in node group."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow_mixed.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_all_egress_mixed" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all outbound traffic from node group."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow_mixed.id
}