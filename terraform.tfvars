# would have array of obj but that creates some ugly syntax when calling the var with for_each
# e.g. https://stackoverflow.com/questions/58594506/how-to-for-each-through-a-listobjects-in-terraform-0-12

# adding
#   some-resourcegroup {}
# will set up shutdown/startup automation at 7pm, 6am UTC respectively

automation_accounts = { # each named after resource group
  t2-oasys          = {},
  nomis-bip-lsast   = {},
  nomis-bip-preprod = {},
  nomis-bip-t1      = {}
}

schedules = {
  "weekdays 6am" = {
    week_days     = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
    time          = "06:00:00",
    frequency     = "week"
  },
  "weekdays 7pm" = {
    week_days     = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
    time          = "19:00:00",
    frequency     = "week"
  }
}