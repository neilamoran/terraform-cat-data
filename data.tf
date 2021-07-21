# data "azurerm_logic_app_workflow" "example" {
#   name                = "MSA-PASImport-Logic-App"
#   resource_group_name = "msa-devtest-uks-adf-rg"
# }

# output "access_endpoint" {
#   value = data.azurerm_logic_app_workflow.example.access_endpoint
# }

# output "schema" {
#     value = data.azurerm_logic_app_workflow.example.workflow_schema
# }

data "azurerm_client_config" "current" {}

# get subnet id

data "azurerm_subnet" "subnet" {
  name                 = var.subnet.name
  virtual_network_name = var.subnet.virtual_network_name
  resource_group_name  = var.subnet.resource_group_name
}