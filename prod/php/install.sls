php-source-install:
  file.managed:
    - name: /usr/local/src/php-5.6.21.tar.gz
    - source: salt://php/files/php-5.6.21.tar.gz
    - user: root
    - group: root
    - mode: 644
  cmd.run:
    - name: cd /usr/local/src && tar zxf php-5.6.21.tar.gz && cd php-5.6.21 && ./configure --prefix=/usr/local/php-fastcgi --with-pdo-mysql=mysqlnd --with-mysqli=mysqlnd --with-mysql=mysqlnd --with-jpeg-dir --with-png-dir --with-zlib --enable-xml --with-libxml-dir --with-curl --enable-bcmath --enable-shmop  --enable-sysvsem --enable-inline-optimization --enable-mbregex   --with-openssl --enable-mbstring --with-gd --enable-gd-native-ttf --with-freetype-dir=/usr/lib64 --with-gettext=/usr/lib64  --enable-sockets --with-xmlrpc --enable-zip --enable-soap   --disable-debug --enable-opcache --enable-zip   --with-config-file-path=/usr/local/php-fastcgi/etc  --enable-fpm   --with-fpm-user=nginx --with-fpm-group=nginx && make && make install
    - require:
      - file: php-source-install
    - unless: test -d /usr/local/php-fastcgi
pdo-plugin:
  cmd.run:
    - name: cd /usr/local/src/php-5.6.21/ext/pdo_mysql/ && /usr/local/php-fastcgi/bin/phpize &&./configure --with-php-config=/usr/local/php-fastcgi/bin/php-config &&make &&make install
    - unless: test -f /usr/local/php-fastcgi/lib/php/extensions/*/pdo_mysql.so
    - require:
      - cmd: php-source-install

php-ini:
  file.managed:
    - name: /usr/local/php-fastcgi/etc/php.ini
    - source: salt://php/files/php.ini-production
    - user: root
    - group: root
    - mode: 644 

php-fpm:
  file.managed:
   - name: /usr/local/php-fastcgi/etc/php-fpm.conf
   - source: salt://php/files/php-fpm.conf.default
   - user: root
   - group: root
   - mode: 644 
php-fastcgi-service:
  file.managed:
    - name: /etc/init.d/php-fpm
    - source: salt://php/files/init.d.php-fpm
    - user: root
    - group: root
    - mode:  755
  cmd.run:
    - name: chkconfig --add php-fpm
    - unless: chkonfig --list | grep php-fpm
    - require:
      - file: php-fastcgi-service
  service.running:
    - name: php-fpm
    - enable: True
    - reload: True
    - sig: php-fpm
    - require: 
      - cmd: php-fastcgi-service
    - watch:
      - file: php-ini
      - file: php-fpm

