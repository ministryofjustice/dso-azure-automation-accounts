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
}

schedules = {
}
