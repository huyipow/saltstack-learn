include:
  - init.install
  - pcre.install
nginx-source-install:
  file.managed:
    - name: /usr/local/src/nginx-1.10.0.tar.gz
    - source: salt://nginx/files/nginx-1.10.0.tar.gz
    - user: root
    - group: root
    - mode: 755
  cmd.run:
    - name: cd /usr/local/src && tar zxf nginx-1.10.0.tar.gz && cd nginx-1.10.0 && ./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-mail --with-mail_ssl_module --with-file-aio  --with-cc-opt='-O2 -g -pipe -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic' --with-pcre=/usr/local/src/pcre-8.37 && make && make install
    - unless: test -d /etc/nginx
    - require: 
      - file: nginx-source-install
      - pkg: pkg-nginx-init
      - cmd: pcre-source-install
nginx-init:
  file.managed:
    - name: /etc/init.d/nginx
    - source: salt://nginx/files/nginx
    - user: root
    - group: root
    - mode: 755
  cmd.run:
    - name: chkconfig --add nginx
    - unless: chkconfig --list | grep nginx
    - require:
      - file: nginx-init

/etc/nginx/nginx.conf:
  file.managed:
    - source: salt://nginx/files/nginx.conf
    - user: root
    - group: root
    - mode: 644
/etc/nginx/fastcgi_params:
  file.managed:
    - source: salt://nginx/files/fastcgi_params
    - user: root
    - group: root
    - mode: 644
nginx-user:
  user.present:
    - name: nginx
    - fullname: nginx
    - shell: /sbin/nologin
    - uid: 199
    - gid: 199
  group.present:
    - name: nginx
    - gid: 199
   
nginx-service:
  file.directory:
    - name: /etc/nginx/conf.d
    - require: 
      - cmd: nginx-source-install
  service.running:
    - name: nginx
    - enable: True
    - reload: True     
    - sig: 'nginx: master process'
    - watch:
      - file: /etc/nginx/nginx.conf 
