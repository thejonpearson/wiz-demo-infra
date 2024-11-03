module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.name}-eks"
  cluster_version = "1.31"

# # below line will increase the wait before worker nodes are created
# # this may be necessary to ensure networking prefix delegation actually happens
  dataplane_wait_duration = "60s"

  # EKS Addons
  cluster_addons = {
    coredns                = {addon_version = "v1.11.3-eksbuild.2"}
    kube-proxy             = {addon_version = "v1.31.1-eksbuild.2"}
    vpc-cni = {
      before_compute           = true
      addon_version = "v1.18.5-eksbuild.1"
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION           = "true"
          WARM_ENI_TARGET                    = "1"
        }
      })
    }
  }

  vpc_id     = var.vpcid
  subnet_ids = var.vpc_private_subnets
  
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access = true

#  potentially restrict access to specific CIDR blocks (or only my ip) 
#  cluster_endpoint_public_access_cidrs = [ "0.0.0.0/0" ]

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    nodes = {
      instance_types = ["t3.medium"]
      name = "${var.name}-eks-mng"    
      min_size = 1
      max_size = 3
      desired_size = 2
    }
  }
}