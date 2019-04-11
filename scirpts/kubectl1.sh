kubectl create -f skydns-svc.yaml

yum install -y yum-utils device-mapper-persistent-data lvm2
tee /etc/docker/daemon.json <<-'EOF'
{
 "registry-mirrors": ["https://we8dvwud.mirror.aliyuncs.com"],
 "iptables": false,
 "ip-masq": false,
 "storage-driver": "overlay2",
 "graph": "/app/dcos/docker"
}
EOF

tee /etc/yum.repos.d/kubernetes.repo <<-'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
EOF\

kubeadm init --apiserver-advertise-address=10.201.83.99 --pod-network-cidr=192.168.0.0/16  --kubernetes-version=v1.12.0


Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join 10.201.83.99:6443 --token bm5q1q.b9c58zl48u65w3sm --discovery-token-ca-cert-hash sha256:bab1c7e63352226c9ea11475b9ab89f659d4dbaf543409d39f626cf8474af9ea

