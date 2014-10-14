# rabbitmq-cluster

Rabbitmq Cluster using Docker.

## Status
In Testing

## Requirements
- Docker 1.2 +
- Etcd 0.4.6 +

## Features
- Automatic seed node detection using etcd (Seed node will initialize the settings for cluster).
- rabbitmq.conf file for automatic cluster initialization using etcd discovery.
- hosts file initialization using etcd discovery.
- Centralized logging using syslog.
- Random Erlang Cookie for the cluster.

## Creating cluster (different machines)
Assuming that there are 2 machines (machine-1, machine-2), with data directory
at /data (you may choose different path). You may deploy all nodes at once using command:

```
RABBITMQ_USER=<rabbitmq_user>
RABBITMQ_PASSWORD=<rabbitmq_password>
sudo docker run --rm -P -p 5672:5672 -p 25672:25672 -p 4369:4369 -p 44001:44001 --name node1 -e HOST_IP=$COREOS_PRIVATE_IPV4 -e RABBITMQ_USER=$RABBITMQ_USER -e RABBITMQ_PASSWORD=$RABBITMQ_PASSWORD -v /data:/var/lib/rabbitmq  totem/rabbitmq-cluster
```  

where $COREOS_PRIVATE_IPV4 is the private IP address for the host. 
(If using ec2, ensure that machines can talk to each other on ports: 4369, 5672, 35197)
35197)

## Proxying Cluster using Yoda
If you are using dynamic proxy like yoda (that supports tcp) for port 5672, you may 
need to add additional port binding in Yoda proxy. 
e.g.: -p 5673:5672

To configure yoda with tcp listeners and sidekick discovery, see [Yoda Proxy](https://github.com/totem/yoda-proxy) 
and [Yoda Discover](https://github.com/totem/yoda-discover)


## Note for SSH
It has SSH enabled with keys obtained from repository. Ideally, we should not 
require ssh access for docker containers. However, it helps to troubleshoot the
problem on the server. Once the status moves out of development, the ssh access
will be removed.
