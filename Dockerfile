# https://hub.docker.com/r/phusion/baseimage/
FROM phusion/baseimage:0.9.19

MAINTAINER tuyenv <bitworkvn@gmail.com>

# Set correct environment variables
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

# ------------------------------------------------------------------------------
# Set locale (support UTF-8 in the container terminal)
# ------------------------------------------------------------------------------
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

CMD ["/sbin/my_init"]

# Install base packages
ENV DEBIAN_FRONTEND noninteractive

RUN add-apt-repository -y ppa:ondrej/php
RUN add-apt-repository -y ppa:nginx/stable

RUN apt-get update && \
    apt-get -yq install wget && \
    apt-get update && \
    apt-get -yq upgrade && \
    apt-get -yq install \
     	nano \
        aptitude \
        git \
        curl \
        vim \
        build-essential \
        python-software-properties \
        libcurl4-openssl-dev \
        pkg-config

# Nginx-PHP Installation
RUN apt-get install -y --force-yes php5.6-cli php5.6-fpm php5.6-mysql php5.6-pgsql php5.6-sqlite php5.6-curl\
       php5.6-gd php5.6-intl php5.6-imap php5.6-tidy php5.6-memcached\
       php5.6-mcrypt php-pear php5.6-dev

RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/5.6/cli/php.ini
RUN sed -ie 's/\;date\.timezone\ \=/date\.timezone\ \=\ Asia\/Ho_Chi_Minh/g' /etc/php/5.6/cli/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/5.6/fpm/php-fpm.conf
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/5.6/fpm/php.ini
RUN sed -i "s/;max_execution_time.*/max_execution_time=1600/" /etc/php/5.6/fpm/php.ini
RUN sed -i "s/;memory_limit.*/memory_limit=3024M/" /etc/php/5.6/fpm/php.ini

RUN apt-get install -y nginx gearman memcached
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# add ID for user www-data
RUN groupmod -g 1600 www-data
RUN usermod -u 1600 www-data

# Install composer globally. Life is too short for local per prj installer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

RUN mkdir -p        /var/www
ADD build/default   /etc/nginx/sites-available/default
RUN mkdir           /etc/service/nginx
ADD build/nginx.sh  /etc/service/nginx/run
RUN chmod +x        /etc/service/nginx/run

RUN mkdir           /etc/service/phpfpm
ADD build/phpfpm.sh /etc/service/phpfpm/run
RUN chmod +x        /etc/service/phpfpm/run

RUN mkdir /etc/service/memcached
ADD build/memcached.sh /etc/service/memcached/run
RUN chmod 0755 /etc/service/memcached/run
EXPOSE 80
# End Nginx-PHP

# Copy source directory to default nginx root directory
ADD www             /var/www

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
