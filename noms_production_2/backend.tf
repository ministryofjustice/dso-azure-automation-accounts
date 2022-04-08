terraform {
  backend "azurerm" {
    subscription_id      = "1d95dcda-65b2-4273-81df-eb979c6b547b"
    tenant_id            = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
    resource_group_name  = "dso-terraform-state"
    storage_account_name = "dsotfstateprod"
    container_name       = "dso-azure-automation-accounts"
    key                  = "noms_production_2/terraform.v1.tfstate"
  }
}
