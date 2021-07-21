resource "azurerm_resource_group" "rg" {
  name = join("-", [
    var.name,
    var.environment,
    var.location,
    "rg"
  ])
  location = var.location
  tags     = var.tags
}

resource "random_string" "random" {
  length  = 6
  special = false
}

# module "vm" {
#   source = "git::git@ssh.dev.azure.com:v3/rpc-tyche/Cognizant/tf-module-azure-vm"
#   name = join("-", [
#     var.name,
#     "shir"
#   ])
#   resource_group_name = azurerm_resource_group.rg.name
#   subnet_id           = data.azurerm_subnet.subnet.id
#   server_type         = "web"
#   custom_data         = local.shir_install_script
# }

resource "azurerm_data_factory" "adf" {
  name = join("-", [
    var.name,
    var.environment,
    var.location,
    "adf"
  ])
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  identity {
    type = "SystemAssigned"
  }
  tags = var.tags
  # Probably need to include VSTS integration config details too
}

resource "azurerm_data_factory_integration_runtime_self_hosted" "shir" {
  name = join("-", [
    azurerm_data_factory.adf.name,
    "shir"
  ])
  resource_group_name = azurerm_resource_group.rg.name
  data_factory_name   = azurerm_data_factory.adf.name
}

resource "azurerm_data_factory_pipeline" "pasimport" {
  name                = var.pipeline_name
  resource_group_name = azurerm_resource_group.rg.name
  data_factory_name   = azurerm_data_factory.adf.name
  activities_json     = templatefile("${path.module}/data-factory-pipelines/pasimport-activities.json",{
      linked_sql_service_name = keys(var.linked_sql_server)[0]
  })
  parameters = {
      PolicyKey = ""
      PASObject = ""
  }
}

# resource "time_sleep" "wait_for_shir_install" {
#   create_duration = "300s"
#   depends_on = [
#     module.vm
#   ]
# }

resource "azurerm_data_factory_linked_service_sql_server" "sql" {
  for_each                 = var.linked_sql_server
  name                     = each.key
  resource_group_name      = azurerm_resource_group.rg.name
  data_factory_name        = azurerm_data_factory.adf.name
  connection_string        = each.value
  integration_runtime_name = "AutoResolveIntegrationRuntime"
#   depends_on = [
#       time_sleep.wait_for_shir_install
#   ]
}

# resource "azurerm_logic_app_workflow" "pasimport" {
#   name = join("-", [
#     var.name,
#     var.environment,
#     "pasimport",
#     "logapp"
#   ])
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   tags                = var.tags
#   provisioner "local-exec" {
#     command = templatefile("${path.module}/scripts/update-logicapp-definition.ps1", {
#       resource_group  = azurerm_resource_group.rg.name
#       logic_app       = self.name
#       definition_file = "pasimport.json"
#       connectionId    = jsondecode(azurerm_resource_group_template_deployment.apiconnection_data_factory.output_content).resourceId.value
#       id              = jsondecode(azurerm_resource_group_template_deployment.apiconnection_data_factory.output_content).apiConnection.value.api.id
#       name            = jsondecode(azurerm_resource_group_template_deployment.apiconnection_data_factory.output_content).apiConnection.value.api.name
#       datafactoryId   = azurerm_data_factory.adf.id
#     })
#     interpreter = ["pwsh", "-Command"]
#   }
#   depends_on = [
#     azurerm_resource_group_template_deployment.apiconnection_data_factory
#   ]
# }

# resource "azurerm_logic_app_workflow" "pasimportstatus" {
#   name = join("-", [
#     var.name,
#     var.environment,
#     "pasimportstatus",
#     "logapp"
#   ])
#   identity {
#       type = "SystemAssigned"
#   }
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   tags                = var.tags
#   provisioner "local-exec" {
#     command = templatefile("${path.module}/scripts/update-logicapp-definition.ps1", {
#       resource_group  = azurerm_resource_group.rg.name
#       logic_app       = self.name
#       definition_file = "pasimportstatus.json"
#       connectionId    = jsondecode(azurerm_resource_group_template_deployment.apiconnection_data_factory.output_content).resourceId.value
#       id              = jsondecode(azurerm_resource_group_template_deployment.apiconnection_data_factory.output_content).apiConnection.value.api.id
#       name            = jsondecode(azurerm_resource_group_template_deployment.apiconnection_data_factory.output_content).apiConnection.value.api.name
#       datafactoryId   = azurerm_data_factory.adf.id
#     })
#     interpreter = ["pwsh", "-Command"]
#   }
#   depends_on = [
#     azurerm_resource_group_template_deployment.apiconnection_data_factory
#   ]
# }

# resource "azurerm_resource_group_template_deployment" "apiconnection_data_factory" {
#   name                = "arm-deployment-adf-api-connection-${formatdate("YYYYMMD", timestamp())}"
#   resource_group_name = azurerm_resource_group.rg.name
#   deployment_mode     = "Incremental"
#   parameters_content = jsonencode({
#     "connections_azuredatafactory_name" = {
#       value = "azuredatafactory"
#     }
#     "connections_azuredatafactory_display_name" = {
#       value = "apiconnection-${azurerm_data_factory.adf.name}"
#     }
#     "connections_azuredatafactory_location" = {
#       value = var.location
#     }
#     "connections_azuredatafactory_subscription_id" = {
#       value = data.azurerm_client_config.current.subscription_id
#     }
#   })
#   template_content = templatefile("${path.module}/apiconnections/azuredatafactory.json", {})
# }

resource "azurerm_resource_group_template_deployment" "pasimport" {
  name                = "arm-deployment-pasimport-${formatdate("YYYYMMD", timestamp())}"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental"
  parameters_content = jsonencode({
    "datafactory_location" = {
      value = var.location
    }
    "datafactory_subscriptionid" = {
      value = data.azurerm_client_config.current.subscription_id
    }
    "datafactory_resourcegroupname" = {
      value = azurerm_resource_group.rg.name
    }
    "datafactory_name" = {
      value = azurerm_data_factory.adf.name
    }

  })
  template_content = templatefile("${path.module}/logicapps/pasimport.arm.json", {})
}

resource "azurerm_api_management" "apim" {
  name = join("-", [
    var.name,
    var.environment,
    var.location,
    random_string.random.result,
    "apim"
  ])
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "Tyche"
  publisher_email     = "noreply@rpc-tyche.com"

  sku_name = "Developer_1"
  identity {
    type = "SystemAssigned"
  }
  tags = var.tags
}

# resource "azurerm_api_management_backend" "pasimport" {
#   name                = join("-", [
#       azurerm_logic_app_workflow.pasimport.name,
#       "backend"
#   ])
#   resource_group_name = azurerm_resource_group.rg.name
#   api_management_name = azurerm_api_management.apim.name
#   protocol            = "http"
#   url                 = azurerm_logic_app_workflow.pasimport.access_endpoint
# }

# resource "azurerm_api_management_backend" "pasimportstatus" {
#   name                = join("-", [
#       azurerm_logic_app_workflow.pasimportstatus.name,
#       "backend"
#   ])  
#   resource_group_name = azurerm_resource_group.rg.name
#   api_management_name = azurerm_api_management.apim.name
#   protocol            = "http"
#   url                 = azurerm_logic_app_workflow.pasimportstatus.access_endpoint
# }
