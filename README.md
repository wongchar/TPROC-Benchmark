# TPROC-Benchmark using MySQL Database

## Install Kubernetes with ContainerD ##
Version at time of writing:
- Ubuntu 22.04
- Kubernetes v1.26.0
- ContainerD v1.6.15

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

- - - -

## Install Docker CE ##

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
