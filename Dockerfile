FROM totem/python-base:3.4-trusty

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y openssh-server openssh-client nano

#Install Supervisor
RUN pip install supervisor==3.1.2

##SSH Server (To troubleshoot issues with discover)
RUN mkdir /var/run/sshd
ADD .root/.ssh /root/.ssh
RUN chmod -R 400 /root/.ssh/* && chmod  500 /root/.ssh & chown -R root:root /root/.ssh

# Install RabbitMQ.
RUN \
  wget -qO - http://www.rabbitmq.com/rabbitmq-signing-key-public.asc | apt-key add - && \
  echo "deb http://www.rabbitmq.com/debian/ testing main" > /etc/apt/sources.list.d/rabbitmq.list && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y rabbitmq-server && \
  rm -rf /var/lib/apt/lists/* && \
  rabbitmq-plugins enable rabbitmq_management && \
  echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config

#Syslog
RUN echo '$PreserveFQDN on' | cat - /etc/rsyslog.conf > /tmp/rsyslog.conf && sudo mv /tmp/rsyslog.conf /etc/rsyslog.conf
RUN sed -i 's~^#\$ModLoad immark\(.*\)$~$ModLoad immark \1~' /etc/rsyslog.conf

#Confd
ENV CONFD_VERSION 0.6.2
RUN curl -L https://github.com/kelseyhightower/confd/releases/download/v$CONFD_VERSION/confd-${CONFD_VERSION}-linux-amd64 -o /usr/local/bin/confd
RUN chmod 555 /usr/local/bin/confd

#Etcdctl
RUN echo "Etcd force...."
ENV ETCDCTL_VERSION v0.4.6
RUN curl -L https://github.com/coreos/etcd/releases/download/$ETCDCTL_VERSION/etcd-$ETCDCTL_VERSION-linux-amd64.tar.gz -o /tmp/etcd-$ETCDCTL_VERSION-linux-amd64.tar.gz
RUN cd /tmp && gzip -dc etcd-$ETCDCTL_VERSION-linux-amd64.tar.gz | tar -xof -
RUN cp -f /tmp/etcd-$ETCDCTL_VERSION-linux-amd64/etcdctl /usr/local/bin
RUN rm -rf /tmp/etcd-$ETCDCTL_VERSION-linux-amd64.tar.gz

#Configure Rabbitmq
ADD bin/rabbitmq-start /usr/local/bin/
RUN chmod +x /usr/local/bin/rabbitmq-start

#Supervisor Config
RUN mkdir -p /var/log/supervisor
ADD etc/supervisor /etc/supervisor
RUN ln -sf /etc/supervisor/supervisord.conf /etc/supervisord.conf

#Confd Defaults
ADD ./bin/confd-wrapper.sh /usr/sbin/confd-wrapper.sh
RUN chmod 550 /usr/sbin/confd-wrapper.sh
ADD etc/confd /etc/confd

ENV ETCD_URL 172.17.42.1:4001
ENV ETCD_RABBITMQ_BASE /totem
ENV ETCD_YODA_BASE /yoda
ENV NODE_PREFIX totem-rabbitmq

# Define mount points.
VOLUME ["/var/lib/rabbitmq"]

EXPOSE 5672 15672 25672 22

ENTRYPOINT ["/usr/local/bin/supervisord"]
CMD ["-n"]