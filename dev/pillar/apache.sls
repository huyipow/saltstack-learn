apache:
  HOST: {{ grains['ipv4'][1] }}
  PORT: 80
  MAC: {{salt['network.hw_addr']('eth1')}}

