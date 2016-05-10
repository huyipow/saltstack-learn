/etc/sysconfig/selinux:
  file.managed:
    - source: salt://init/files/selinux
    - user: root
    - group: root
    - mode: 644
