# dso-azure-automation-accounts

discussion on making shutdown automation this way https://github.com/ministryofjustice/dso-infra-azure-fixngo/pull/48

# How to use repo
- add to terraform.tfvars
- MANGED IDENTITY NEEDS TO BE DONE MANUALLY - TF isn't able to do this yet. Add the system managed identity through the UI and give relevant permissions.

## PROBLEMS

This discusses the limitations of not being able to add runasaccount in TF https://github.com/terraform-providers/terraform-provider-azurerm/issues/4431
The only half decent way around this would be to
 - create a service principal/s in azure-ad repo
 - add the ability to create service principals with certs from keyvault
Although: 
 - the automation account having a managed identity would be better, less maintenance etc (unable to do through TF as of 14/7/21)
 - this would be a new thing the team would need to have understanding of
 Therefore, seems not worth going through all this hassle and instead for each automation account manually toggling managed_identity until TF gains this capability


