#!/bin/bash

if [ ! -f ${NAGIOS_HOME}/etc/htpasswd.users ] ; then
  htpasswd -c -b -s ${NAGIOS_HOME}/etc/htpasswd.users ${NAGIOSADMIN_USER} ${NAGIOSADMIN_PASS}
  chown -R nagios.nagios ${NAGIOS_HOME}/etc/htpasswd.users
fi

/etc/init.d/nagios start
/usr/local/nagios/bin/nrpe -c /tmp/nrpe/sample-config/nrpe.cfg -d

/usr/bin/supervisord -n
