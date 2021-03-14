#!/bin/bash

###############################################
#  MAKE SURE MASTER HAS ATLEAST 2GB+ RAM      #
#  MAKE SURE HOSTNAME CONTAIN 'master' WORD   #
###############################################

sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
# sudo ln -s /dev/console /dev/kmsg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt-get install -y docker-ce=5:19.03.15~3-0~ubuntu-focal docker-ce-cli=5:19.03.15~3-0~ubuntu-focal containerd.io
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl restart docker
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt update


if [[ $(hostname) =~ .*master.* ]]
then
    sudo apt install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl docker
    #sudo kubeadm init --apiserver-advertise-address=`hostname --ip-address | awk '{print $2}'` --pod-network-cidr=10.244.0.0/16
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16
    sudo mkdir /root/.kube
    mkdir -p $HOME/.kube
    sudo cp /etc/kubernetes/admin.conf /root/.kube/config
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
fi

###############################################
#  MAKE SURE MASTER HAS ATLEAST 2GB RAM       #
#  MAKE SURE HOSTNAME CONTAIN 'worker' WORD   #
###############################################

if [[ $(hostname) =~ .*worker.* ]]
then
    sudo apt install -y kubelet kubeadm
    sudo apt-mark hold kubelet docker
fi
