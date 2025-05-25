# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl nfs-common  # nfs-common needed for nfs-client storage class
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# install docker/containerd
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# install kubelet kubeadm kubectl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# install nvidia-container-toolkit and make it default runtime

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt update && sudo apt install nvidia-container-toolkit -y
cat << EOF > /etc/containerd/config.toml
version = 2

[plugins]

  [plugins."io.containerd.grpc.v1.cri"]

    [plugins."io.containerd.grpc.v1.cri".containerd]
      default_runtime_name = "nvidia"

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]

        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
          privileged_without_host_devices = false
          runtime_engine = ""
          runtime_root = ""
          runtime_type = "io.containerd.runc.v2"

          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia.options]
            BinaryName = "/usr/bin/nvidia-container-runtime"
            systemdCgroup = true
EOF	    
sudo service containerd restart

sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
# install nginx for load balancing
sudo apt install nginx-light libnginx-mod-stream -y

cat << EOF > /etc/nginx/nginx.conf
error_log stderr notice;
load_module /lib/nginx/modules/ngx_stream_module.so;

worker_processes auto;
worker_rlimit_nofile 130048;
worker_shutdown_timeout 10s;

events {
  multi_accept on;
  use epoll;
  worker_connections 16384;
}

stream {
  upstream kube_apiserver {
    least_conn;
    server 127.0.0.1:6443;
    server 10.239.10.222:6443;
    server 10.239.10.223:6443;
    }

  server {
    listen        127.0.0.1:8080;
    proxy_pass    kube_apiserver;
    proxy_timeout 10m;
    proxy_connect_timeout 1s;
  }
}

http {
  aio threads;
  aio_write on;
  tcp_nopush on;
  tcp_nodelay on;

  keepalive_timeout 5m;
  keepalive_requests 100;
  reset_timedout_connection on;
  server_tokens off;
  autoindex off;

  server {
    listen 8081;
    location /healthz {
      access_log off;
      return 200;
    }
    location /stub_status {
      stub_status on;
      access_log off;
    }
  }
  }
EOF

sudo service nginx restart
kubeadm init --upload-certs --control-plane-endpoint=127.0.0.1:8080

kubeadm join 127.0.0.1:8080 --token e01u52.c9uq77rkvl3qm86u --discovery-token-ca-cert-hash sha256:a7fc076bdcd7391e8bc7577b54ecc492d319298b5699293f8390042b57866700 --control-plane --certificate-key 2931030dff3041c185715298ab833895c6f36028a97b2f139857641bbe7f66b5  # master

kubeadm join 127.0.0.1:8080 --token e01u52.c9uq77rkvl3qm86u    --discovery-token-ca-cert-hash sha256:a7fc076bdcd7391e8bc7577b54ecc492d319298b5699293f8390042b57866700  # worker

# install cilium
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

cilium install --version 1.15.1

# taint masters
kubectl taint nodes ml-cbt-02 ml-cbt-03 node-role.kubernetes.io/control-plane:NoSchedule-# install tools

# install tools
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash   # helm
helm plugin install https://github.com/databus23/helm-diff  # helm-diff needed for helmfile



