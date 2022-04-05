# would have array of obj but that creates some ugly syntax when calling the var with for_each
# e.g. https://stackoverflow.com/questions/58594506/how-to-for-each-through-a-listobjects-in-terraform-0-12

# adding
#   some-resourcegroup {}
# will set up shutdown/startup automation at 7pm, 6am UTC respectively

tenant_id            = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
subscription_id      = "1d95dcda-65b2-4273-81df-eb979c6b547b"
la_workspace_name    = "noms-prod1"
la_workspace_rg_name = "noms-prod-loganalytics"

automation_accounts = { # each named after resource group
  nomis-bip-lsast = {
    tags = { service = "NOMIS", application = "BI", environment_name = "lsast" }
  },
  nomis-bip-preprod = {
    "delay_between_groups" = 600
    tags = { service = "NOMIS", application = "BI", environment_name = "preprod" }
  }
}

schedules = {
  "weekdays 6am" = {
    week_days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
    time      = "06:00:00",
    frequency = "week"
  },
  "weekdays 7pm" = {
    week_days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
    time      = "19:00:00",
    frequency = "week"
  }
}
