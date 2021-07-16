provider "azurerm" {
  features {}
}

##
# automation

module "automation_account" {
  source            = "../modules/automation_account"
  for_each          = var.automation_accounts
  resource_group    = each.key
  script_templates  = lookup(each, "script_templates", [
    "start-vms", 
    "stop-vms"
  ])
  schedules         = lookup(each, "schedules", {
    "weekdays 7am" = {
      week_days     = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
      start_time    = "2021-06-14T07:00:00Z" # annoyingly this needs to be 5 mins ahead of the first deployment and the time that you want the job to run
    },
    "weekdays 7pm" = {
      week_days     = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
      start_time    = "2021-06-14T19:00:00Z"
    }
  })
  job_schedules     = each.job_schedules
}