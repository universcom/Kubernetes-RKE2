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
  dns_nameservers = ["${var.OS_DNS}"]
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
  depends_on  = [openstack_networking_router_interface_v2.kuberntes_router_interface_1]
  name        = "${var.name}_Server_kuberntes_security_Group"
  description = "for Masters only"
}

resource "openstack_compute_secgroup_v2" "kuberntes_secgroup_share" {
  depends_on  = [openstack_networking_router_interface_v2.kuberntes_router_interface_1]
  name        = "${var.name}_Share_kuberntes_security_Group"
  description = "share between all hosts"
}

resource "openstack_compute_secgroup_v2" "kuberntes_secgroup_lb" {
  depends_on  = [openstack_networking_router_interface_v2.kuberntes_router_interface_1]
  name        = "${var.name}_LB_kuberntes_security_Group"
  description = "for LB only"
}

##### Assign port to security group #####
resource "openstack_networking_secgroup_rule_v2" "kubernetes_secgrouprule_server"{
  depends_on = [openstack_compute_secgroup_v2.kuberntes_secgroup_server]
  count = length(var.RKE-server-ports)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = split("/",var.RKE-server-ports[count.index])[1]
  port_range_min    = split("/",var.RKE-server-ports[count.index])[0] == "1" ? "1" : length(regexall("-", split("/",var.RKE-server-ports[count.index])[0])) > 0 ? split("-",split("/",var.RKE-server-ports[count.index])[0])[0] : split("/",var.RKE-server-ports[count.index])[0] 
  port_range_max    = split("/",var.RKE-server-ports[count.index])[0] == "1" ? "65535" : length(regexall("-", split("/",var.RKE-server-ports[count.index])[0])) > 0 ? split("-",split("/",var.RKE-server-ports[count.index])[0])[1] : split("/",var.RKE-server-ports[count.index])[0]
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
  remote_ip_prefix  = split("/",var.RKE-share-ports[count.index])[1] != "icmp" ? "${var.OS_CIDR}" : "0.0.0.0/0"
  security_group_id = "${openstack_compute_secgroup_v2.kuberntes_secgroup_share.id}"
}

resource "openstack_networking_secgroup_rule_v2" "kubernetes_secgrouprule_lb"{
  depends_on = [openstack_compute_secgroup_v2.kuberntes_secgroup_share]
  count = length(var.RKE-LB-ports)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = split("/",var.RKE-LB-ports[count.index])[1]
  port_range_min    = split("/",var.RKE-LB-ports[count.index])[0] == "1" ? "1" : length(regexall("-", split("/",var.RKE-LB-ports[count.index])[0])) > 0 ? split("-",split("/",var.RKE-LB-ports[count.index])[0])[0] : split("/",var.RKE-LB-ports[count.index])[0] 
  port_range_max    = split("/",var.RKE-LB-ports[count.index])[0] == "1" ? "65535" : length(regexall("-", split("/",var.RKE-LB-ports[count.index])[0])) > 0 ? split("-",split("/",var.RKE-LB-ports[count.index])[0])[1] : split("/",var.RKE-LB-ports[count.index])[0]
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_compute_secgroup_v2.kuberntes_secgroup_lb.id}"
}

######define instance interfaces ######
resource "openstack_networking_port_v2" "kubernetes_Master_Instances_interface" {
  depends_on = [openstack_compute_secgroup_v2.kuberntes_secgroup_server]
  count          = var.Number_Of_Masters
  name           = "Master_port_${count.index}"
  network_id     = openstack_networking_network_v2.kuberntes_network.id
  admin_state_up = true
  security_group_ids = [
    openstack_compute_secgroup_v2.kuberntes_secgroup_server.id,
    openstack_compute_secgroup_v2.kuberntes_secgroup_share.id
  ]
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.kuberntes_subnet.id
  }
}

resource "openstack_networking_port_v2" "kubernetes_Worker_Instances_interface" {
  depends_on = [openstack_compute_secgroup_v2.kuberntes_secgroup_share]
  count          = var.Number_of_Workers
  name           = "Work_port_${count.index}"
  network_id     = openstack_networking_network_v2.kuberntes_network.id
  admin_state_up = true
  security_group_ids = [
    openstack_compute_secgroup_v2.kuberntes_secgroup_share.id
  ]
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.kuberntes_subnet.id
  }
}

resource "openstack_networking_port_v2" "kubernetes_LB_Instance_interface" {
  depends_on = [openstack_compute_secgroup_v2.kuberntes_secgroup_server]
  name           = "LB_port"
  network_id     = openstack_networking_network_v2.kuberntes_network.id
  admin_state_up = true
  security_group_ids = [
    openstack_compute_secgroup_v2.kuberntes_secgroup_server.id,
    openstack_compute_secgroup_v2.kuberntes_secgroup_share.id,
    openstack_compute_secgroup_v2.kuberntes_secgroup_lb.id
  ]
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.kuberntes_subnet.id
  }
}

#####define keypair#####
resource "openstack_compute_keypair_v2" "kubernetes_admin_user_key" {
  name       = "${var.name}"
}

# ##### Get image ID #####
# data "openstack_images_image_v2" "kuberntes_Image_id" {
#   name        = "${var.OS_IMG_ID}"
#   most_recent = true
# }

#create_instances
resource "openstack_compute_instance_v2" "kubernetes_Master_Instances" {
  depends_on = [openstack_compute_keypair_v2.kubernetes_admin_user_key]
  count       = var.Number_Of_Masters 
  name        = "Master-${count.index}"
  image_name  = "${var.OS_IMG_ID}"
  flavor_name = "${var.Master_flavor}"
  key_pair    = openstack_compute_keypair_v2.kubernetes_admin_user_key.name
  network {
    port = openstack_networking_port_v2.kubernetes_Master_Instances_interface[count.index].id
  }
  block_device {
    volume_size           = "${var.volume_root_size}"
    destination_type      = "volume"
    delete_on_termination = true
    source_type           = "image"
    #uuid                  = data.openstack_images_image_v2.kuberntes_Image_id.id
    uuid                  = "${var.OS_IMG_ID}"
  }
}

resource "openstack_compute_instance_v2" "kubernetes_Worker_Instances" {
  depends_on = [openstack_compute_keypair_v2.kubernetes_admin_user_key]
  count       = var.Number_of_Workers 
  name        = "Worker-${count.index}"
  image_name  = "${var.OS_IMG_ID}"
  flavor_name = "${var.Worker_flavor}"
  key_pair    = openstack_compute_keypair_v2.kubernetes_admin_user_key.name
  network {
    port = openstack_networking_port_v2.kubernetes_Worker_Instances_interface[count.index].id
  }
  block_device {
    volume_size           = "${var.volume_root_size}"
    destination_type      = "volume"
    delete_on_termination = true
    source_type           = "image"
    #uuid                  = data.openstack_images_image_v2.kuberntes_Image_id.id
    uuid                  = "${var.OS_IMG_ID}"
  }
 }

resource "openstack_compute_instance_v2" "kubernetes_LB_Instance" {
  depends_on = [openstack_compute_keypair_v2.kubernetes_admin_user_key]
  name        = "LB"
  image_name  = "${var.OS_IMG_ID}"
  flavor_name = "${var.LB_flavor}"
  key_pair    = openstack_compute_keypair_v2.kubernetes_admin_user_key.name
  network {
    port = openstack_networking_port_v2.kubernetes_LB_Instance_interface.id
  }
  block_device {
    volume_size           = "${var.volume_root_size}"
    destination_type      = "volume"
    delete_on_termination = true
    source_type           = "image"
    #uuid                  = data.openstack_images_image_v2.kuberntes_Image_id.id
    uuid                  = "${var.OS_IMG_ID}"
  }
 }

############################ floating IP ############################
#create floating IP
resource "openstack_networking_floatingip_v2" "LB_floatingIP" {
  depends_on = [openstack_networking_router_v2.kuberntes_router]
  pool = "${var.OS_external_network_Name}"
}

#assign floating IP to LB
resource "openstack_compute_floatingip_associate_v2" "LB_floatingIP-associate" {
  depends_on = [ openstack_networking_floatingip_v2.LB_floatingIP ]
  floating_ip = openstack_networking_floatingip_v2.LB_floatingIP.address
  instance_id = openstack_compute_instance_v2.kubernetes_LB_Instance.id
}






