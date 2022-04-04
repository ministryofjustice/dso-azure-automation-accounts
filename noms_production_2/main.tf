provider "azurerm" {
  tenant_id       = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
  subscription_id = "1d95dcda-65b2-4273-81df-eb979c6b547b"
  features {}
}

##
# automation

#module "automation_account" {
#  source            = "../modules/automation_account"
#  for_each          = var.automation_accounts
#  resource_group    = each.key
#  script_templates  = lookup(each.value, "script_templates", [
#    "start-vms", 
#    "stop-vms"
#  ])
#  schedules         = lookup(each.value, "schedules", var.schedules)
#  job_schedules     = lookup(each.value, "job_schedules", [
#    {
#      schedule = "saturday 7am"
#      script   = "stop-vms"
#    },
#    {
#      schedule = "monday 7am"
#      script   = "start-vms"
#    }
#  ])
#  delay_between_groups = lookup(each.value, "delay_between_groups", 180)
#}
