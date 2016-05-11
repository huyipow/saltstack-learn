pkg-init:
  pkg.group_installed:
    - names:
      - 'Development tools'
pkg-nginx-init:
  pkg.installed:
    - names:
      - openssl-devel
      - openssl
      - libxml2-devel
      - bzip2-devel
      - libcurl-devel
      - libjpeg-turbo-devel
      - libpng-devel
      - freetype-devel
      - mysql-devel
      - swig
      - libjpeg-turbo
      - libpng
      - freetype
      - libxml2
      - zlib
      - zlib-devel
      - libcurl
      - pcre-devel
      - gmp-devel 
      - libmcrypt-devel
      - php-mcrypt
      - mhash-devel
/var/cache/nginx:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
