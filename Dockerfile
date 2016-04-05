FROM alpine:3.3

ENV LAST_RELEASE_URL http://dl.cnezsoft.com/zentao/8.1.3/ZenTaoPMS.8.1.3.zip
ENV LAST_RELEASE_FILENAME ZenTaoPMS.8.1.3
ENV APACHE_CONFIG /etc/apache2/httpd.conf
ENV PHP_CONFIG /etc/php/php.ini

# change timezone to Asia/Shanghai
RUN apk add --no-cache tzdata && \
    cp  /usr/share/zoneinfo/Asia/Shanghai  /etc/localtime && \
    echo "Asia/Shanghai" >  /etc/timezone && \
    apk del tzdata

# add bash
RUN apk add --no-cache bash && \
    sed -i -e "s/bin\/ash/bin\/bash/" /etc/passwd


# add rain user and group (addgroup -g 200 -S rain)
RUN sed -i -r 's/nofiles/rain/' /etc/group && \
    adduser -u 200 -D -S -G rain rain


# install apache2 and php
RUN apk add --no-cache apache2=2.4.17-r4 \
    apache2-utils=2.4.17-r4 \
    php=5.6.20-r0 \
    php-apache2 \
    php-bz2 \
    php-ctype \
    php-curl \
    php-curl \
    php-dom \
    php-iconv \
    php-json \
    php-mcrypt \
    php-mysql \
    php-mysqli \
    php-opcache \
    php-openssl \
    php-pdo \
    php-pdo_mysql \
    php-phar \
    php-posix \
    php-sockets \
    php-xml \
    php-xmlreader \
    php-zip \
    php-zlib 

# modify apache config
RUN sed -i -r 's/#(ServerName) .*/\1 localhost:80/' $APACHE_CONFIG && \
    sed -i -r 's/(User) apache/\1 rain/' $APACHE_CONFIG && \
    sed -i -r 's/(Group) apache/\1 rain/' $APACHE_CONFIG && \
    sed -i -r 's#(/var/www/localhost/htdocs)#\1/www#g' $APACHE_CONFIG && \
    sed -i -r 's#(Options) Indexes (FollowSymLinks)#\1 \2#' $APACHE_CONFIG && \ 
    sed -i -r 's#(AllowOverride) None#\1 All#g' $APACHE_CONFIG && \
    sed -i -r 's#(ErrorLog) logs/error.log#\1 /dev/stderr#' $APACHE_CONFIG && \
    sed -i -r 's#(CustomLog) logs/access.log (combined)#\1 /dev/stdout \2#' $APACHE_CONFIG && \
    sed -i -r 's/#(LoadModule rewrite_module .*)/\1/' $APACHE_CONFIG

# modify php config
RUN sed -i -r 's/(post_max_size) =.*/\1 = 50M/' $PHP_CONFIG && \
    sed -i -r 's/(upload_max_filesize) =.*/\1 = 50M/' $PHP_CONFIG && \
    sed -i -r 's/; (max_input_vars) =.*/\1 = 3000/' $PHP_CONFIG

# download tendaocms
RUN curl -fSL $LAST_RELEASE_URL -o /tmp/$LAST_FILENAME && \
    cd /tmp && unzip $LAST_RELEASE_FILENAME && \
    rm -rf /var/www/localhost/htdocs/* && \
    mv zendaopms/* /var/www/localhost/htdocs/ && \
    chown rain.rain /var/www/localhost/htdocs/ -R && \
    sed -i -r 's/(php_*)/#\1/g' /var/www/localhost/htdocs/www/.htaccess

WORKDIR /var/www/localhost/htdocs

VOLUME /data

COPY docker-entrypoint.sh /

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
