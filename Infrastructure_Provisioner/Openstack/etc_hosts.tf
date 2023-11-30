resource "local_file" "nginx" {
  depends_on = [ openstack_compute_floatingip_associate_v2.LB_floatingIP-associate ]
  filename = "config_files/hosts"
  content = <<-EOF
127.0.0.1 localhosts
%{ for index , instance in Master_nodes }
${instance.access_ip_v4}  Master${index}.${cluster_FQDN} Master${index}
%{ endfor }
%{ for index , instance in Worker_nodes }
${instance.access_ip_v4}  Worker${index}.${cluster_FQDN} Worker${index}
%{ endfor }
${LB_node.access_ip_v4}  LB.${cluster_FQDN}  LB
  EOF
}