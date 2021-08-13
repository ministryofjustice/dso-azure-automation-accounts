terraform {
  backend "azurerm" {
    subscription_id      = "b1f3cebb-4988-4ff9-9259-f02ad7744fcb" # NOMS Dev & Test Environments
    tenant_id            = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
    resource_group_name  = "dso-terraform-state"
    storage_account_name = "dsoautomationaccounts"
    container_name       = "automation-accounts-tfstate"
    key                  = "terraform.tfstate"
  }
}