FROM ubuntu:14.04 
MAINTAINER Jerry Wu  "wenzwu3931@gmail.com"

# Environment variable

ENV NAGIOS_HOME             /usr/local/nagios
ENV NAGIOS_USER             nagios
ENV NAGIOS_GROUP            nagios
ENV NAGIOS_CMDUSER          nagios
ENV NAGIOS_CMDGROUP         nagios
ENV NAGIOSADMIN_USER        nagiosadmin
ENV NAGIOSADMIN_PASS        nagios
ENV APACHE_RUN_USER         nagios
ENV APACHE_RUN_GROUP        nagios
ENV NAGIOS_TIMEZONE         UTC
ENV DEBIAN_FRONTEND         noninteractive
ENV NG_NAGIOS_CONFIG_FILE   ${NAGIOS_HOME}/etc/nagios.cfg
ENV NG_CGI_DIR              ${NAGIOS_HOME}/sbin
ENV NG_WWW_DIR              ${NAGIOS_HOME}/share/nagiosgraph
ENV NG_CGI_URL              /cgi-bin

# Install basic package

RUN apt-get update && apt-get install -y     \
        apache2                              \
        apache2-utils                        \
        autoconf                             \
        automake                             \
        bc                                   \
        bsd-mailx                            \
        build-essential                      \
        dc                                   \
        fping                                \
        gawk                                 \
        gcc                                  \
        gettext                              \
        git                                  \
        gperf                                \
        iputils-ping                         \
        libc6                                \
        libcache-memcached-perl              \
        libcgi-pm-perl                       \
        libdbd-mysql-perl                    \
        libdbi-perl                          \
        libfreeradius-client-dev             \
        libgd-gd2-perl                       \
        libgd2-xpm-dev                       \
        libgd2-xpm-dev                       \
        libjson-perl                         \
        libmcrypt-dev                        \
        libnagios-object-perl                \
        libnet-tftp-perl                     \
        libredis-perl                        \
        librrds-perl                         \
        libssl-dev                           \
        libswitch-perl                       \
        libwww-perl                          \
        m4                                   \
        make                                 \
        netcat                               \
        parallel                             \
        php5                                 \
        postfix                              \
        runit                                \
        supervisor                           \
        unzip                             && \
        apt-get clean

# Add nagios user, group

RUN ( egrep -i "^${NAGIOS_GROUP}"    /etc/group || groupadd $NAGIOS_GROUP    )              &&  \
    ( egrep -i "^${NAGIOS_CMDGROUP}" /etc/group || groupadd $NAGIOS_CMDGROUP )
RUN ( id -u $NAGIOS_USER    || useradd --system -d $NAGIOS_HOME -g $NAGIOS_GROUP    $NAGIOS_USER    )   &&  \
    ( id -u $NAGIOS_CMDUSER || useradd --system -d $NAGIOS_HOME -g $NAGIOS_CMDGROUP $NAGIOS_CMDUSER )

# Install nagios core

RUN cd /tmp                                                                             &&  \
    git clone https://github.com/NagiosEnterprises/nagioscore.git -b nagios-4.4.3       &&  \
    cd nagioscore                                                                       &&  \
    ./configure                                                                             \
        --prefix=${NAGIOS_HOME}                                                             \
        --exec-prefix=${NAGIOS_HOME}                                                        \
        --enable-event-broker                                                               \
        --with-httpd-conf=/etc/apache2/conf-available                                       \
        --with-command-user=${NAGIOS_CMDUSER}                                               \
        --with-command-group=${NAGIOS_CMDGROUP}                                             \
        --with-nagios-user=${NAGIOS_USER}                                                   \
        --with-nagios-group=${NAGIOS_GROUP}                                             &&  \
    make all                                                                            &&  \
    make install                                                                        &&  \
    make install-init                                                                   &&  \
    make install-config                                                                 &&  \
    make install-commandmode                                                            &&  \
    make install-webconf                                                                &&  \
    make clean

RUN a2enconf nagios && \
    a2enmod cgi rewrite ssl

# Install nagios plugins

RUN cd /tmp                                                                             &&  \
    git clone https://github.com/nagios-plugins/nagios-plugins.git -b release-2.2.1     &&  \
    cd nagios-plugins                                                                   &&  \
    ./tools/setup                                                                       &&  \
    ./configure                                                                             \
        --prefix=${NAGIOS_HOME}                                                         &&  \
    make                                                                                &&  \
    make install                                                                        &&  \
    make clean                                                                          &&  \
    mkdir -p /usr/lib/nagios/plugins                                                    &&  \
    ln -sf /opt/nagios/libexec/utils.pm /usr/lib/nagios/plugins

# Install nrpe server

RUN cd /tmp                                                                             &&  \
    git clone https://github.com/NagiosEnterprises/nrpe.git -b nrpe-3.2.1               &&  \
    cd nrpe                                                                             &&  \
    ./configure                                                                             \
        --with-ssl=/usr/bin/openssl                                                         \
        --with-ssl-lib=/usr/lib/x86_64-linux-gnu                                        &&  \
    make check_nrpe                                                                     &&  \
    cp src/check_nrpe ${NAGIOS_HOME}/libexec/                                           &&  \
    make clean

ADD conf/supervisord.conf /etc/supervisor/conf.d/
ADD run.sh /usr/local/nagios

EXPOSE 80 443 5666

CMD ["/usr/local/nagios/run.sh"]
