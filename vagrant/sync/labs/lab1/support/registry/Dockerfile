FROM registry.access.redhat.com/rhel:7.1-6
MAINTAINER Student <student@foo.io>

ADD ./local.repo /etc/yum.repos.d/local.repo
ADD ./hosts /new-hosts
ADD ./run-registry.sh /opt/registry/run-registry.sh

RUN cat /new-hosts >> /etc/hosts && yum -y install docker-registry && yum clean all
RUN chmod -v 755 /opt/registry/run-registry.sh

EXPOSE 5000

# CMD ["/usr/bin/gunicorn", "--access-logfile", "-", "--debug", "--max-requests", "100", "--graceful-timeout", "3600", "-t", "3600", "-k", "gevent", "-b", "${REGISTRY_ADDRESS}:${REGISTRY_PORT}", "-w", "$GUNICORN_WORKERS", "docker_registry.wsgi:application"]

CMD ["/opt/registry/run-registry.sh"]

