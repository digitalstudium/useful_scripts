nala install -y sssd-ldap sssd-tools ldap-utils
mkdir /etc/ldap/ca/
#vim /etc/ldap/ca/ninv.crt
#vim /etc/ldap/ldap.conf
#vim /etc/hosts
#vim /etc/sssd/sssd.conf
chmod 600 /etc/sssd/sssd.conf
pam-auth-update --enable mkhomedir
service sssd restart
nala install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
nala update
nala install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
nala install -y containerd
swapoff -a
#vim /etc/fstab 
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
kubeadm join 10.239.10.221:6443 --token z51k9o.144c6ntyob9ut43y --discovery-token-ca-cert-hash sha256:baaa860fb0cf4007b31979e0e21fdc45ec12ad2857aba3a82b63ec26044da597
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
nala update && nala install nvidia-driver-535 nvidia-cuda-toolkit nvidia-container-toolkit -y
nvidia-ctk runtime configure --runtime=containerd
service containerd restart

