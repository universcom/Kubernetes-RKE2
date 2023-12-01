resource "local_file" "anisble_inventory" {
  depends_on = [ openstack_compute_floatingip_associate_v2.LB_floatingIP-associate ]
  filename = "config_files/ansible_inventory.ini"
  content = <<-EOF
[all]
localhost  ansible_host=127.0.0.1
%{ for index , instance in Master_nodes }
master${index}.${cluster_FQDN}  ansible_host=${instance.access_ip_v4}
%{ endfor}
%{ for index , instance in Worker_nodes }
worker${index}.${cluster_FQDN}  ansible_host=${instance.access_ip_v4}
%{ endfor}
lb${index}.${cluster_FQDN}  ansible_host=${instance.access_ip_v4}

[all:vars]
ansible_ssh_user=ubuntu
ansible_port=22
  EOF
}