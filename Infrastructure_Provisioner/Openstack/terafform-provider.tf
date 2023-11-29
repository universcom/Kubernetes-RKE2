# Define required providers
terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
  }
}

# Configure the OpenStack Provider
provider "openstack" {
  user_name    = var.auth_username
  tenant_name  = var.auth_tenant
  password     = var.auth_password
  auth_url     = var.auth_url
  region       = var.auth_region
  domain_name  = var.auth_domain
}

output "terraform-provider" {
    value = "Connected with openstack at ${var.auth_url}"
  
}