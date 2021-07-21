locals {
  shir_install_script = templatefile("${path.module}/scripts/install_integration_runtime.ps1", {
    shir_auth_key = azurerm_data_factory_integration_runtime_self_hosted.shir.auth_key_1
  })
}