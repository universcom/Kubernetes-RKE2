resource "local_file" "nginx" {
  depends_on = [ openstack_compute_instance_v2.kubernetes_LB_Instance ]
  filename = "config_files/nginx.conf"
  content = <<-EOF
user www-data;
worker_processes 4;
worker_rlimit_nofile 40000;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;
load_module /usr/lib/nginx/modules/ngx_stream_module.so;

# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 8192;
}

stream {
upstream backend {
        least_conn;
        %{ for ip in openstack_compute_instance_v2.kubernetes_Master_Instances }
        server "${ip.access_ip_v4}":9345 max_fails=3 fail_timeout=5s;
        %{ endfor }
   }

   # This server accepts all traffic to port 9345 and passes it to the upstream. 
   # Notice that the upstream name and the proxy_pass need to match.
   server {

      listen 9345;

          proxy_pass backend;
   }
    upstream rancher_api {
        least_conn;
        %{ for ip in openstack_compute_instance_v2.kubernetes_Master_Instances }
        server "${ip.access_ip_v4}":6443 max_fails=3 fail_timeout=5s;
        %{ endfor }
    }
        server {
        listen     6443;
        proxy_pass rancher_api;
        }
    upstream rancher_http {
        least_conn;
        %{ for ip in openstack_compute_instance_v2.kubernetes_Master_Instances }
        server "${ip.access_ip_v4}":80 max_fails=3 fail_timeout=5s;
        %{ endfor }
    }
        server {
        listen     80;
        proxy_pass rancher_http;
        }
    upstream rancher_https {
        least_conn;
        %{ for ip in openstack_compute_instance_v2.kubernetes_Master_Instances }
        server "${ip.access_ip_v4}":443 max_fails=3 fail_timeout=5s;
        %{ endfor }
    }
        server {
        listen     443;
        proxy_pass rancher_https;
        }
}
  EOF
}