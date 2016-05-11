include:
  - nginx.install
  - php.install

bbs-conf:
  file.managed:
    - name: /etc/nginx/conf.d/bbs.conf
    - source: salt://bbs/files/olamp.conf
    - user: root
    - group: root
    - mode: 644 
    - require: 
      - service: php-fastcgi-service
    - watch_in:
      - service: nginx-service
