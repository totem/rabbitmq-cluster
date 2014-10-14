#!/bin/bash -le

echo "Starting discover for rabbitmq nodes"

ETCDCTL="etcdctl --peers $ETCD_URL"
PUBLISH_NODE_TTL=${PUBLISH_NODE_TTL:-120}
PUBLISH_NODE_POLL=${PUBLISH_NODE_POLL:-60s}

NODE=$(cat /var/lib/rabbitmq/nodename)
NODE_IP=${NODE_IP:-$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')}

while supervisorctl status rabbitmq-server | grep 'RUNNING'
do
    echo "Publishing $ETCD_RABBITMQ_BASE/rabbitmq/nodes/${NODE} ${NODE_IP} with ttl ${PUBLISH_NODE_TTL}"
	${ETCDCTL} set --ttl ${PUBLISH_NODE_TTL} $ETCD_RABBITMQ_BASE/rabbitmq/nodes/${NODE} ${NODE_IP}
	sleep ${PUBLISH_NODE_POLL}
done
