FROM phusion/baseimage:jammy-1.0.1
#MAINTAINER nando
# Custom cache invalidation
ARG CACHEBUST=1

# Set correct environment variables
ENV DEBIAN_FRONTEND noninteractive
ENV HOME            /root
ENV LC_ALL          C.UTF-8
ENV LANG            en_US.UTF-8
ENV LANGUAGE        en_US.UTF-8
ENV TERM xterm


# Use baseimage-docker's init system
CMD ["/sbin/my_init"]


# Configure user nobody to match unRAID's settings
 RUN \
 usermod -u 99 nobody && \
 usermod -g 100 nobody && \
 usermod -d /home nobody && \
 chown -R nobody:users /home


RUN apt-get update 
RUN apt-get install -qy net-tools curl unzip
RUN apt-get install -qy mc git
RUN apt-get install -qy nano
RUN apt-get install -qy tmux
RUN apt-get install -qy php8.1-mysql
RUN apt-get install -qy php8.1-mysqlnd


# Install proxy Dependencies
RUN \
  apt-get update -q && \
  apt-get install -qy apache2 inotify-tools  libapache2-mod-php8.1 php8.1-amqp php8.1-ast php8.1-bcmath php8.1-bz2 php8.1-cgi php8.1-dba  php8.1-ds php8.1-enchant php8.1-gd php8.1-gearman php8.1-gmagick php8.1-gmp php8.1-gnupg php8.1-oauth php8.1-odbc php8.1-pcov php8.1-pgsql php8.1-phpdbg  php8.1-tidy php8.1-uuid  php8.1-xdebug  php-xmlrpc php8.1-pspell php8.1-curl php8.1-gd php8.1-sqlite  php8.1-tidy php8.1-cli  php8.1-http php8.1-igbinary  php8.1-imap php8.1-xsl php8.1-yac php8.1-yaml php8.1-interbase php8.1-intl php8.1-ldap  php8.1-mailparse   php8.1-sqlite3 php8.1-ssh2  php8.1-common  php8.1-redis php8.1-rrd php8.1-smbclient  php8.1-memcached php8.1-snmp php8.1-soap php8.1-solr composer   && \



  apt-get clean -y && \
  rm -rf /var/lib/apt/lists/*
 
RUN \
  service apache2 restart && \
  rm -R -f /var/www && \
  ln -s /web /var/www
  
# Update apache configuration with this one
RUN \
  mv /etc/apache2/sites-available/000-default.conf /etc/apache2/000-default.conf && \
  rm /etc/apache2/sites-available/* && \
  rm /etc/apache2/apache2.conf && \
  ln -s /config/proxy-config.conf /etc/apache2/sites-available/000-default.conf && \
  ln -s /var/log/apache2 /logs

ADD proxy-config.conf /etc/apache2/000-default.conf
ADD apache2.conf /etc/apache2/apache2.conf
ADD ports.conf /etc/apache2/ports.conf

# Manually set the apache environment variables in order to get apache to work immediately.
RUN \
echo www-data > /etc/container_environment/APACHE_RUN_USER && \
echo www-data > /etc/container_environment/APACHE_RUN_GROUP && \
echo /var/log/apache2 > /etc/container_environment/APACHE_LOG_DIR && \
echo /var/lock/apache2 > /etc/container_environment/APACHE_LOCK_DIR && \
echo /var/run/apache2.pid > /etc/container_environment/APACHE_PID_FILE && \
echo /var/run/apache2 > /etc/container_environment/APACHE_RUN_DIR

# Expose Ports
EXPOSE 80 443

# The www directory and proxy config location
VOLUME ["/config", "/web", "/logs"]

# Add our crontab file
ADD crons.conf /root/crons.conf

# Add firstrun.sh to execute during container startup
ADD firstrun.sh /etc/my_init.d/firstrun.sh
RUN chmod +x /etc/my_init.d/firstrun.sh

# Add inotify.sh to execute during container startup
RUN mkdir /etc/service/inotify
ADD inotify.sh /etc/service/inotify/run
RUN chmod +x /etc/service/inotify/run

# Add apache to runit
RUN mkdir /etc/service/apache
ADD apache-run.sh /etc/service/apache/run
RUN chmod +x /etc/service/apache/run
ADD apache-finish.sh /etc/service/apache/finish
RUN chmod +x /etc/service/apache/finish
