# TPROC-Benchmark using MySQL Database

## Create Striped LVM ##

Ensure BIOS setting is set to NPS=1 \
Ensure NVMEs are physically installed so there are equal quantities on each NUMA node (if using 2-socket system) \


## Install Kubernetes with ContainerD ##
Version at time of writing:
- Ubuntu 22.04
- Kubernetes v1.26.0
- ContainerD v1.6.15

Load br_netfilter module
```console
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
```

Allow iptables to see bridged traffic
```console
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
```

Apply settings
```console
sudo sysctl --system
```

Install ContainerD

```console
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update -y 
sudo apt install -y containerd.io
```

Setup default config file for ContainerD
```console
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
```

Set cgroupDriver to systemd in configuration file
```console
sudo vi /etc/containerd/config.toml
```

Search using the following command: /SystemdCgroup \
Change **SystemdCgroup = false** to **SystemdCgroup = true** \
Ensure your section matches the following:

```
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    BinaryName = ""
    CriuImagePath = ""
    CriuPath = ""
    CriuWorkPath = ""
    IoGid = 0
    IoUid = 0
    NoNewKeyring = false
    NoPivotRoot = false
    Root = ""
    ShimCgroup = ""
    SystemdCgroup = true
```

Restart ContainerD
```
sudo systemctl restart containerd
```

Install Kubernetes
```
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update -y
sudo apt install -y kubelet kubeadm kubectl
```

Add hostnames and IP address of ALL nodes that will be on the cluster to **/etc/hosts** file for all nodes
```
vi /etc/hosts
```

An example of a host file for a 2-node cluster below:

```
127.0.0.1 localhost
10.216.179.66 ubuntu2004-milan-001
10.216.177.81 titanite-d4c2-os

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

Disable swap on every node
```
sudo swapoff –a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

Initialze control plane (make sure to record the output of kubeadm init if you want to add nodes to your K8s cluster)
```
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
```

Configure kubectl
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Set up CNI using Calico
```
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/custom-resources.yaml
```

Verify all pods are running
 ```
kubectl get pods -A
```

Output should look like the following
```console
amd@titanite-d4c2-os:~$ kubectl get pods -A
NAMESPACE          NAME                                       READY   STATUS    RESTARTS   AGE
calico-apiserver   calico-apiserver-76b945d94f-2xnqj          1/1     Running   0          22s
calico-apiserver   calico-apiserver-76b945d94f-dm24c          1/1     Running   0          22s
calico-system      calico-kube-controllers-6b7b9c649d-wrbjj   1/1     Running   0          55s
calico-system      calico-node-v8xhj                          1/1     Running   0          55s
calico-system      calico-typha-7ff787f77b-6vwmp              1/1     Running   0          55s
calico-system      csi-node-driver-d5qtc                      2/2     Running   0          55s
kube-system        coredns-787d4945fb-7m5pz                   1/1     Running   0          87s
kube-system        coredns-787d4945fb-fr5d8                   1/1     Running   0          87s
kube-system        etcd-titanite-d4c2-os                      1/1     Running   0          102s
kube-system        kube-apiserver-titanite-d4c2-os            1/1     Running   0          101s
kube-system        kube-controller-manager-titanite-d4c2-os   1/1     Running   0          100s
kube-system        kube-proxy-c2rqb                           1/1     Running   0          87s
kube-system        kube-scheduler-titanite-d4c2-os            1/1     Running   0          101s
tigera-operator    tigera-operator-54b47459dd-fq8kk           1/1     Running   0          67s
```

OPTION: If you want to schedule pods on the control-plane, use the following command
```
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

OPTION: If creating a multi-node cluster, use output command provided by kubeadm init on another node to add to the K8s cluster. \
Below is an example of join token for a worker node (NOTE: USE THE ONE PROVIDED BY YOUR KUBEADM INIT AND NOT THE EXAMPLE)
```
sudo kubeadm join 10.216.177.81:6443 --token pxskra.4lurssigp18i3h4v \
        --discovery-token-ca-cert-hash sha256:af6d5360b3874f31db97c8c0bc749821c17c65003a72b2c95a1dd6d0ceabd4f
```

- - - -

## Install Docker CE ##
https://docs.docker.com/engine/install/ubuntu/
- - - -

## Setup HammerDB TPROC-C MySQL Database for SUT ##

Pull public MySQL container image using docker (v8.0.17 at time of writing)
```console
docker pull mysql:8.0.17
```

Save MySQL docker image as .tar file
```console
docker save mysql:8.0.17 > mysql.tar
```
 
Import MySQL container image to ContainerD K8s namespace 
 ```console
 sudo ctr -n=k8s.io image import mysql.tar
```

docker.io/library/mysql:8.0.17

Go to mysql folder in repository
```console
cd TRPOC-Benchmark/mysql
```

>Set the desired memory size for your MySQL database
```console
vi conf.d/my.cnf
>> Specify the memory size here (currently set to 24GB):
```console
innodb_buffer_pool_size=24G
```

## Setup HammerDB TPROC for Load Generator ##

Clone the HammerDB repository
```console
git clone https://github.com/TPC-Council/HammerDB.git
```
