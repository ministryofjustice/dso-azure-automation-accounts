# dso-azure-automation-accounts

discussion on making shutdown automation this way https://github.com/ministryofjustice/dso-infra-azure-fixngo/pull/48

# How to use this repo
For a resource group you want to apply shutdown automation to :
- Add ordering/disabling tags to vms - sequence_start, sequence_stop, shutdown_exclude (tag info in section below)
- under the relevant subscription folder in this repo add resource group to terraform.tfvars
- when tf looks good, apply. This will create everything except sorting out modules (couldn't get to work in tf) and identity (can't do in tf at the moment)
- UPDATING AZURERM - https://www.powershellgallery.com/packages/AzureRM -> azure automation -> deploy to azure automation -> select new automation account
- MANGED IDENTITY - TF isn't able to do this yet. Add the system managed identity through the UI (go to the automation account -> identity -> status on -> add contrib role to resource group)

# Configuration
## Tags

### Disable
To disable the shutdown automation add the tag `shutdown_exclude` to the VM you want to exclude.

E.g.
```
shutdown_exclude : true
```

### Ordering

There are a number of tags that exist to control the ordering of the shutdown process, they are `sequence_start` and `sequence_stop`.

The values of the tags `sequence_start` and `sequence_stop` can be some number, and can optionally have a `_series` suffix if the shutdown operation is required to be carried out in series instead of in parallel.

E.g.

`sequence_start = 3_series` 
  - Will be in the 3rd batch to start
  - Will start all of the batch `3` VMs one-by-one

`sequence_stop = 2` 
  - will be in the 2nd batch to stop
  - will stop the whole batch at the same time 

If hosts in the same RG had inconsistent tagging, e.g. a mix of '3_series' and '3'; the `3` group would be run in parallel, then the `3_series` group would be run.

## EXAMPLE TAG COMMANDS

### replace all tags with new set
```
az tag update --resource-id /subscriptions/<sub id>/resourcegroups/<resource group name>/providers/Microsoft.Compute/virtualMachines/<vm name>	--operation Replace --tags key1=value1 ...
```

### add/update tags
```
az tag update --resource-id /subscriptions/<sub id>/resourcegroups/<resource group name>/providers/Microsoft.Compute/virtualMachines/<vm name> --operation merge --tags key1=value1 key3=value3
```

### add exclude tag
```
az tag update --resource-id /subscriptions/<sub id>/resourcegroups/<resource group name>/providers/Microsoft.Compute/virtualMachines/<vm name> --operation merge --tags shutdown_exclude=true
```

### set shutdown order tags
```
az tag update --resource-id /subscriptions/<sub id>/resourcegroups/<resource group name>/providers/Microsoft.Compute/virtualMachines/<vm name> --operation merge --tags sequence_start=1_series sequence_stop=2
```


## DECISIONS & PROBLEMS

### USING UTC AND NOT LOCAL TIME
TL;DR
horrible code to deal with timezones vs UTC that has 1 hour less shutdown time and 103/108 of the savings
Chose UTC

If we were to use the local time, the problem is BST
azure doesn't have a good way of dealing with this - you need to specify the start time in this format
2014-04-15T18:00:15+02:00
terraform isn't aware of different timezones. timestamp() returns UTC only, and formatdate() can only change the form, it doesn't know when it's BST and when it's not
SO! if we were to go down this path there are a few solutions:

1. use terraform to run a bash script locally, save it to a file locally (because you can't get outputs with local-exec), then read the local file in terraform to then use as a var
resource "null_resource" "thing" {
  provisioner "local-exec" {
      command = "TZ=Europe/London date --iso-8601=seconds >> thing.txt"
  }
}

2. use external data source - terraform advises against https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/data_source

3. just use UTC. pulling it back an hour and for half of the year shutting down servers an hour later, and the other half of the year starting up servers an hour earlier
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
