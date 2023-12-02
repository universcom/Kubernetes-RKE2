resource "local_file" "etc_hosts" {
  depends_on = [ openstack_compute_floatingip_associate_v2.LB_floatingIP-associate ]
  filename = "config_files/hosts"
  content = <<-EOF
127.0.0.1 localhosts
%{ for index , instance in openstack_compute_instance_v2.kubernetes_Master_Instances }
${instance.access_ip_v4}  Master${index}.${var.cluster_FQDN} Master${index}
%{ endfor }
%{ for index , instance in openstack_compute_instance_v2.kubernetes_Worker_Instances }
${instance.access_ip_v4}  Worker${index}.${var.cluster_FQDN} Worker${index}
%{ endfor }
${openstack_compute_instance_v2.kubernetes_LB_Instance.access_ip_v4}  LB.${var.cluster_FQDN}  LB
  EOF
}