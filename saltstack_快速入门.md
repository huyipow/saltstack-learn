#关于salt简介

salt是一个异构平台基础设置管理工具(虽然我们通常只用在Linux上)，使用轻量级的通讯器ZMQ,用Python写成的批量管理工具，完全开源，遵守Apache2协议，与Puppet，Chef功能类似，有一个强大的远程执行命令引擎，也有一个强大的配置管理系统，通常叫做Salt State System。

![](http://i.imgur.com/b8Ezo4Y.png)
#saltstack 快速入门-远程执行

 实验环境准备2台虚拟机,主机名如下

    node1-host saltstack-node1.example.com
    node2-host saltstack-node2.example.com

##安装saltstack

安装centos6 epel-release 扩展包

配置 salt yum 仓库包安装salt-master

    rpm --import https://repo.saltstack.com/yum/redhat/6/x86_64/latest/SALTSTACK-GPG-KEY.pub   
    [saltstack-repo]
    name=SaltStack repo for RHEL/CentOS $releasever
    baseurl=https://repo.saltstack.com/yum/redhat/$releasever/$basearch/latest
    enabled=1
    gpgcheck=1
    gpgkey=https://repo.saltstack.com/yum/redhat/$releasever/$basearch/latest/SALTSTACK-GPG-KEY.pub

 node1 安装管理端及客户端 master minion

    yum install salt-master salt-minion#管理端安装


node2 安装客户端minion

    yum install salt-minion #客户端安装

修改客户端配置指向master

    vim /etc/salt/minion
    master: 192.168.10.251



salt-run 该命令执行runner(salt带的或者自定义的，runner以后会讲)，通常在master端执行，比如经常用到的manage

    salt-run [options] [runner.func]
    salt-run manage.status   ##查看所有minion状态
    salt-run manage.down ##查看所有没在线minion
    salt-run manged.up   ##查看所有在线minion

基于认证的客户端添加

    [root@saltstack-node1 salt]# salt-key 
    Accepted Keys:
    Denied Keys:
    Unaccepted Keys:
    saltstack-node2.example.com
    Rejected Keys:

添加saltstack-node2.example.com 管理

    [root@saltstack-node1 salt]# salt-key -a saltstack-node2.example.com
    [[DThe following keys are going to be accepted:
    Unaccepted Keys:
    saltstack-node2.example.com
    Proceed? [n/Y] y

验证密钥添加是否成功

    [root@saltstack-node1 salt]# salt-key 
    Accepted Keys:
    saltstack-node2.example.com #node2添加成功
    Denied Keys:
    Unaccepted Keys:
    Rejected Keys:
> 添加成功后node2 客户端/etc/salt/pki/minion/目录有minion_master.pub公钥。

    [root@saltstack-node2 minion]# ls
    minion_master.pub  minion.pem  minion.pub
    [root@saltstack-node2 minion]# pwd
    /etc/salt/pki/minion

salt-key 常用选项

- -A, --accept-all    Accept all pending keys #允许所有
- -D, --delete-all    Delete all keys #删除所有
- -d DELETE, --delete=DELETE #删除单个key
- -L, --list-all      List all public keys 

salt 远程命令执行语法， 测试所有节点是否正常

    [root@saltstack-node1 ~]# salt '*' test.ping
    saltstack-node2.example.com:
    True
    saltstack-node1.example.com:
    True

查看node1 负载

    [root@saltstack-node1 ~]# salt 'saltstack-node1.example.com' cmd.run 'uptime'
    saltstack-node1.example.com:
     19:24:53 up 18 min,  1 user,  load average: 0.02, 0.02, 0.01 


##salt 配置管理

编辑salt 配置管理文件自动安装配置nginx web 服务。
修改自定义配置文件存放路径

    vim /etc/salt/master
    file_roots:
      base:
    - /srv/salt

简历配置管理目录，重启服务

    mkdir /srv/salt -p
    [root@saltstack-node1 ~]# service salt-master restart
    Stopping salt-master daemon:   [  OK  ]
    Starting salt-master daemon:   [  OK  ]

安装apache 并开机启动，salt配置文件语法为yaml,2个空格代表一次缩进。严格区分配置文件语法

    [root@saltstack-node1 salt]# cat apache.sls 
    apache-server:
      pkg.installed:
    - names:
      - httpd
      - httpd-devel
      service.running:
    - name: httpd
    - enable: True

    salt '*' state.highstate  #执行配置文件

saltstack 数据系统 Grains详解

##Grain 应用场景


- Grains 可以在state系统中使用，用于配置管理模块。
- grains 可以target中使用，在用来匹配minion，比如匹配操作系统，使用 -G选项
- grains可以用于节点属性信息查询，Grains 保存着收集到的客户端的详细信息。


> 
    salt 'saltstack-node1.example.com' grains.ls #grains模块查看
    # salt 'saltstack-node1.example.com' grains.items  #节点基本属性查看

查看node1 节点fqdn 属性

    [root@saltstack-node1 ~]# salt 'saltstack-node1.example.com' grains.get fqdn
    saltstack-node1.example.com:
    	saltstack-node1.example.com

###  grains可以保持在minion端、通过master端下发等多个方式来分发。但不同的方法有不同的优先级的：
  

   1. /etc/salt/grains

   2. /etc/salt/minion

   3. /srv/salt/_grains/  master端_grains目录下


##自定义grains 标签

    vim /etc/salt/minion
    grains:
      roles: nginx
      env: test

同时也可以编辑 /etc/salt/grains ，建议使用此方法标记grains。

    [root@saltstack-node1 salt]# cat /etc/salt/grains 
    cloud: openstack

    [root@saltstack-node1 ~]# service salt-minion restart
    Stopping salt-minion daemon:   [  OK  ]
    Starting salt-minion daemon:   [  OK  ]
    
    [root@saltstack-node1 salt]# salt 'saltstack-node1.example.com' grains.get role
    saltstack-node1.example.com:
    nginx
    [root@saltstack-node1 salt]# salt 'saltstack-node1.example.com' grains.get env
    saltstack-node1.example.com:
    test
    [root@saltstack-node1 salt]# salt 'saltstack-node1.example.com' grains.get cloud
    saltstack-node1.example.com:
    openstack

> 如果出现Minion did not return. [No response] ，建议先test.ping一下

使用系统标准grains  查看系统负载

    [root@saltstack-node1 salt]# salt -G os:Centos cmd.run 'uptime'
    saltstack-node1.example.com:
     05:37:48 up  5:05,  1 user,  load average: 0.09, 0.03, 0.01
    saltstack-node2.example.com:
     21:37:48 up  5:05,  0 users,  load average: 0.00, 0.00, 0.00

使用自定义grains 查看系统负载

    [root@saltstack-node1 salt]# salt -G role:nginx cmd.run 'uptime'
    saltstack-node1.example.com:
     05:39:18 up  5:06,  1 user,  load average: 0.02, 0.02, 0.00

 top.sls 中使用grains

    base:
      'role:nginx'
    - match: grain
    - web.nginx

   
##saltstack 数据系统-pillar

- 存储位置：存储在master 端，存放需要提供给minion的信息
- 应用场景： 敏感信息：每个minion 只能访问master分配给自己的


> master端配置 pillar 根目录
    vim /etc/salt/master
    pillar_roots:
      base:
       - /srv/pillar

    [root@saltstack-node1 pillar]# cat top.sls 
    base:
      'saltstack-node2.example.com':
        - Zabbix
    
    [root@saltstack-node1 pillar]# cat zabbix.sls 
    Zabbix_server: 192.168.10.251 

刷新pillar

    [root@saltstack-node1 pillar]# salt '*' saltutil.refresh_pillar
    saltstack-node2.example.com:
    True
    saltstack-node1.example.com:
    True 

查看 自定义pillar
[root@saltstack-node1 pillar]# salt '*' pillar.item Zabbix_server
saltstack-node2.example.com:
    ----------
    Zabbix_server:
        192.168.10.251
saltstack-node1.example.com:
    ----------
    Zabbix_server:

## salt远程执行-targeting 详解

使用正则表达匹配 tatget

    [root@saltstack-node1 ~]# salt -E 'saltstack-(node1|node2).example.com' test.ping
    saltstack-node1.example.com:
    True
    使用IP 方式
    [root@saltstack-node1 ~]# salt -S  192.168.10.0/24 test.ping
    saltstack-node1.example.com:
    True

##salt 模块管理方法

网络模块使用 network

获取所有链接信息
    # salt '*' network.active_tcp

服务管理模块 service

    [root@saltstack-node1 ~]# salt '*' service.stop httpd
    saltstack-node1.example.com:
    True
    saltstack-node2.example.com:
    True
    [root@saltstack-node1 ~]# salt '*' service.status httpd
    saltstack-node2.example.com:
    False
    saltstack-node1.example.com:
    False
    [root@saltstack-node1 ~]# salt '*' service.start httpd
    saltstack-node2.example.com:
    True
    saltstack-node1.example.com:
    True
    

系统状态模块 state:
> state 	Control the state system on the minion.

模块的ACL 禁止root 用户执行cmd 模块

    vim /etc/salt/master
    client_acl_blacklist:
    #  users:
    #- root
    #- '^(?!sudo_).*$'   #  all non sudo users
      modules:
        - cmd
注意重启master 服务

    [root@saltstack-node1 salt]# service salt-master restart
    Stopping salt-master daemon:   [  OK  ]
    Starting salt-master daemon:   [  OK  ]
    [root@saltstack-node1 salt]# salt  '*' cmd.run w
    Failed to authenticate! This is most likely because this user is not permitted to execute commands, but there is a small possibility that a disk error occurred (check disk/inode usage).
    

## salt-returner 详解

所有minion 客户端依赖包安装python-mysqldb

    yum install mysql-server MySQL-python -y

    minion 端配置mysql
    
    vim /etc/salt/minion
    
    mysql.host: '192.168.10.251'
    mysql.user: 'salt'
    mysql.pass: 'salt'
    mysql.db: 'salt'
    mysql.port: 3306

创建mysql salt 库及表

    CREATE DATABASE  `salt`
      DEFAULT CHARACTER SET utf8
      DEFAULT COLLATE utf8_general_ci;
    
    USE `salt`;
    
    --
    -- Table structure for table `jids`
    --
    
    DROP TABLE IF EXISTS `jids`;
    CREATE TABLE `jids` (
      `jid` varchar(255) NOT NULL,
      `load` mediumtext NOT NULL,
      UNIQUE KEY `jid` (`jid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    CREATE INDEX jid ON jids(jid) USING BTREE;
    
    --
    -- Table structure for table `salt_returns`
    --
    
    DROP TABLE IF EXISTS `salt_returns`;
    CREATE TABLE `salt_returns` (
      `fun` varchar(50) NOT NULL,
      `jid` varchar(255) NOT NULL,
      `return` mediumtext NOT NULL,
      `id` varchar(255) NOT NULL,
      `success` varchar(10) NOT NULL,
      `full_ret` mediumtext NOT NULL,
      `alter_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      KEY `id` (`id`),
      KEY `jid` (`jid`),
      KEY `fun` (`fun`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    
    --
    -- Table structure for table `salt_events`
    --
    
    DROP TABLE IF EXISTS `salt_events`;
    CREATE TABLE `salt_events` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `tag` varchar(255) NOT NULL,
    `data` mediumtext NOT NULL,
    `alter_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `master_id` varchar(255) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `tag` (`tag`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;


执行测试 mysql return

    salt '*' test.ping --return mysql

查看mysql salt_returns 表是否有数据

    select *  from  salt.salt_returns\G;

    *************************** 7. row ***************************
       fun: test.ping
       jid: 20160506073143570942
    return: true
    id: saltstack-node2.example.com
       success: 1
      full_ret: {"fun_args": [], "jid": "20160506073143570942", "return": true, "retcode": 0, "success": true, "fun": "test.ping", "id": "saltstack-node2.example.com"}
    alter_time: 2016-05-06 07:31:43
    *************************** 8. row ***************************
       fun: test.ping
       jid: 20160506073143570942
    return: true
    id: saltstack-node1.example.com
       success: 1
      full_ret: {"fun_args": [], "jid": "20160506073143570942", "return": true, "retcode": 0, "success": true, "fun": "test.ping", "id": "saltstack-node1.example.com"}
    alter_time: 2016-05-06 07:31:44

## salt 配置管理详解
- 【开发环境】
- 【测试环境】
- 【生产环境】

>     vim /etc/salt/master
>     
>     file_roots:
>       base:
>     - /srv/salt
>       dev:
>     - /srv/salt/dev/
>       test:
>     - /srv/salt/test/
>       prod:
>     - /srv/salt/prod/


环境目录创建

    mkdir /srv/salt/{dev,test,prod}

##saltstack  配置管理-states 编写技巧
文件路径 /srv/salt/init

    [root@saltstack-node1 init]# cat dns.sls 
    /etc/resolv.conf:   #管理的目标文件
      file.managed:
        - source: salt://init/files/resolv.conf  #管理的模板文件，文件路径相对salt root路径。
        - user: root
        - group: root
        - mode: 644
 
源文件模板

     cp /etc/resolv.conf /srv/salt/init/files/ 

top.sls 指定全局引用文件

    [root@saltstack-node1 salt]# cat top.sls 
    base:
      '*':
        - init.dns


执行 dns.sls模块文件

`# salt '*' state.highstate  `  

#salt YAML 语法编写规则
缩进、冒号、短横线 三大规则

- YAML 使用一个固定的缩进风格表示数据层结构关系。
- salt需要每个缩进级别由两个空格组成
- **不要使用tabs** 
- my_key: my_value
- 使用短横线加一个空格表示列表功能，

##salt 配置管理 LAMP 自动化部署

![](http://i.imgur.com/edycO6C.png)

lamp.sls 文件编写

    [root@saltstack-node1 dev]# cp /etc/httpd/conf/httpd.conf files/
    [root@saltstack-node1 dev]# cp /etc/my.cnf  files/
    
    [root@saltstack-node1 dev]# cat lamp.sls 
    lamp-pkg-install:
      pkg.installed: 
        - names:
          - httpd
          - php
          - php-cli
          - php-common
          - mysql
          - mysql-server
          - php-mysql
          - php-pdo
    
    apache-server:
      file.managed:
        - name: /etc/httpd/conf/httpd.conf
        - source: salt://dev/files/httpd.conf
        - user: root
        - group: root
        - mode: 644
      service.running:
        - name: httpd
        - enable: True
    
    mysql-service
      file.managed:
        - name: /etc/my.cnf
        - source: salt://dev/files/my.cnf
        - user: root
        - group: root
        - mode: 644
      service.running:
        - name: mysqld
        - enable: True

执行生效

    # salt '*' state.highstate

- pkg 包管理常见模块

![](http://i.imgur.com/sga3gjU.png)

- 文件管理模块

![](http://i.imgur.com/phRXtZY.png)

- 服务管理模块

![](http://i.imgur.com/YEju1mA.png)

## salt 处理状态间关系

![](http://i.imgur.com/L0quxej.png)

###require 与 require_in

- require: a 依赖于 b

- require_in: b 被a 依赖

执行结果一直，区别于位置不同。

    apache-server:
      pkg.installed:
    - name: httpd
      file.managed:
    - name: /etc/httpd/conf/httpd.conf
    - source: salt://files/httpd.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: apache-server    #只有安装了 httpd 软件包，才会执行复制http.conf配置文件
      service.running:
    - name: httpd
    - enable: True
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
      service.running:
    - name: mysqld

### watch 与 watch_in 

    apache-server:
      pkg.installed:
    - name: httpd
      file.managed:
    - name: /etc/httpd/conf/httpd.conf
    - source: salt://files/httpd.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: apache-server
      service.running:
    - name: httpd
    - enable: True
    - reload: True #使用reload 方式启动服务，默认为restart。
    - watch: 
      - file: apache-serve #当发现httpd.conf 模板配置文件被修改，重新修改minion 端httpd.conf配置文件。

watch_in

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
    - watch_in:          ##当发现my.cnf 模板配置文件被修改，重新修改minion 端my.cnf配置文件
      - service: mysql-service
      service.running:
    - name: mysqld
    - enable: True
    

##saltstack 使用Jinja2 模板

- 官网地址：http://jinja.pocoo.org/
- 文件状态使用template
- 模板文件变量使用{{var}}

###使用jinjia 模板 配置 apahce 监听端口为变量

    # vim /srv/salt/dev/files/httpd.conf
    Listen {{HOST}}:{{ PORT }}

###salt 配置模板文件 lamp.sls 引用template

    apache-server:
      pkg.installed:
    - name: httpd
      file.managed:
    - name: /etc/httpd/conf/httpd.conf
    - source: salt://files/httpd.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja #引用变量值
    - defaults:
    - HOST: 192.168.10.250
      PORT: 8080
    - require:
      - pkg: apache-server
      service.running:
    - name: httpd
    - enable: True
    - reload: True
    - watch:
      - file: apache-server

执行生效

    # salt '*' state.highstate

- 变量使用Grains:  {{grains['fqdn_ip4']}}
- 变量使用执行摸块
- 变量使用Pillar


>     apache-server:
>       pkg.installed:
>     - name: httpd
>       file.managed:
>     - name: /etc/httpd/conf/httpd.conf
>     - source: salt://files/httpd.conf
>     - user: root
>     - group: root
>     - mode: 644
>     - template: jinja
>     - defaults:
>       HOST: {{ grains['ipv4'][1] }}  #使用grains-ipv4 变量，获取列表第二个参数 
>       PORT: 8080
>     - require:
>       - pkg: apache-server
>       service.running:
>     - name: httpd
>     - enable: True
>     - reload: True
>     - watch:
>       - file: apache-server
>     

###使用salt远程执行模块

    > # salt '*' network.hw_addr eth1
    > 
    > apache-server:
    >   pkg.installed:
    > - name: httpd
    >   file.managed:
    > - name: /etc/httpd/conf/httpd.conf
    > - source: salt://files/httpd.conf
    > - user: root
    > - group: root
    > - mode: 644
    > - template: jinja
    > - defaults:
    >   HOST: {{ grains['ipv4'][1] }}
    >   PORT: 8080
    >   MAC: {{salt['network.hw_addr']('eth1')}}  #使用salt远程执行模块
    > - require:
    >   - pkg: apache-server
    >   service.running:
    > - name: httpd
    > - enable: True
    > - reload: True
    > - watch:
    >   - file: apache-server

### 使用pillar 

指定 pillar 变量文件路径

----------

    vim /etc/salt/master
    pillar_roots:
      base:
    - /srv/salt/pillar  #pillar top.sls 路径
      dev:
    - /srv/salt/dev/pillar  #dev 环境pillar 引用
    

 
###指明pillar top.sls 
    
    [root@saltstack-node1 pillar]# cat /srv/salt/pillar/top.sls 
    dev:
      'saltstack-node2.example.com':
        - apache

### 引用 dev 环境名为apache pillar

    [root@saltstack-node1 pillar]# cat /srv/salt/dev/pillar/apache.sls 
    apache:
      HOST: {{ grains['ipv4'][1] }}
      PORT: 8080
      MAC: {{salt['network.hw_addr']('eth1')}}

###使用pillar 定义模板

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


##salt 系统初始化配置

![](http://i.imgur.com/dqnkNPx.png)

###初始kernel 参数
    
    [root@saltstack-node1 init]# cat /srv/salt/init/sysctl.sls 
    net.ipv4.ip_forward:
      sysctl.present:
        - value: 1
    vm.swappiness:
      sysctl.present:
        - value: 0

    # salt '*' state.sls init.sysctl  #初始化执行
### 初始化 history 历史记录格式

    [root@saltstack-node1 init]# cat history.sls 
    /etc/profile:
      file.append:
    - text:  
      - export HISTTIMEFORMAT="%F %T `whoami` "
    
    
### 指令审计

    [root@saltstack-node1 init]# cat cmd.sls 
    /etc/bashrc:
      file.append:
        - text:
          - export PROMEPT_COMMAND='{ msg=$(history 1 | {read x y; echo $y; });logger "[euid=$(whoami)]":$(who am i):[`pwd`]"$msg"; }'
    
### salt agent 安装


    [root@saltstack-node1 init]# cat salt_agent.sls 
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


    
### top.sls 全局引用

    [root@saltstack-node1 init]# cat env_init.sls 
    include:
      - init.history
      - init.cmd
      - init.sysctl
      - init.dns
      - init.epel
      - init.salt_agent
    [root@saltstack-node1 init]# cat /srv/salt/top.sls 
    base:
      '*':
        - init.env_init
    dev:
      'saltstack-node2.example.com':
        - lamp


