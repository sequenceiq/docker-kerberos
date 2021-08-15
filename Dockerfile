FROM centos:7
MAINTAINER SequenceIQ

# kerberos
RUN yum install -y krb5-server krb5-libs krb5-auth-dialog krb5-workstation 

EXPOSE 88 749

ADD ./config.sh /config.sh

ENTRYPOINT ["/config.sh"]
