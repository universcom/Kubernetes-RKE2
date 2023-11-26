# Authentication variables
variable "auth_username" {}
variable "auth_password" {}
variable "auth_tenant" {}
variable "auth_url" {}
variable "auth_region" { default = "RegionOne" }
variable "auth_domain" { default = "default" }


#Openstack Instances Specifications
variable "name" { description = "this value an aribitry name for Openstack objects" }
variable "OS_IMG_ID" {}
variable "OS_flavor_ID" {}
variable "OS_CIDR" {}
variable "OS_DNS" {}
variable "OS_external_network_ID" {}


#Kuberntes Specifications
variable "Number_Of_Masters" {
  type = number
  default = 1
  validation {
    condition = var.Number_Of_Masters % 2 == 1
    error_message = "Number of masters must be odd like 1 or 3 or 5 or .."
  }
}

variable "Number_of_Workers" {
  type = number
  default = 1
  validation {
    condition = var.Number_of_Workers >= 1
    error_message = "You have to have at least 1 worker node"
  }
}

variable "seprated_ETCD" {
  type = bool
  default = false
}

variable "network_type" {
    type = string
    default = "calico"
  
}

variable "Ingress_type" {
    type = string
    default = "nginx"
}

variable "POD_CIDR" {}

variable "Service_CIDR" {}

variable "registry_mirror" {
    type = string
    default = ""
}

#Security_Group ports