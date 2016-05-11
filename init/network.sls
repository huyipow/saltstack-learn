/etc/sysconfig/network-scripts/ifcfg-eth0:
  file.append:
    - text:  
      - PEERDNS=no
/etc/sysconfig/network-scripts/ifcfg-eth1:
  file.append:
    - text:  
      - PEERDNS=no

