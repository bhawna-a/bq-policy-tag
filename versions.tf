
terraform {
  backend "local" {
    path = "state/terraform.tfstate"
  }

  required_providers {
    external = {
      source = "hashicorp/external"
    }
    google = {
      source  = "hashicorp/google"
      version = "5.2.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 1.0"
}
