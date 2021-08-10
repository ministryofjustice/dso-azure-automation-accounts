provider "azurerm" {
  features {}
}

##
# automation

module "automation_account" {
  source            = "./modules/automation_account"
  for_each          = var.automation_accounts
  resource_group    = each.key
  script_templates  = lookup(each.value, "script_templates", [
    "start-vms", 
    "stop-vms"
  ])
  schedules         = lookup(each.value, "schedules", var.schedules)
  job_schedules     = lookup(each.value, "job_schedules", [
    {
      schedule = "weekdays 6am"
      script   = "start-vms"
    },
    {
      schedule = "weekdays 7pm"
      script   = "stop-vms"
    }
  ])
}