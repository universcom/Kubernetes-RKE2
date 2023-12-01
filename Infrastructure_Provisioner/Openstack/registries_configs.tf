resource "local_file" "registries_configs" {
  depends_on = [ openstack_compute_floatingip_associate_v2.LB_floatingIP-associate ]
  filename = "config_files/rke2_registries.yaml"
  content = <<-EOF
mirrors:
  docker.io:
    endpoint:
      - "${var.registry_mirror}"
  EOF
}