terraform {
  backend "azurerm" {
    subscription_id      = "1d95dcda-65b2-4273-81df-eb979c6b547b" # NOMS Production 1
    tenant_id            = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
    resource_group_name  = "dso-terraform-state"
    storage_account_name = "dsoautomationaccounts"
    container_name       = "automation-accounts-tfstate"
    key                  = "terraform.tfstate"
  }
}
