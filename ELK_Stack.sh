#!/bin/bash
# Installing ELK via script

wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u65-b17/jdk-8u65-linux-x64.rpm"

sudo yum localinstall jdk-8u65-linux-x64.rpm

rm ~/jdk-8u65-linux-x64.rpm


rpm --import http://packages.elastic.co/GPG-KEY-elasticsearch

echo '[elasticsearch-2.1]
name=Elasticsearch repository for 2.x packages
baseurl=http://packages.elastic.co/elasticsearch/2.x/centos
gpgcheck=1
gpgkey=http://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1 ' | tee  /etc/yum.repos.d/elasticsearch.repo

yum -y install elasticsearch

# vi /etc/elasticsearch/elasticsearch.yml
#You may want to restrict outside access to your Elasticsearch instance (port 9200), so outsiders can't read your data or shutdown your Elasticsearch cluster through the HTTP API. Find the line that specifies network.host, uncomment it, and replace its value with "localhost" so it looks like this:
#elasticsearch.yml excerpt (updated)
#network.host: localhost

  sed -i '/network.host/c\network.host: localhost' /etc/elasticsearch/elasticsearch.yml
  sed -i '/discovery.zen.ping.multicast.enabled/c\discovery.zen.ping.multicast.enabled: false' /etc/elasticsearch/elasticsearch.yml
  sed -i '/cluster.name/c\cluster.name: elasticsearch' /etc/elasticsearch/elasticsearch.yml

  chown -R elasticsearch:elasticsearch /var/lib/elasticsearch/ /var/log/elasticsearch/

systemctl start elasticsearch


systemctl enable elasticsearch


groupadd -g 1005 kibana



useradd -u 1005 -g 1005 kibana

cd ~; wget https://download.elastic.co/kibana/kibana/kibana-4.3.0-linux-x64.tar.gz

tar xvf kibana-*.tar.gz


#vi ~/kibana-4*/config/kibana.yml
#In the Kibana configuration file, find the line that specifies server.host, and replace the IP address ("0.0.0.0" by default) with "localhost":
#server.host: "localhost"

mkdir -p /opt/kibana

cp -R ~/kibana-4*/* /opt/kibana/

chown -R kibana: /opt/kibana

sed -i 's/host: "0.0.0.0"/host: "localhost"/g' /opt/kibana/config/kibana.yml

cd /etc/init.d && sudo curl -o kibana https://gist.githubusercontent.com/thisismitch/8b15ac909aed214ad04a/raw/fc5025c3fc499ad8262aff34ba7fde8c87ead7c0/kibana-4.x-init

cd /etc/default && sudo curl -o kibana https://gist.githubusercontent.com/thisismitch/8b15ac909aed214ad04a/raw/fc5025c3fc499ad8262aff34ba7fde8c87ead7c0/kibana-4.x-default

chmod +x /etc/init.d/kibana

 service kibana start
 
 chkconfig kibana on
 
 # Install Nginx
 
 yum -y install epel-release
 
 yum -y install nginx httpd-tools
 
 htpasswd -c /etc/nginx/htpasswd.users kibanaadmin
 
# sudo vi /etc/nginx/nginx.conf
#Find the default server block (starts with server {), the last configuration block in the file, and delete it. When you are done, the last two lines in the file should look like this:

#    include /etc/nginx/conf.d/*.conf; }

echo 'server {
    listen 80;

    server_name example.com;

    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/htpasswd.users;

    location / {
        proxy_pass http://localhost:5601;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;        
    }
}' | tee /etc/nginx/conf.d/kibana.conf

systemctl start nginx

 systemctl enable nginx
 
echo '[logstash-2.1]
name=logstash repository for 2.1 packages
baseurl=http://packages.elasticsearch.org/logstash/2.1/centos
gpgcheck=1
gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch
enabled=1' | tee /etc/yum.repos.d/logstash.repo

yum -y install logstash

mkdir -p /etc/pki/tls/certs

mkdir /etc/pki/tls/private

cd /etc/pki/tls; sudo openssl req -x509 -batch -nodes -days 3650 -newkey rsa:2048 -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt

cd ..

echo 'input {
  beats {
    port => 5044
    type => "logs"
    ssl => true
    ssl_certificate => "/etc/pki/tls/certs/logstash-forwarder.crt"
    ssl_key => "/etc/pki/tls/private/logstash-forwarder.key"
  }
}' | tee /etc/logstash/conf.d/02-filebeat-input.conf

echo 'filter {
  if [type] == "syslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
      add_field => [ "received_at", "%{@timestamp}" ]
      add_field => [ "received_from", "%{host}" ]
    }
    syslog_pri { }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
}' | tee /etc/logstash/conf.d/10-syslog.conf


echo 'output {
  elasticsearch { hosts => ["localhost:9200"] }
  stdout { codec => rubydebug }
}' | tee /etc/logstash/conf.d/30-elasticsearch-output.conf


 service logstash configtest
 
 systemctl restart logstash
 
 
 chkconfig logstash on
 
 #logstash forwarder setup
 
 rpm --import http://packages.elasticsearch.org/GPG-KEY-elasticsearch
 
 cat >> /etc/yum.repos.d/logstash-forwarder.repo << REPO
[logstash-forwarder]
name=logstash-forwarder repository
baseurl=http://packages.elasticsearch.org/logstashforwarder/centos
gpgcheck=1
gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch
enabled=1
REPO

yum -y install logstash-forwarder

rm /etc/logstash-forwarder.conf
cat >> /etc/logstash-forwarder.conf << FORWARD
{
The network section covers network configuration :)
  "network": {
"servers": [ "elk.mckendrick.io:5000" ],
"timeout": 15,
"ssl ca": "/etc/pki/tls/certs/logstash-forwarder.crt"
  },

The list of files configurations
  "files": [
{
  "paths": [
"/var/log/messages",
"/var/log/secure",
"/var/log/fail2ban.log"
   ],
  "fields": { "type": "syslog" }
}
  ]
}
FORWARD

systemctl restart logstash-forwarder restart
systemctl enable logstash-forwarder 


