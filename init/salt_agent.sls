salt_agent:
  pkg.installed:
    - name: salt-minion.noarch
  file.managed: 
    - name: /etc/salt/minion
    - source: salt://init/files/minion
    - template: jinja
    - defaults:
    - MASTER: 192.168.10.251
    - require: 
      - pkg: salt_agent
  service.running:
    - name: salt-minion
    - enable: True
    - watch:
      - pkg: salt_agent
      - file: salt_agent
