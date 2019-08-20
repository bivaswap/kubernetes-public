apt-get update && apt-get install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

apt-get update && apt-get install docker-ce=5:18.09.8~3-0~ubuntu-bionic docker-ce-cli=5:18.09.8~3-0~ubuntu-bionic
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl restart docker
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl docker-ce docker-ce-cli
systemctl enable kubelet
systemctl start kubelet

kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=Swap,FileContent--proc-sys-net-bridge-bridge-nf-call-iptables,SystemVerification >> /root/kubeinit.log 2>&1
mkdir /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml > /dev/null 2>&1

# Generate Cluster join command
echo "[TASK 12] Generate and save cluster join command to /joincluster.sh"
joinCommand=$(kubeadm token create --print-join-command) 
echo "$joinCommand --ignore-preflight-errors=Swap,FileContent--proc-sys-net-bridge-bridge-nf-call-iptables,SystemVerification" > /joincluster.sh
