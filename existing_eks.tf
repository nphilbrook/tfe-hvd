# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# For testing BYO EKS cluster
#------------------------------------------------------------------------------
resource "aws_eks_cluster" "existing" {

  name     = "existing-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = false
  }

  vpc_config {
    security_group_ids      = [aws_security_group.eks_cluster_allow.id]
    subnet_ids              = module.tfe_prereqs_w2.compute_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  kubernetes_network_config {
    ip_family = "ipv4"
  }

  tags = merge(
    { "Name" = "exixsting-cluster" }
  )
}

resource "aws_eks_access_entry" "tfe_cluster_creator" {
  cluster_name      = aws_eks_cluster.existing.name
  kubernetes_groups = null
  principal_arn     = data.aws_iam_session_context.current.issuer_arn
  type              = "STANDARD"
  user_name         = null

  tags = merge(
    { "Name" = "${aws_eks_cluster.existing.name}-access-entry" }
  )
}

resource "aws_eks_access_policy_association" "existing_cluster_creator" {
  access_scope {
    type       = "cluster"
    namespaces = []
  }

  cluster_name = aws_eks_cluster.existing.name

  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = data.aws_iam_session_context.current.issuer_arn

}

#------------------------------------------------------------------------------
# Security groups
#------------------------------------------------------------------------------
resource "aws_security_group" "eks_cluster_allow" {
  name   = "tfe-eks-cluster-allow"
  vpc_id = module.tfe_prereqs_w2.vpc_id

  tags = merge(
    { "Name" = "tfe-eks-allow" }
  )
}

resource "aws_security_group_rule" "eks_cluster_allow_ingress_nodegroup" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.tfe_eks_nodegroup_allow.id
  description              = "Allow TCP/443 (HTTPS) inbound to EKS cluster from node group."
  security_group_id        = aws_security_group.eks_cluster_allow.id
}

resource "aws_security_group_rule" "eks_cluster_allow_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic from EKS cluster."
  security_group_id = aws_security_group.eks_cluster_allow.id
}


#------------------------------------------------------------------------------
# EKS cluster
#------------------------------------------------------------------------------
resource "aws_iam_role" "eks_cluster" {

  name        = "eks-cluster-role-${data.aws_region.current.name}"
  path        = "/"
  description = "IAM role for TFE EKS cluster."

  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json

}

data "aws_iam_policy_document" "eks_cluster_assume_role" {
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

resource "aws_iam_role_policy_attachment" "eks_cluster_cluster_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_service_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_vpc_resource_controller_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

#------------------------------------------------------------------------------
# EKS node group
#------------------------------------------------------------------------------
resource "aws_iam_role" "tfe_eks_nodegroup" {
  name        = "eks-node-group-role-${data.aws_region.current.name}"
  path        = "/"
  description = "IAM role for TFE EKS node group."

  assume_role_policy = data.aws_iam_policy_document.tfe_eks_nodegroup_assume_role.json

  tags = merge(
    { "Name" = "eks-node-group-role-${data.aws_region.current.name}" }
  )
}

data "aws_iam_policy_document" "tfe_eks_nodegroup_assume_role" {
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

resource "aws_iam_role_policy_attachment" "tfe_eks_nodegroup_worker_node_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.tfe_eks_nodegroup.name
}

resource "aws_iam_role_policy_attachment" "tfe_eks_nodegroup_cni_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.tfe_eks_nodegroup.name
}

resource "aws_iam_role_policy_attachment" "tfe_eks_nodegroup_container_registry_readonly" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.tfe_eks_nodegroup.name
}

#------------------------------------------------------------------------------
# EKS node group
#------------------------------------------------------------------------------
resource "aws_eks_node_group" "tfe" {
  cluster_name    = aws_eks_cluster.existing.name
  node_group_name = "existing-nodegroup"
  node_role_arn   = aws_iam_role.tfe_eks_nodegroup.arn
  subnet_ids      = module.tfe_prereqs_w2.compute_subnet_ids
  capacity_type   = "ON_DEMAND"
  instance_types  = ["m7i.large"]
  ami_type        = "AL2023_x86_64_STANDARD"

  launch_template {
    id      = aws_launch_template.tfe_eks_nodegroup.id
    version = aws_launch_template.tfe_eks_nodegroup.latest_version
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
    { "Name" = "existing-nodegroup" }
  )
}

#------------------------------------------------------------------------------
# Launch template
#------------------------------------------------------------------------------
locals {
  eks_default_ami_map = {
    // https://github.com/awslabs/amazon-eks-ami/releases
    AL2023_ARM_64_STANDARD     = "al2023-ami-minimal-2023.*-arm64"
    AL2023_x86_64_STANDARD     = "al2023-ami-minimal-2023.*-x86_64"
    AL2_ARM_64                 = "amzn2-ami-minimal-hvm-2.0.*-arm64-ebs"
    AL2_x86_64                 = "amzn2-ami-minimal-hvm-2.0.*-x86_64-ebs"
    AL2_x86_64_GPU             = "amzn2-ami-minimal-hvm-2.0.*-x86_64-ebs"
    BOTTLEROCKET_ARM_64        = "bottlerocket-aws-k8s-*-aarch64-*"
    BOTTLEROCKET_x86_64        = "bottlerocket-aws-k8s-*-x86_64-*"
    BOTTLEROCKET_ARM_64_NVIDIA = "bottlerocket-aws-k8s-*-nvidia-aarch64-*"
    BOTTLEROCKET_x86_64_NVIDIA = "bottlerocket-aws-k8s-*-nvidia-x86_64-*"
  }
}

data "aws_ami" "tfe_eks_nodegroup_default" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [lookup(local.eks_default_ami_map, "AL2023_x86_64_STANDARD")]
  }
}

resource "aws_launch_template" "tfe_eks_nodegroup" {
  name = "existing-launch-template"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.tfe_eks_nodegroup_allow.id]
  }

  block_device_mappings {
    device_name = data.aws_ami.tfe_eks_nodegroup_default.root_device_name

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
      Name = "existing-eks-private-node"
    }
  }
}

#------------------------------------------------------------------------------
# Security groups
#------------------------------------------------------------------------------
resource "aws_security_group" "tfe_eks_nodegroup_allow" {
  name   = "existing-eks-nodegroup-allow"
  vpc_id = module.tfe_prereqs_w2.vpc_id
  tags   = merge({ "Name" = "existing-eks-nodegroup-allow" })
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_443_from_lb" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.tfe_pi_byo.tfe_lb_security_group_id
  description              = "Allow TCP/443 (HTTPS) inbound to node group from TFE load balancer."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_tfe_http_from_lb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = module.tfe_pi_byo.tfe_lb_security_group_id

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_tfe_https_from_lb" {
  type                     = "ingress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  source_security_group_id = module.tfe_pi_byo.tfe_lb_security_group_id
  description              = "Allow TCP/8443 or specified port (TFE HTTPS) inbound to node group from TFE load balancer."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow.id
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

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_443_from_cluster" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_allow.id
  description              = "Allow TCP/443 (Cluster API) inbound to node group from EKS cluster (cluster API)."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_10250_from_cluster" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_allow.id
  description              = "Allow TCP/10250 (kubelet) inbound to node group from EKS cluster (cluster API)."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_4443_from_cluster" {
  type                     = "ingress"
  from_port                = 4443
  to_port                  = 4443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_allow.id
  description              = "Allow TCP/4443 (webhooks) inbound to node group from EKS cluster (cluster API)."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_9443_from_cluster" {
  type                     = "ingress"
  from_port                = 9443
  to_port                  = 9443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_allow.id
  description              = "Allow TCP/9443 (ALB controller, NGINX) inbound to node group from EKS cluster (cluster API)."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_6443_from_cluster" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_allow.id
  description              = "Allow TCP/6443 (prometheus-adapter) inbound to node group from EKS cluster (cluster API)."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_8443_from_cluster" {
  type                     = "ingress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_allow.id
  description              = "Allow TCP/8443 (Karpenter) inbound to node group from EKS cluster (cluster API)."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_nodes_53_tcp" {
  type        = "ingress"
  from_port   = 53
  to_port     = 53
  protocol    = "tcp"
  self        = true
  description = "Allow TCP/53 (CoreDNS) inbound between nodes in node group."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_nodes_53_udp" {
  type        = "ingress"
  from_port   = 53
  to_port     = 53
  protocol    = "udp"
  self        = true
  description = "Allow UDP/53 (CoreDNS) inbound between nodes in node group."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_nodes_ephemeral" {
  type        = "ingress"
  from_port   = 1025
  to_port     = 65535
  protocol    = "tcp"
  self        = true
  description = "Allow TCP/1025-TCP/65535 (ephemeral ports) inbound between nodes in node group."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow.id
}

resource "aws_security_group_rule" "tfe_eks_nodegroup_allow_all_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all outbound traffic from node group."

  security_group_id = aws_security_group.tfe_eks_nodegroup_allow.id
}