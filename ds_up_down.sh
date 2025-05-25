#!/bin/bash
if [ $1 = "down" ]; then
  KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n $2 patch daemonset $3 -p '{"spec": {"template": {"spec": {"nodeSelector": {"non-existing": "true"}}}}}'
elif [ $1 = "up" ]; then
  KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n $2 patch daemonset $3 --type json -p='[{"op": "remove", "path": "/spec/template/spec/nodeSelector/non-existing"}]'
fi

