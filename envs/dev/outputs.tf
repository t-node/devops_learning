output "root_k3s_kubeconfig_scp" {
  description = "EC2 public IP from compute module"
  value       = module.compute.k3s_kubeconfig_scp
}
