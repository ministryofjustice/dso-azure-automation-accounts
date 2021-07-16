resource "azurerm_automation_account" "automation_account" {
  name                = "${var.resource_group}-automation-account"
  location            = "UK West"
  resource_group_name = var.resource_group
  sku_name            = "Basic"
}

resource "azurerm_automation_module" "azurerm" {
  name                    = "AzureRM"
  resource_group_name     = azurerm_automation_account.automation_account.resource_group_name
  automation_account_name = azurerm_automation_account.automation_account.name
  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/AzureRM/6.13.2"
  }
}

resource "azurerm_automation_schedule" "schedules" {
  for_each                = var.schedules
  name                    = each.key
  resource_group_name     = azurerm_automation_account.automation_account.resource_group_name
  automation_account_name = azurerm_automation_account.automation_account.name
  frequency               = "Week"
  week_days               = each.value.week_days
  start_time              = each.value.start_time
}

resource "azurerm_automation_runbook" "runbooks" {
  for_each                = toset(var.script_templates)
  name                    = each.key
  location                = azurerm_automation_account.automation_account.location
  resource_group_name     = azurerm_automation_account.automation_account.resource_group_name
  automation_account_name = azurerm_automation_account.automation_account.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShellWorkflow"
  content                 = templatefile("${path.module}/automation_scripts/${each.key}.ps1.tmpl", { 
    resource_group = azurerm_automation_account.automation_account.resource_group_name
  })
}

resource "azurerm_automation_job_schedule" "job_schedules" {
  for_each                = { for index, js in var.job_schedules: index => js }
  resource_group_name     = azurerm_automation_account.automation_account.resource_group_name
  automation_account_name = azurerm_automation_account.automation_account.name
  schedule_name           = each.value.schedule
  runbook_name            = each.value.script
}