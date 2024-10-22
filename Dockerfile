FROM ubuntu:24.04

# Set our our meta data for this container.
LABEL name="Ubuntu PHP 8.3 with SQLSRV and MySQL Workbench For Translating"
LABEL author="Michael R. Bagnall <hello@flyingflip.com>"

WORKDIR /root

ENV TERM=xterm

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/mssql-tools/bin:/opt/mssql/bin

RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential \
  git \
  gnupg \
  libnss3 \
  nano \
  netcat-openbsd \
  ntp \
  software-properties-common \
  sudo \
  vim \
  wget \
  zip \
  mariadb-client \
  mariadb-server \
  curl \
  net-tools \
  gettext \
  rsync \
  unzip \
  zlib1g 

RUN curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc && \
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg &&  \
  curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list |  tee /etc/apt/sources.list.d/mssql-server-2022.list && \
  curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list |  tee /etc/apt/sources.list.d/mssql-release.list && \
  apt update -y && \
  ACCEPT_EULA=Y apt install -y mssql-server mssql-tools unixodbc-dev msodbcsql18 && \
  apt search msodbcsql18 && \
  wget https://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-workbench-community_8.0.38-1ubuntu24.04_amd64.deb && \
  apt-get install -y \
    libatk1.0-0t64 \
    libatkmm-1.6-1v5 \
    libcairo2 \
    libgdk-pixbuf-2.0-0 \
    libglibmm-2.4-1t64 \
    libglx0 \
    libgtk-3-0t64 \
    libgtk2.0-0t6 \
    libgtkmm-3.0-1t6 \
    libopengl0 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libproj25 \
    libsecret-1-0 \
    libsigc++-2.0-0v5 \
    libzip4t64 && \
    DEBIAN_FRONTEND=noninteractive dpkg -i mysql-workbench-community_8.0.38-1ubuntu24.04_amd64.deb

# Add ondrej/php PPA repository for PHP.
RUN add-apt-repository ppa:ondrej/php && \
  apt-get update -y && \
  apt-get upgrade -y && \
  apt-get install dialog && \
  apt -y install apache2 && \
  apt -y install apache2-utils

RUN apt-get install -y \
  php8.3 \
  php8.3-common \
  php8.3-bcmath \
  php8.3-bz2 \
  php8.3-ctype \
  php8.3-curl \
  php8.3-dba \
  php8.3-dom \
  php8.3-exif \
  php8.3-ffi \
  php8.3-fileinfo \
  php8.3-ftp \
  php8.3-gd \
  php8.3-gettext \
  php8.3-iconv \
  php8.3-igbinary \
  php8.3-mbstring \
  php8.3-memcached \
  php8.3-mysqli \
  php8.3-mysqlnd \
  php8.3-mysql \
  php8.3-phar \
  php8.3-posix \
  php8.3-shmop \
  php8.3-simplexml \
  php8.3-soap \
  php8.3-sockets \
  php8.3-sysvsem \
  php8.3-sysvmsg \
  php8.3-sysvshm \
  php8.3-tokenizer \
  php8.3-xml \
  php8.3-dev \
  php8.3-xmlreader \
  php8.3-xmlwriter \
  php8.3-xsl \
  php8.3-zip \
  php8.3-opcache \
  php-pear \
  libapache2-mod-php8.3 && \
  pecl install sqlsrv && \
  pecl install pdo_sqlsrv

COPY etc/apache2/apache2-auth.conf /etc/apache2/apache2-auth.conf
COPY etc/apache2/apache2-noauth.conf /etc/apache2/apache2-noauth.conf
RUN rm /etc/apache2/sites-enabled/000-default.conf
COPY etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf
RUN ln -s /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-enabled/000-default.conf

COPY etc/php/8.3/apache2/php.ini /etc/php/8.3/apache2/php.ini
COPY etc/php/8.3/cli/php.ini /etc/php/8.3/cli/php.ini

# Enable MSSQL PHP modules
RUN printf "; priority=20\nextension=sqlsrv.so\n" > /etc/php/8.3/mods-available/sqlsrv.ini
RUN printf "; priority=30\nextension=pdo_sqlsrv.so\n" > /etc/php/8.3/mods-available/pdo_sqlsrv.ini
RUN phpenmod sqlsrv pdo_sqlsrv

# Configure Apache. Be sure to enable apache mods or you're going to have a bad time.
RUN a2enmod rewrite \
  && a2enmod actions \
  && a2enmod alias \
  && a2enmod deflate \
  && a2enmod dir \
  && a2enmod expires \
  && a2enmod headers \
  && a2enmod mime \
  && a2enmod negotiation \
  && a2enmod setenvif \
  && a2enmod proxy \
  && a2enmod proxy_http \
  && a2enmod speling \
  && a2enmod cgid \
  && a2enmod remoteip \
  && a2enmod ssl \
  && a2enmod php8.3

USER root
WORKDIR /root

ADD etc/run-httpd.sh /run-httpd.sh
RUN chmod -v +x /run-httpd.sh

CMD [ "/run-httpd.sh" ]
