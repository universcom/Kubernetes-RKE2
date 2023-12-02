resource "null_resource" "init_LB" {
  depends_on = [
  module.lunch_instances
  ]
  #connect to instances with ssh
  connection {
    type = "ssh"
    user = "ubuntu"
    timeout = "5m"
    private_key = "${openstack_compute_keypair_v2.kubernetes_admin_user_key.private_key}"
    host = "${openstack_compute_instance_v2.kubernetes_LB_Instance.floating_ip}"
    port = "22"
  }
  provisioner "remote-exec" {
    inline = [ 
        "sudo apt update",
        "sudo apt install nginx",
        "sudo chown ubuntu:root -R /etc/nginx/*", 
        "sudo chown ubuntu:root -R /etc/etc/hosts",
        "sudo ssh-keygen && sudo echo ${openstack_compute_keypair_v2.kubernetes_admin_user_key.private_key} > /root/.ssh/id_rsa"
     ]
  }
  #Copy required files to destination hosts
  provisioner "file" {
    source = "config_files/hosts"
    destination = "/etc/hosts"
  }

  provisioner "file" {
    source = "config_files/nginx.conf"
    destination = "/etc/nginx/nginx.conf"
    }

  provisioner "remote-exec" {
    inline = [ "sudo service nginx reload" ]
  }
}