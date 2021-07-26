# dso-azure-automation-accounts

discussion on making shutdown automation this way https://github.com/ministryofjustice/dso-infra-azure-fixngo/pull/48

# How to use repo
- add to terraform.tfvars
- MANGED IDENTITY NEEDS TO BE DONE MANUALLY - TF isn't able to do this yet. Add the system managed identity through the UI and give relevant permissions.


## FUNCTIONALITY WE COULD ADD

start stop in sequence: https://docs.microsoft.com/en-us/azure/automation/automation-solution-vm-management-config#tags


## PROBLEMS

### USING UTC AND NOT LOCAL TIME
TL;DR
horrible code to deal with timezones vs UTC that has 1 hour less shutdown time and 1/12 less savings

If we were to use the local time, the problem is BST
azure doesn't have a good way of dealing with this - you need to specify the start time in this format
2014-04-15T18:00:15+02:00
terraform isn't aware of different timezones. timestamp() returns UTC only, and formatdate() can only change the form, it doesn't know when it's BST and when it's not
SO! if we were to go down this path there are a few solutions
1.
use terraform to run a bash script locally, save it too a file locally (because you can't get outputs with local-exec), then read the local file in terraform to then use as a var
resource "null_resource" "thing" {
  provisioner "local-exec" {
      command = "TZ=Europe/London date --iso-8601=seconds >> thing.txt"
  }
}

2.
use external data source - terraform advises against https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/data_source

3.
just use UTC. pulling it back an hour and for half of the year shutting down servers an hour later, and the other half of the year starting up servers an hour earlier
resulting in less savings but simpler code


### MANAGED IDENTITY NOT IN TF
This discusses the limitations of not being able to add runasaccount in TF https://github.com/terraform-providers/terraform-provider-azurerm/issues/4431
The only half decent way around this would be to
 - create a service principal/s in azure-ad repo
 - add the ability to create service principals with certs from keyvault
Although: 
 - the automation account having a managed identity would be better, less maintenance etc (unable to do through TF as of 14/7/21)
 - this would be a new thing the team would need to have understanding of
 Therefore, seems not worth going through all this hassle and instead for each automation account manually toggling managed_identity until TF gains this capability


