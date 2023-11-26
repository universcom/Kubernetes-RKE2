#####Create Router#####
resource "openstack_networking_router_v2" "kuberntes_router" {
  name                = "${var.name}_kuberntes_router"
  admin_state_up      = true
  external_network_id = "${var.OS_external_network_ID}"
}

#####Create network#####
resource "openstack_networking_network_v2" "kuberntes_network" {
  depends_on = [openstack_networking_router_v2.kuberntes_router]
  name              = "${var.name}_kubernetes_Instance_Network"
  admin_state_up    = "true"
}

#####Create subnet#####
resource "openstack_networking_subnet_v2" "kuberntes_subnet" {
  depends_on = [openstack_networking_network_v2.kuberntes_network]
  name       = "${var.name}_kubernetes_Instance_Subnet"
  network_id = "${openstack_networking_network_v2.kuberntes_network.id}"
  cidr       = "${var.OS_CIDR}"
#   allocation_pool{
#     start = "${var.cidr-start_ip}"
#     end   = "${var.cidr-end_ip}"
#   }
  dns_nameservers = "${var.OS_DNS}"
  ip_version = 4
}

#####attach network to router#####
resource "openstack_networking_router_interface_v2" "kuberntes_router_interface_1" {
  depends_on = [openstack_networking_subnet_v2.kuberntes_subnet]
  router_id = "${openstack_networking_router_v2.kuberntes_router.id}"
  subnet_id = "${openstack_networking_subnet_v2.kuberntes_subnet.id}"
}

##### define security group #####
resource "openstack_compute_secgroup_v2" "kuberntes_secgroup_server" {
  depends_on = [openstack_networking_router_interface_v2.DBaaS_router_interface_1]
  name        = "${var.name}_Server_kuberntes_security_Group"
}

resource "openstack_compute_secgroup_v2" "kuberntes_secgroup_share" {
  depends_on = [openstack_networking_router_interface_v2.DBaaS_router_interface_1]
  name        = "${var.name}_Share_kuberntes_security_Group"
}

##### Assign port to security group #####
resource "openstack_networking_secgroup_rule_v2" "kubernetes_secgrouprule_server"{
  depends_on = [openstack_compute_secgroup_v2.kuberntes_secgroup_server]
  count = length(var.RKE-server-ports)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = split("/",var.RKE-server-ports[count.index])[1]
  port_range_min    = split("/",var.RKE-share-ports[count.index])[0] == "1" ? "1" : length(regexall("-", split("/",var.RKE-share-ports[count.index])[0])) > 0 ? split("-",split("/",var.RKE-share-ports[count.index])[0])[0] : split("/",var.RKE-share-ports[count.index])[0] 
  port_range_max    = split("/",var.RKE-share-ports[count.index])[0] == "1" ? "65535" : length(regexall("-", split("/",var.RKE-share-ports[count.index])[0])) > 0 ? split("-",split("/",var.RKE-share-ports[count.index])[0])[1] : split("/",var.RKE-share-ports[count.index])[0]
  remote_ip_prefix  = "${var.OS_CIDR}"
  security_group_id = "${openstack_compute_secgroup_v2.kuberntes_secgroup_server.id}"
}

resource "openstack_networking_secgroup_rule_v2" "kubernetes_secgrouprule_share"{
  depends_on = [openstack_compute_secgroup_v2.kuberntes_secgroup_share]
  count = length(var.RKE-share-ports)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = split("/",var.RKE-share-ports[count.index])[1]
  port_range_min    = split("/",var.RKE-share-ports[count.index])[0] == "1" ? "1" : length(regexall("-", split("/",var.RKE-share-ports[count.index])[0])) > 0 ? split("-",split("/",var.RKE-share-ports[count.index])[0])[0] : split("/",var.RKE-share-ports[count.index])[0] 
  port_range_max    = split("/",var.RKE-share-ports[count.index])[0] == "1" ? "65535" : length(regexall("-", split("/",var.RKE-share-ports[count.index])[0])) > 0 ? split("-",split("/",var.RKE-share-ports[count.index])[0])[1] : split("/",var.RKE-share-ports[count.index])[0]
  remote_ip_prefix  = "${var.OS_CIDR}"
  security_group_id = "${openstack_compute_secgroup_v2.kuberntes_secgroup_share.id}"
}

######define instance interfaces ######
resource "openstack_networking_port_v2" "kubernetes_Master_Instances_interface" {
  depends_on = [openstack_compute_secgroup_v2.kuberntes_secgroup_server]
  count          = var.Number_Of_Masters
  name           = "Master_port_${count.index}"
  network_id     = openstack_networking_network_v2.kuberntes_network.id
  admin_state_up = true
  security_group_ids = [
    openstack_compute_secgroup_v2.server.id,
    openstack_compute_secgroup_v2.share.id
  ]
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.kubernetes_Instance_Subnet.id
  }
}

resource "openstack_networking_port_v2" "kubernetes_Agent_Instances_interface" {
  depends_on = [openstack_compute_secgroup_v2.kuberntes_secgroup_share]
  count          = var.Number_of_Workers
  name           = "Work_port_${count.index}"
  network_id     = openstack_networking_network_v2.kuberntes_network.id
  admin_state_up = true
  security_group_ids = [
    openstack_compute_secgroup_v2.share.id
  ]
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.kubernetes_Instance_Subnet.id
  }
}

resource "openstack_networking_port_v2" "kubernetes_Master_Instances_interface" {
  depends_on = [openstack_compute_secgroup_v2.kuberntes_secgroup_server]
  name           = "LB_port"
  network_id     = openstack_networking_network_v2.kuberntes_network.id
  admin_state_up = true
  security_group_ids = [
    openstack_compute_secgroup_v2.server.id,
    openstack_compute_secgroup_v2.share.id
  ]
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.kubernetes_Instance_Subnet.id
  }
}