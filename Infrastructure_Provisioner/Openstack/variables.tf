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
variable "OS_CIDR" {}
variable "OS_DNS" {type = string}
variable "OS_external_network_ID" {}
variable "OS_external_network_Name" {}


#Kuberntes Specifications
variable "Worker_flavor" {}
variable "Master_flavor" {}
variable "LB_flavor" {}
variable "volume_root_size" {
  type = string
  default = "20"
}
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

variable "POD_CIDR" {
    type = string
    default = "10.0.1.0/24"
}

variable "Service_CIDR" {
    type = string
    default = "10.0.2.0/24"
}

variable "registry_mirror" {
    type = string
    default = ""
}

#Security_Group ports
variable "RKE-server-ports" {
  type = list
  default = [
    "2379/tcp", "2380/tcp", "2381/tcp",
    "9345/tcp", "6443/tcp"
  ]
}

variable "RKE-share-ports" {
  type = list
  default = [
    "8472/udp", "51820/udp", "51821/udp", "4789/udp",
    "10250/tcp", "9099/tcp", "5473/tcp", "9098/tcp", "179/tcp", "4240/tcp", 
    "2379/tcp", "2380/tcp", "2381/tcp",
    "30000-32767/tcp",
    "1/icmp"
  ]  
}