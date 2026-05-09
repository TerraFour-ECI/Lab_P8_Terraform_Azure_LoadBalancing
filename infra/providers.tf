# =============================================================================
#  Terraform & Provider Configuration
# -----------------------------------------------------------------------------
#  - Pins Terraform >= 1.6 to guarantee compatibility with the language
#    features used across the modules (optional object attributes, etc.).
#  - Pins the AzureRM provider on the v4.x line; the actual locked version
#    lives in `.terraform.lock.hcl` and must not be edited by hand.
#  - The `backend "azurerm" {}` block is intentionally empty: the real values
#    are injected at `terraform init` time via `-backend-config=backend.hcl`,
#    which keeps subscription/account names out of source control.
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}
