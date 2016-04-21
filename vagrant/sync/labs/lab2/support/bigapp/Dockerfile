FROM registry.access.redhat.com/rhel
MAINTAINER Student <student@foo.io>

# ADD set up scripts
ADD  scripts /scripts
RUN chmod 755 /scripts/*

# Add in custom yum repository and update
ADD ./local.repo /etc/yum.repos.d/local.repo
ADD ./hosts /new-hosts
RUN cat /new-hosts >> /etc/hosts && yum -y update

# Common Deps
RUN cat /new-hosts >> /etc/hosts && yum -y install openssl procps-ng
RUN cat /new-hosts >> /etc/hosts && yum -y install psmisc 

# Deps for wordpress
RUN cat /new-hosts >> /etc/hosts && yum -y install httpd 
RUN cat /new-hosts >> /etc/hosts && yum -y install php 
RUN cat /new-hosts >> /etc/hosts && yum -y install php-mysql 
RUN cat /new-hosts >> /etc/hosts && yum -y install php-gd
RUN cat /new-hosts >> /etc/hosts && yum -y install tar

# Deps for mariadb
RUN cat /new-hosts >> /etc/hosts && yum -y install mariadb-server 
RUN cat /new-hosts >> /etc/hosts && yum -y install net-tools
RUN cat /new-hosts >> /etc/hosts && yum -y install hostname

# Add in wordpress sources 
COPY latest.tar.gz /latest.tar.gz
RUN tar xvzf /latest.tar.gz -C /var/www/html --strip-components=1 
RUN rm /latest.tar.gz
RUN chown -R apache:apache /var/www/

EXPOSE 80
CMD ["/bin/bash", "/scripts/start.sh"]
