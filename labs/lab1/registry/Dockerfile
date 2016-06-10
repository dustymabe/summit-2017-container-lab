FROM registry.access.redhat.com/rhel:7.2
MAINTAINER Student <student@foo.io>

ADD ./custom.repo /etc/yum.repos.d/custom.repo
ADD ./run-registry.sh /opt/registry/run-registry.sh

RUN yum -y install docker-registry --enablerepo=rhel-7-server-extras-rpms && yum clean all
RUN chmod -v 755 /opt/registry/run-registry.sh

EXPOSE 5000

CMD ["/opt/registry/run-registry.sh"]
