#base:
#  '*':
#    - init.env_init
#dev:
#  'saltstack-node2.example.com':
#    - lamp

prod:
  'saltstack-node4.example.com':
    - bbs.bbs
