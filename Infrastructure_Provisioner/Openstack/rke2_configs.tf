resource "local_file" "rke2_configs" {
  depends_on = [ openstack_compute_floatingip_associate_v2.LB_floatingIP-associate ]
  filename = "config_files/rke2_config.yaml"
  content = <<-EOF
write-kubeconfig-mode: "0644"
tls-san:
 - LB.${cluster_FQDN}
 - ${LB_node.access_ip_v4}
  EOF
}

