#!/bin/bash

[[ "TRACE" ]] && set -x

: ${REALM:=NODE.CONSUL}
: ${DOMAIN_REALM:=node.consul}
: ${KERB_MASTER_KEY:=masterkey}
: ${KERB_ADMIN_USER:=admin}
: ${KERB_ADMIN_PASS:=admin}

fix_nameserver() {
  cat>/etc/resolv.conf<<EOF
nameserver $NAMESERVER_IP
search service.consul node.consul
EOF
}

fix_hostname() {
  sed -i "/^hosts:/ s/ *files dns/ dns files/" /etc/nsswitch.conf
}

create_config() {
  : ${KDC_ADDRESS:=$(hostname -f)}

  cat>/etc/krb5.conf<<EOF
[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 default_realm = $REALM
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true

[realms]
 $REALM = {
  kdc = $KDC_ADDRESS
  admin_server = $KDC_ADDRESS
 }

[domain_realm]
 .$DOMAIN_REALM = $REALM
 $DOMAIN_REALM = $REALM
EOF
}

create_db() {
  /usr/sbin/kdb5_util -P $KERB_MASTER_KEY -r $REALM create -s
}

start_kdc() {
  /etc/rc.d/init.d/krb5kdc start
  /etc/rc.d/init.d/kadmin start

  chkconfig krb5kdc on
  chkconfig kadmin on
}

restart_kdc() {
  /etc/rc.d/init.d/krb5kdc restart
  /etc/rc.d/init.d/kadmin restart
}

create_admin_user() {
  kadmin.local -q "addprinc -pw $KERB_ADMIN_PASS $KERB_ADMIN_USER/admin"
  echo "*/admin@$REALM *" > /var/kerberos/krb5kdc/kadm5.acl
}

main() {
  fix_nameserver
  fix_hostname
  create_config
  create_db
  start_kdc
  create_admin_user
  restart_kdc
  tail -f /var/log/krb5kdc.log
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"