locals { # currently working on
  current_time = timestamp()
  tomorrow     = formatdate("YYYY-MM-DD", timeadd(local.current_time, "24h"))
}

resource "azurerm_automation_account" "automation_account" {
  name                = "${var.resource_group}-automation-account"
  location            = "UK West"
  resource_group_name = var.resource_group
  sku_name            = "Basic"
  tags = {
    infrastructure_support = "DSO:digital-studio-operations-team@digital.justice.gov.uk"
    source_code            = "https://github.com/ministryofjustice/dso-azure-automation-accounts"
  }
}

# sadly doesn't work
#resource "azurerm_automation_module" "azurerm" {
#  name                    = "AzureRM"
#  resource_group_name     = azurerm_automation_account.automation_account.resource_group_name
#  automation_account_name = azurerm_automation_account.automation_account.name
#  module_link {
#    uri = "https://www.powershellgallery.com/api/v2/package/AzureRM/6.13.2"
#  }
#}

resource "azurerm_automation_schedule" "schedules" {
  for_each                = var.schedules
  name                    = each.key
  resource_group_name     = azurerm_automation_account.automation_account.resource_group_name
  automation_account_name = azurerm_automation_account.automation_account.name
  frequency               = each.value.frequency
  week_days               = each.value.week_days
  start_time              = "${local.tomorrow}T${each.value.time}Z"
  timezone                = "UTC"
  lifecycle {
    ignore_changes = [
      # Ignore changes to start_time, because if new needs to be 5 mins in future.
      # if created we don't want to recreate this all the time since we're dynamically setting start_time
      start_time,
      timezone # annoyingly this should be changed manually for now. Terraform/azure has confusion with the timezone being 'Etc/UTC' or 'UTC'.
    ]
  }
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
  content = templatefile("${path.module}/automation_scripts/${each.key}.ps1.tmpl", {
    resource_group       = azurerm_automation_account.automation_account.resource_group_name
    delay_between_groups = var.delay_between_groups
  })
}

resource "azurerm_automation_job_schedule" "job_schedules" {
  for_each                = { for index, js in var.job_schedules : index => js }
  resource_group_name     = azurerm_automation_account.automation_account.resource_group_name
  automation_account_name = azurerm_automation_account.automation_account.name
  schedule_name           = each.value.schedule
  runbook_name            = each.value.script
}