#!/bin/sh -le

ETCDCTL="etcdctl --peers $ETCD_URL"

# Check if nodename exists. If not create a new node
if [ ! -f /var/lib/rabbitmq/nodename ]; then
    # Generate Persistent host file
    NODE=${NODE_PREFIX}-$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c${1:-10};echo;)
    echo $NODE > /var/lib/rabbitmq/nodename
fi
NODE=$(cat /var/lib/rabbitmq/nodename)

echo "Modifying Host entries..."
echo 127.0.0.1 $NODE  >> /etc/hosts
cat /etc/hosts /etc/confd/templates/hosts.dynamic.tmpl > /etc/confd/templates/hosts.tmpl


echo "Modifying Syslog entries..."
$ETCDCTL get $ETCD_RABBITMQ_BASE/syslog/host || $ETCDCTL set $ETCD_RABBITMQ_BASE/syslog/host ""

echo "Modify confd settings (ETCD_URL, ETCD_RABBITMQ_BASE)"
sed -i -e "s/127.0.0.1[:]4001/$ETCD_URL/g" -e "s|/totem|$ETCD_RABBITMQ_BASE|g" /etc/confd/confd.toml

echo "Check/Create Erlang Cookie (For RabbitMq cluster)"
$ETCDCTL mk $ETCD_RABBITMQ_BASE/rabbitmq/cookie $(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c${1:-32};echo;) || echo "Utilizing existing cookie..."
echo $($ETCDCTL get $ETCD_RABBITMQ_BASE/rabbitmq/cookie) > /var/lib/rabbitmq/.erlang.cookie
chmod 600 /var/lib/rabbitmq/.erlang.cookie


echo "Ensure that attached volume is owned by rabbitmq"
chown -R rabbitmq:rabbitmq /var/lib/rabbitmq

echo "Starting supervisord"
supervisord -n
