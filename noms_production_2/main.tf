provider "azurerm" {
  features {}
}

##
# automation

module "automation_account" {
  source            = "../modules/automation_account"
  for_each          = var.automation_accounts
  resource_group    = each.key
  script_templates  = lookup(each.value, "script_templates", [
    "start-vms", 
    "stop-vms"
  ])
  schedules         = lookup(each.value, "schedules", var.schedules)
  job_schedules     = lookup(each.value, "job_schedules", [
    {
      schedule = "saturday 7am"
      script   = "stop-vms"
    },
    {
      schedule = "monday 7am"
      script   = "start-vms"
    }
  ])
  delay_between_groups = lookup(each.value, "delay_between_groups", 180)
}