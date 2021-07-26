# would have array of obj but that creates some ugly syntax when calling the var with for_each
# e.g. https://stackoverflow.com/questions/58594506/how-to-for-each-through-a-listobjects-in-terraform-0-12

# adding
#   some-resourcegroup {}
# will set up shutdown/startup automation at 7pm, 6am UTC respectively

automation_accounts = { # each named after resource group
  t2-oasys = {}
}