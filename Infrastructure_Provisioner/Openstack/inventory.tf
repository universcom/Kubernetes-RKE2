resource "local_file" "anisble_inventory" {
  depends_on = [ openstack_compute_floatingip_associate_v2.LB_floatingIP-associate ]
  filename = "config_files/ansible_inventory.ini"
  content = <<-EOF
[all]
localhost  ansible_host=127.0.0.1
%{ for index , instance in openstack_compute_instance_v2.kubernetes_Master_Instances }
master${index}.${var.cluster_FQDN}  ansible_host=${instance.access_ip_v4}
%{ endfor}
%{ for index , instance in openstack_compute_instance_v2.kubernetes_Worker_Instances }
worker${index}.${var.cluster_FQDN}  ansible_host=${instance.access_ip_v4}
%{ endfor}
lb.${var.cluster_FQDN}  ansible_host=${openstack_compute_instance_v2.kubernetes_LB_Instance.access_ip_v4}

[all:vars]
ansible_ssh_user=ubuntu
ansible_port=22
  EOF
}