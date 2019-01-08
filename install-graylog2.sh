#!/bin/bash

set -x 

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Adding EPEL Repo 

echo '[epel]
name=Extra Packages for Enterprise Linux 6 - $basearch
#baseurl=http://download.fedoraproject.org/pub/epel/6/$basearch
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch
failovermethod=priority
enabled=1
gpgcheck=0' | tee /etc/yum.repos.d/epel.repo 

#Adding  mongodb Repo

echo '[10gen]
name=10gen Repository
baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64
gpgcheck=0
enabled=1' | tee /etc/yum.repos.d/10gen.repo

# Installing mogodb

yum install -y mongo-10gen-server && /etc/init.d/mongod start

which nc >/dev/null 2>&1
if  [ $? != 0 ]; then
  yum -y install nc >/dev/null 2>&1
fi

while ! nc -vz localhost 27017; do sleep 1; done

# Installing all pre-reqs

yum install -y gcc gcc-c++ gd gd-devel glibc glibc-common glibc-devel glibc-headers make automake wget tar vim nc libcurl-devel openssl-devel zlib-devel zlib patch readline readline-devel libffi-devel curl-devel libyaml-devel libtoolbisonlibxml2-devel libxslt-devel libtool bison pwgen nc

#install sun java

curl -L http://javadl.sun.com/webapps/download/AutoDL?BundleId=80804 -o java.rpm

rpm -ivh java.rpm

# Download Elasticsearch, Graylog2-Server and Graylog2-Web-Interface

cd /opt

wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.10.noarch.rpm

# Install elasticsearch and start

echo "Installing elasticsearch"

rpm -ivh elasticsearch-0.90.10.noarch.rpm

sed -i -e 's|# cluster.name: elasticsearch|cluster.name: graylog2|' /etc/elasticsearch/elasticsearch.yml

# Restart elasticsearch

service elasticsearch restart

# Install graylog2-server

echo "Installing graylog2-server"

wget http://packages.graylog2.org/releases/graylog2-server/graylog2-server-0.90.0.tgz

tar -xvf graylog2-server-0.90.0.tgz

# Create Symbolic Links

echo "Creating SymLink Graylog2-server"

ln -s graylog2-server-0.9*/ graylog2-serve

echo -n "Enter a password to use for the admin account to login to the Graylog2 webUI: "

read adminpass

echo "You entered $adminpass "

pause 'Press [Enter] key to continue...'

cd graylog2-server/

cp /opt/graylog2-server/graylog2.conf{.example,}

mv graylog2.conf /etc/

pass_secret=$(pwgen -s 96)

admin_pass_hash=$(echo -n $adminpass|sha256sum|awk '{print $1}')

sed -i -e 's|password_secret =|password_secret = '$pass_secret'|' /etc/graylog2.conf
sed -i -e "s|root_password_sha2 =|root_password_sha2 = $admin_pass_hash|" /etc/graylog2.conf
sed -i -e 's|elasticsearch_shards = 4|elasticsearch_shards = 1|' /etc/graylog2.conf
sed -i -e 's|mongodb_useauth = true|mongodb_useauth = false|' /etc/graylog2.conf
sed -i -e 's|#elasticsearch_discovery_zen_ping_multicast_enabled = false|elasticsearch_discovery_zen_ping_multicast_enabled = false|' /etc/graylog2.conf
sed -i -e 's|#elasticsearch_discovery_zen_ping_unicast_hosts = 192.168.1.203:9300|elasticsearch_discovery_zen_ping_unicast_hosts = 127.0.0.1:9300|' /etc/graylog2.conf

# Setting new retention policy setting or Graylog2 Server will not start
sed -i 's|retention_strategy = delete|retention_strategy = close|' /etc/graylog2.conf

# This setting is required as of v0.20.2 in /etc/graylog2.conf
#sed -i -e 's|#rest_transport_uri = http://192.168.1.1:12900/|rest_transport_uri = http://127.0.0.1:12900/|' /etc/graylog2.conf

# Start graylog2-server on bootup

chkconfig --add graylog2-server

chkconfig graylog2-server on

service graylog2-server start

# Install Graylog2-Web-Interface

rpm -Uvh https://packages.graylog2.org/repo/el/6Server/1.1/x86_64/graylog-web-1.1.6-1.noarch.rpm

#Set the URI to localhost:

sed -ie "s/^graylog2-server\.uris=.*/graylog2-server\.uris=\"http:\/\/127.0.0.1:12900\/\"/g" /etc/graylog/web/web.conf

sed -ie "s/^application\.secret=.*/application\.secret=\"$(pwgen -N 1 -s 96)\"/g" /etc/graylog/web/web.conf

#Also, set a timezone in the /etc/graylog/web/web.conf file:

timezone="Europe/London"

/etc/init.d/graylog-web start
