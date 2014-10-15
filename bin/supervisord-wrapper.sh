#!/bin/sh -le

ETCDCTL="etcdctl --peers $ETCD_URL"

# Check if nodename exists. If not create a new node
if [ ! -f /var/lib/rabbitmq/nodename ]; then
    # Generate Persistent host file
    NODE=${NODE:-${NODE_PREFIX}-$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c${1:-10};echo;)}
    echo $NODE > /var/lib/rabbitmq/nodename
fi
NODE=$(cat /var/lib/rabbitmq/nodename)

echo "Modifying Host entries..."
echo 127.0.0.1 $NODE  >> /etc/hosts
cat /etc/hosts /etc/confd/templates/hosts.dynamic.tmpl > /etc/confd/templates/hosts.tmpl


echo "Modifying Syslog entries..."
$ETCDCTL get $ETCD_RABBITMQ_BASE/syslog/host || $ETCDCTL set $ETCD_RABBITMQ_BASE/syslog/host ""
sed -i -e "s/{NODE}/${NODE}/g" -e "s/{RABBITMQ_CLUSTER_NAME}/${RABBITMQ_CLUSTER_NAME}/g" /etc/rsyslog.d/20-rabbitmq.conf

echo "Modify confd settings (ETCD_URL, ETCD_RABBITMQ_BASE)"
sed -i -e "s/127.0.0.1[:]4001/$ETCD_URL/g" -e "s|/totem|$ETCD_RABBITMQ_BASE|g" /etc/confd/confd.toml

echo "Check/Create Erlang Cookie (For RabbitMq cluster)"

$ETCDCTL mk $ETCD_RABBITMQ_BASE/rabbitmq/cookie $(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c${1:-32};echo;) || echo "Utilizing existing cookie..."
ERLANG_COOKIE=$($ETCDCTL get $ETCD_RABBITMQ_BASE/rabbitmq/cookie)
if [ -z $ERLANG_COOKIE ]; then
    echo "ERROR: Erlang cookie was found empty. Can not continue...."
    exit 10
fi
echo "$ERLANG_COOKIE" > /var/lib/rabbitmq/.erlang.cookie
chmod 600 /var/lib/rabbitmq/.erlang.cookie


echo "Changing owner for attached volume to rabbitmq"
chown -R rabbitmq:rabbitmq /var/lib/rabbitmq

echo "Updating environment file"
cat <<END>> /etc/environment
ETCDCTL=$ETCDCTL
ETCD_RABBITMQ_BASE=$ETCD_RABBITMQ_BASE
NODE=$NODE
RABBITMQ_NODENAME=rabbit@$NODE
RABBITMQ_CLUSTER_NAME=${RABBITMQ_CLUSTER_NAME}
END

echo "Starting supervisord"
supervisord -n
