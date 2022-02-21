locals {
  current_time = timestamp()
  tomorrow     = formatdate("YYYY-MM-DD", timeadd(local.current_time, "24h"))
  tags         = {
    infrastructure_support = "DSO:digital-studio-operations-team@digital.justice.gov.uk"
    source_code            = "https://github.com/ministryofjustice/dso-azure-automation-accounts"
  }
}

resource "azurerm_automation_account" "automation_account" {
  name                = "${var.resource_group}-automation-account"
  location            = "UK West"
  resource_group_name = var.resource_group
  sku_name            = "Basic"
  tags                = local.tags
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
  log_verbose             = "false"
  log_progress            = "true"
  runbook_type            = "PowerShellWorkflow"
  content = templatefile("${path.module}/automation_scripts/${each.key}.ps1.tmpl", {
    resource_group       = azurerm_automation_account.automation_account.resource_group_name
    delay_between_groups = var.delay_between_groups
  })
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_automation_job_schedule" "job_schedules" {
  for_each                = { for index, js in var.job_schedules : index => js }
  resource_group_name     = azurerm_automation_account.automation_account.resource_group_name
  automation_account_name = azurerm_automation_account.automation_account.name
  schedule_name           = each.value.schedule
  runbook_name            = each.value.script
  depends_on              = [azurerm_automation_runbook.runbooks]
}

##
# store the logs from the runbook runs

resource "azurerm_log_analytics_workspace" "analytics_workspace" {
  name                = azurerm_automation_account.automation_account.name
  location            = azurerm_automation_account.automation_account.location
  resource_group_name = azurerm_automation_account.automation_account.resource_group_name
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_settings" {
  name                       = azurerm_automation_account.automation_account.name
  target_resource_id         = azurerm_automation_account.automation_account.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.analytics_workspace.id
  log {
    category = "AuditEvent"
    enabled  = false
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "DscNodeStatus"
    enabled  = false
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "JobLogs"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "JobStreams"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  metric {
    category = "AllMetrics"
    enabled  = false
    retention_policy {
      days    = 0
      enabled = false
    }
  }
}

###
# Alert when there are runbook errors

resource "azurerm_monitor_action_group" "email_dso" {
  name                = "email_dso"
  resource_group_name = azurerm_automation_account.automation_account.resource_group_name
  short_name          = "email_dso"

  email_receiver {
    name          = "email_dso"
    email_address = "william.gibbon@digital.justice.gov.uk" # change to digital-studio-operations-team@digital.justice.gov.uk
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert" "alert" {
  name                = "automation_account_query_rule"
  location            = azurerm_automation_account.automation_account.location
  resource_group_name = azurerm_automation_account.automation_account.resource_group_name

  action {
    action_group           = [azurerm_monitor_action_group.email_dso.id]
    email_subject          = "${var.resource_group}-automation-account job errors"
  }
  data_source_id = azurerm_log_analytics_workspace.analytics_workspace.id
  description    = "Alert when errors exist in automation account job"
  query       = <<-QUERY
  AzureDiagnostics 
  | where ResourceProvider == "MICROSOFT.AUTOMATION"
  | where StreamType_s == "Error"
  | project TimeGenerated, JobId_g, RunbookName_s, _ResourceId, Resource, ResultDescription
  QUERY
  # query returns :
  # TimeGenerated [UTC]       JobId_g                               RunbookName_s   _ResourceId                                                                                                                                                 Resource                      ResultDescription
  # 16/02/2022, 16:00:18.453	e03e51a5-69dd-419c-9e9b-d3a44fb01326	start-vms	      /subscriptions/b1f3cebb-4988-4ff9-9259-f02ad7744fcb/resourcegroups/t1-oasys/providers/microsoft.automation/automationaccounts/t1-oasys-automation-account   T1-OASYS-AUTOMATION-ACCOUNT	  Connect-AzureRMAccount : An error occurred while sending the request.At start-vms:9 char:9+ + CategoryInfo : CloseError: (:) [Connect-AzureRmAccount], HttpRequestException + FullyQualifiedErrorId : Microsoft.Azure.Commands.Profile.ConnectAzureRmAccountCommand		
  # 16/02/2022, 16:00:19.369	e03e51a5-69dd-419c-9e9b-d3a44fb01326	start-vms	      /subscriptions/b1f3cebb-4988-4ff9-9259-f02ad7744fcb/resourcegroups/t1-oasys/providers/microsoft.automation/automationaccounts/t1-oasys-automation-account   T1-OASYS-AUTOMATION-ACCOUNT   Get-AzureRmVM : No subscription found in the context. Please ensure that the credentials you provided are authorized to access an Azure subscription, then run Connect-AzureRmAccount to login.At start-vms:12 char:12+ + CategoryInfo : CloseError: (:) [Get-AzureRmVM], ApplicationException + FullyQualifiedErrorId : Microsoft.Azure.Commands.Compute.GetAzureVMCommand		
  severity    = 0
  frequency   = 30 # mins
  time_window = 30 # mins
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }
}

resource "azurerm_log_analytics_linked_service" "link_log_workspace" {
  resource_group_name = azurerm_automation_account.automation_account.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.analytics_workspace.id
  read_access_id      = azurerm_automation_account.automation_account.id
}