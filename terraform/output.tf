output "cfpassword" {
  value       = local.CF_PASS
  description = "The ColdFusion administrator password"
  sensitive = true
}

output "app_url" {
  value       = "http://${google_compute_instance.main.network_interface[0].access_config[0].nat_ip}:8500/todo"
  description = "The url of the main application"
}

output "admin_url" {
  value       = "http://${google_compute_instance.main.network_interface[0].access_config[0].nat_ip}:8500/CFIDE/administrator"
  description = "The url of the main application"
}