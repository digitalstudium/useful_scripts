#!/bin/bash
set -e
trap "echo 'sending fail backup status to vmagent...' && curl -k -d 'etcd_backup,hostname=ml-cbt-01 status=0.0' -X POST https://<vmagent-url>/write" ERR  # отсылаем алёрт в VictoriaMetrics, если одна из команд была неуспешной
cd /share/kubernetes/backups/etcd/  # переходим в папку с бэкапами
timestamp=$(date +"%Y-%m-%d-%H-%M-%S")
ETCDCTL_API=3 /usr/bin/etcdctl --cacert /etc/kubernetes/pki/etcd/ca.crt  --cert /etc/kubernetes/pki/etcd/server.crt --key /etc/kubernetes/pki/etcd/server.key --endpoints=https://127.0.0.1:2379 snapshot save $timestamp.db  # бэкапим etcd
ETCDCTL_API=3 etcdctl --write-out=table snapshot status $timestamp.db  # проверяем, что с бэкапом всё ок
rm `ls -t | awk 'NR>7'` # оставляем только 7 последних бэкапов, остальные удаляем
echo 'sending success backup status to vmagent...' && curl -k -d 'etcd_backup,hostname=ml-cbt-01 status=1' -X POST https://<vmagent-url>/write  # отправляем информацию об успешном бэкапе. В результате получится метрика etcd_backup_status со значением 1
