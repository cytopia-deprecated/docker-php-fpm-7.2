###
### PHP-FPM 7.2
###
FROM centos:7
MAINTAINER "cytopia" <cytopia@everythingcli.org>


##
## Labels
##
LABEL \
	name="cytopia's PHP-FPM 7.2 Image" \
	image="php-fpm-7.2" \
	vendor="cytopia" \
	license="MIT" \
	build-date="2017-06-27"


###
### Envs
###

# User/Group
ENV MY_USER="devilbox" \
	MY_GROUP="devilbox" \
	MY_UID="1000" \
	MY_GID="1000"

# User PHP config directories
ENV MY_CFG_DIR_PHP_CUSTOM="/etc/php-custom.d"

# Log Files
ENV MY_LOG_DIR="/var/log/php" \
	MY_LOG_FILE_XDEBUG="/var/log/php/xdebug.log" \
	MY_LOG_FILE_ACC="/var/log/php/www-access.log" \
	MY_LOG_FILE_ERR="/var/log/php/www-error.log" \
	MY_LOG_FILE_SLOW="/var/log/php/www-slow.log" \
	MY_LOG_FILE_FPM_ERR="/var/log/php/php-fpm.err"


###
### Install
###
RUN \
	groupadd -g ${MY_GID} -r ${MY_GROUP} && \
	adduser -u ${MY_UID} -m -s /bin/bash -g ${MY_GROUP} ${MY_USER}

RUN \
	yum -y install epel-release && \
	rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm && \
	yum-config-manager --enable remi && \
	yum-config-manager --disable remi-php55 && \
	yum-config-manager --disable remi-php56 && \
	yum-config-manager --disable remi-php70 && \
	yum-config-manager --disable remi-php71 && \
	yum-config-manager --enable remi-test && \
	rpm -ivh https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm && \
	yum-config-manager --enable pgdg96 && \
	( \
		echo "[mongodb-org-3.4]"; \
		echo "name=MongoDB Repository"; \
		echo "baseurl=https://repo.mongodb.org/yum/redhat/7Server/mongodb-org/3.4/x86_64/"; \
		echo "gpgcheck=1"; \
		echo "enabled=1"; \
		echo "gpgkey=https://www.mongodb.org/static/pgp/server-3.4.asc"; \
	) > /etc/yum.repos.d/mongodb.repo && \
	yum clean all

RUN yum -y update && yum -y install \
	php72-php \
	php72-php-cli \
	php72-php-fpm \
	\
	php72-php-bcmath \
	php72-php-common \
	php72-php-gd \
	php72-php-gmp \
	php72-php-imap \
	php72-php-intl \
	php72-php-ldap \
	php72-php-mbstring \
	php72-php-mcrypt \
	php72-php-mysqli \
	php72-php-mysqlnd \
	php72-php-opcache \
	php72-php-pdo \
	php72-php-pear \
	php72-php-pgsql \
	php72-php-phalcon3 \
	php72-php-pspell \
	php72-php-recode \
	php72-php-redis \
	php72-php-soap \
	php72-php-tidy \
	php72-php-xml \
	php72-php-xmlrpc \
	\
	php72-php-pecl-apcu \
	php72-php-pecl-imagick \
	php72-php-pecl-memcache \
	php72-php-pecl-memcached \
	php72-php-pecl-mongodb \
	php72-php-pecl-uploadprogress \
	php72-php-pecl-xdebug \
	php72-php-pecl-zip \
	\
	postfix \
	\
	socat \
	\
	nc \
	\
	&& \
	\
	\
	ln -s /opt/remi/php72/root/bin/php /usr/bin/php && \
	ln -s /opt/remi/php72/root/sbin/php-fpm /usr/sbin/php-fpm && \
	\
	yum -y autoremove && \
	yum clean metadata && \
	yum clean all

###
### Install Tools
###
RUN yum -y update && yum -y install \
	mysql \
	postgresql96 \
	mongodb-org-tools \
	bind-utils \
	which \
	git \
	nodejs \
	npm \
	\
	&& \
	\
	yum -y autoremove && \
	yum clean metadata && \
	yum clean all

RUN \
	curl -sS https://getcomposer.org/installer | php && \
	mv composer.phar /usr/local/bin/composer && \
	composer self-update

RUN \
	DRUSH_VERSION="$( curl -q https://api.github.com/repos/drush-ops/drush/releases 2>/dev/null | grep tag_name | grep -Eo '\"[0-9.]+\"' | head -1 | sed 's/\"//g' )" && \
	mkdir -p /usr/local/src && \
	chown ${MY_USER}:${MY_GROUP} /usr/local/src && \
	su - ${MY_USER} -c 'git clone https://github.com/drush-ops/drush.git /usr/local/src/drush' && \
	v="${DRUSH_VERSION}" su ${MY_USER} -p -c 'cd /usr/local/src/drush && git checkout ${v}' && \
	su - ${MY_USER} -c 'cd /usr/local/src/drush && composer install --no-interaction --no-progress' && \
	ln -s /usr/local/src/drush/drush /usr/local/bin/drush

RUN \
	curl https://drupalconsole.com/installer -L -o drupal.phar && \
	mv drupal.phar /usr/local/bin/drupal && \
	chmod +x /usr/local/bin/drupal

RUN \
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
	mv wp-cli.phar /usr/local/bin/wp && \
	chmod +x /usr/local/bin/wp && \
	wp cli update

RUN \
	mkdir -p /usr/local/src && \
	chown ${MY_USER}:${MY_GROUP} /usr/local/src && \
	su - ${MY_USER} -c 'git clone https://github.com/cytopia/mysqldump-secure.git /usr/local/src/mysqldump-secure' && \
	su - ${MY_USER} -c 'cd /usr/local/src/mysqldump-secure && git checkout $(git describe --abbrev=0 --tags)' && \
	ln -s /usr/local/src/mysqldump-secure/bin/mysqldump-secure /usr/local/bin && \
	cp /usr/local/src/mysqldump-secure/etc/mysqldump-secure.conf /etc && \
	cp /usr/local/src/mysqldump-secure/etc/mysqldump-secure.cnf /etc && \
	touch /var/log/mysqldump-secure.log && \
	chown ${MY_USER}:${MY_GROUP} /etc/mysqldump-secure.* && \
	chown ${MY_USER}:${MY_GROUP} /var/log/mysqldump-secure.log && \
	chmod 0400 /etc/mysqldump-secure.conf && \
	chmod 0400 /etc/mysqldump-secure.cnf && \
	chmod 0644 /var/log/mysqldump-secure.log && \
	sed -i'' 's/^DUMP_DIR=.*/DUMP_DIR="\/shared\/backups\/mysql"/g' /etc/mysqldump-secure.conf && \
	sed -i'' 's/^DUMP_DIR_CHMOD=.*/DUMP_DIR_CHMOD="0755"/g' /etc/mysqldump-secure.conf && \
	sed -i'' 's/^DUMP_FILE_CHMOD=.*/DUMP_FILE_CHMOD="0644"/g' /etc/mysqldump-secure.conf && \
	sed -i'' 's/^LOG_CHMOD=.*/LOG_CHMOD="0644"/g' /etc/mysqldump-secure.conf && \
	sed -i'' 's/^NAGIOS_LOG=.*/NAGIOS_LOG=0/g' /etc/mysqldump-secure.conf

RUN \
	curl -LsS https://symfony.com/installer -o /usr/local/bin/symfony && \
	chmod a+x /usr/local/bin/symfony

RUN \
	mkdir -p /usr/local/src && \
	chown ${MY_USER}:${MY_GROUP} /usr/local/src && \
	su - ${MY_USER} -c 'git clone https://github.com/laravel/installer /usr/local/src/laravel-installer' && \
	su - ${MY_USER} -c 'cd /usr/local/src/laravel-installer && git checkout $(git tag | sort -V | tail -1)' && \
	su - ${MY_USER} -c 'cd /usr/local/src/laravel-installer && composer install' && \
	ln -s /usr/local/src/laravel-installer/laravel /usr/local/bin/laravel && \
	chmod +x /usr/local/bin/laravel


###
### Configure PS1
###
RUN \
	( \
		echo "if [ -f /etc/bashrc ]; then"; \
		echo "    . /etc/bashrc"; \
		echo "fi"; \
	) | tee /home/${MY_USER}/.bashrc /root/.bashrc && \
	( \
		echo "if [ -f ~/.bashrc ]; then"; \
		echo "    . ~/.bashrc"; \
		echo "fi"; \
	) | tee /home/${MY_USER}/.bash_profile /root/.bash_profile && \
	echo ". /etc/bash_profile" | tee -a /etc/bashrc


###
### Bootstrap Scipts
###
COPY ./scripts/docker-install.sh /
COPY ./scripts/docker-entrypoint.sh /
COPY ./scripts/bash-profile /etc/bash_profile


###
### Install
###
RUN /docker-install.sh


###
### Ports
###
EXPOSE 9000


###
### Volumes
###
VOLUME /var/log/php
VOLUME /etc/php-custom.d
VOLUME /var/mail


###
### Entrypoint
###
ENTRYPOINT ["/docker-entrypoint.sh"]
