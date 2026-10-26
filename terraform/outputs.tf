output "vpc_id" {
  description = "The ID of the provisioned VPC"
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "Name of the provisioned EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint URL of the EKS cluster control plane"
  value       = module.eks.cluster_endpoint
}

output "ecr_repository_urls" {
  description = "Registry URLs for container repositories"
  value       = module.ecr.repository_urls
}
