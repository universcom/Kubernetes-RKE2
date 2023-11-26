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
resource "openstack_compute_secgroup_v2" "kuberntes_secgroup" {
  depends_on = [openstack_networking_router_interface_v2.DBaaS_router_interface_1]
  name        = "${var.name}_kuberntes_security_Group"
}