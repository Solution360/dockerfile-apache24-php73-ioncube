FROM debian:9

RUN apt-get clean

RUN apt-get update
RUN apt-get -y install wget curl apt-transport-https apache2 unzip redis-server

RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN echo "deb https://packages.sury.org/php/ stretch main" > /etc/apt/sources.list.d/php.list

RUN apt-get update

RUN apt-get -y install  php7.3 php7.3-redis php7.3-curl php7.3-gd php7.3-mbstring php7.3-imagick php7.3-mysql php7.3-xdebug php7.3-simplexml php7.3-zip php7.3-soap php7.3-apcu php-apcu-bc php7.3-sqlite3 php7.3-intl php7.3-bcmath

#configure apache
RUN ["bin/bash", "-c", "sed -i 's/AllowOverride None/AllowOverride All\\nSetEnvIf X-Forwarded-Proto https HTTPS=on/g' /etc/apache2/apache2.conf"]

RUN service apache2 stop

#set timezone
RUN apt-get -y install tzdata && ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

#configure php
RUN ["bin/bash", "-c", "sed -i 's/max_execution_time\\s*=.*/max_execution_time=180/g' /etc/php/7*/apache2/php.ini"]
RUN ["bin/bash", "-c", "sed -i 's/upload_max_filesize\\s*=.*/upload_max_filesize=16M/g' /etc/php/7*/apache2/php.ini"]
RUN ["bin/bash", "-c", "sed -i 's/memory_limit\\s*=.*/memory_limit=256M/g' /etc/php/7*/apache2/php.ini"]
RUN ["bin/bash", "-c", "sed -i 's/post_max_size\\s*=.*/post_max_size=20M/g' /etc/php/7*/apache2/php.ini"]
RUN phpenmod redis

#configure XDebug
RUN ["bin/bash", "-c", "echo [XDebug] >> /etc/php/7*/apache2/php.ini"]
RUN ["bin/bash", "-c", "echo xdebug.remote_enable=1 >> /etc/php/7*/apache2/php.ini"]
RUN ["bin/bash", "-c", "echo xdebug.remote_connect_back=1 >> /etc/php/7*/apache2/php.ini"]
RUN ["bin/bash", "-c", "echo xdebug.idekey=netbeans-xdebug >> /etc/php/7*/apache2/php.ini"]

#install ioncube
RUN wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
RUN tar xvfz ioncube_loaders_lin_x86-64.tar.gz
RUN ["bin/bash", "-c", "cp -r ioncube/*.so /usr/lib/php/2*/"]
RUN ["bin/bash", "-c", "cd /etc/php/7*/apache2/conf.d && echo zend_extension = /usr/lib/php/2*/ioncube_loader_lin_7.3.so > 00-ioncube.ini"]
#RUN service apache2 restart

# Configure apache
RUN a2enmod rewrite
RUN a2enmod ssl
RUN a2enmod proxy
RUN a2enmod headers
# enable ssl on apache
RUN a2ensite default-ssl
RUN chown -R www-data:www-data /var/www
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
#RUN service apache2 restart

EXPOSE 80
EXPOSE 443

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
