#!/bin/bash -lex

ETCDCTL="etcdctl --peers $ETCD_URL"

#Syslog ETCD Entries
$ETCDCTL get $ETCD_PROXY_BASE/syslog/host || $ETCDCTL set $ETCD_PROXY_BASE/syslog/host ""


sed -i -e "s/127.0.0.1[:]4001/$ETCD_URL/g" -e "s|/totem|$ETCD_PROXY_BASE|g" /etc/confd/confd.toml
confd