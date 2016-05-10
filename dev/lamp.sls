lamp-pkg-install:
  pkg.installed: 
    - names:
      - php
      - php-cli
      - php-common
      - mysql
      - php-mysql
      - php-pdo

apache-server:
  pkg.installed:
    - name: httpd
  file.managed:
    - name: /etc/httpd/conf/httpd.conf
    - source: salt://files/httpd.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults: 
      HOST: {{ pillar['apache']['HOST'] }}
      PORT: {{ pillar['apache']['PORT'] }}
      MAC: {{ pillar['apache']['MAC'] }}
    - require:
      - pkg: apache-server
  service.running:
    - name: httpd
    - enable: True
    - reload: True
    - watch: 
      - file: apache-server

mysql-service:
  pkg.installed:
    - name: mysql-server
    - require_in:
      - file: mysql-service
  file.managed:
    - name: /etc/my.cnf
    - source: salt://files/my.cnf
    - user: root
    - group: root
    - mode: 644
    - watch_in:
      - service: mysql-service
  service.running:
    - name: mysqld
    - enable: True
