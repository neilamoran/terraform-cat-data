# SHIR details
# auth key
# setup script from a template?

output "shir_install_script" {
  description = "A customised PowerShell script to run to deploy the Integration Runtime onto your chosen server"
  value       = local.shir_install_script
}