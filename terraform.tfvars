# would have array of obj but that creates some ugly syntax when calling the var with for_each
# e.g. https://stackoverflow.com/questions/58594506/how-to-for-each-through-a-listobjects-in-terraform-0-12

automation_accounts = { # each named after resource group
  t2-oasys = {
    job_schedules = [
      {
        schedule = "weekdays 7am"
        script   = "start-vms"
      },
      {
        schedule = "weekdays 7pm"
        script   = "stop-vms"
      }
    ]
  }
}