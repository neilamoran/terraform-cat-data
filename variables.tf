variable "name" {
  default = "nm"
}

variable "location" {
  default = "uksouth"
}

variable "environment" {
  default = "devtest"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "linked_sql_server" {
  type        = map(string)
  description = <<-EOT
  Sql Server instances to be configured as linked services. Format:
    {
      friendly_name = connection_string
      another_name  = another_connection_string
      etc           = etc
    }
  NB They will use the SHIR created by default.
  EOT
  default = {
    msa-dev-sql2 = "integrated security=True;data source=msa-dev-sql2;initial catalog=MyDBName"
  }
}

variable "subnet" {
  type        = map(string)
  description = "Details for subnet to connect SHIR VM to"
  default = {
    name                 = "default"
    virtual_network_name = "sql-sysprep-test-vnet"
    resource_group_name  = "sql-sysprep-test"
  }
}

variable "pipeline_name" {
  default = "ProcessPASImportPipeline"
}