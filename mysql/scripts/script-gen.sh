#!/bin/bash

if [ $# -ne 2 ]
then
  echo "Usage: $0 path count"
  exit 2
fi

PATH=$1

for ((I=9; I<=$2; I++))
do
  /bin/cat <<EOF
---
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: comm${I}
spec:
  config: '{
          "cniVersion": "0.4.0",
          "plugins": [
            {
              "type": "macvlan",
              "capabilities": { "ips": true },
              "master": "enp129s0f0np0",
              "mode": "bridge",
              "ipam": {
                "type": "static",
                "addresses": [
                  {
                    "address": "192.78.1.${I}/24"
                  }
                ]
              }
            }
          ]    
  }'
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tpc-db${I}
  labels:
    app: tpc-db${I}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tpc-db${I}
  template:
    metadata:
      annotations:
        k8s.v1.cni.cncf.io/networks: comm${I}
      labels:
        app: tpc-db${I}
    spec:
      containers:
      - name: tpc-db${I}
        image: mysql:8.0.31
        resources:
          limits:
            cpu: 16
            memory: 22Gi
          requests:
            cpu: 16
            memory: 22Gi
        ports:
        - containerPort: 3306
        env:
          - name: MYSQL_DATABASE
            value: tpc
          - name: MYSQL_PASSWORD
            value: password
          - name: MYSQL_ROOT_PASSWORD
            value: password
          - name: MYSQL_SOCKET_DIR
            value: '"/var/lib/mysql/sock"'
        volumeMounts:
          - name: tpc-db${I}-conf
            mountPath: /etc/mysql/conf.d
          - name: tpc-db${I}-vol
            mountPath: /var/lib/mysql
      restartPolicy: Always
      volumes:
        - name: tpc-db${I}-conf
          hostPath:
            path: /$PATH/conf.d
        - name: tpc-db${I}-vol
          hostPath:
            path: /$PATH/db${I}
EOF
done
