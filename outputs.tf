output "cluster_id" {
  description = "OCID of the existing OKE cluster."
  value       = var.cluster_id
}

output "worker_instance_ids" {
  description = "OCIDs of the self-managed confidential worker instances."
  value       = oci_core_instance.confidential_worker[*].id
}

output "worker_private_ips" {
  description = "Private IPs of the self-managed confidential worker instances."
  value       = oci_core_instance.confidential_worker[*].private_ip
}

output "kubeconfig_cmd" {
  description = "Command to generate kubeconfig for this cluster."
  value       = "oci ce cluster create-kubeconfig --cluster-id ${var.cluster_id} --region ${var.region} --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT"
}
