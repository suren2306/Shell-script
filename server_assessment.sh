showdate=$(date +"%b_%d")
Now=$(date +"%b %e")
#echo $Now

echo "Gethering server details $Now"
echo ""


echo "######### hostname #########"
HOSTN=`/bin/hostname`
echo "hostname = $HOSTN"
echo ""
echo ""
echo "####### OS and Platform #######"
OS=`cat /etc/redhat-release | awk '{print $1 " " $4}'`
BIT=`uname -a | awk '{print $12}'`

echo "OS = $OS"
echo "BIT = $BIT"
echo "Version = $BIT"
echo ""
echo ""




echo "####### Memory Size in MB #######" 

MEMT=`free -m | grep Mem |awk '{print $2}'`
MEMU=`free -m | grep Mem |awk '{print $3}'`
MEMF=`free -m | grep Mem |awk '{print $4}'`

echo "Total Memory = $MEMT" 
echo "Used Memory = $MEMU" 
echo "Free Memory = $MEMF" 
echo "" 
echo "" 

echo "#########users details#########" 

UGIDLIMIT=500
awk -v LIMIT=$UGIDLIMIT -F: '($3>=LIMIT) && ($3!=65534)' /etc/passwd | awk '{print $1}' >>/root/text.txt
cut -d ':' -f1 /root/text.txt  | grep -wv '/' | grep -wv chrony 
rm -rf /root/text.txt
echo "" 
echo "" 

echo "#########Partition details#########" 

df -h 

echo "" 
echo "" 

echo "#########Networking#########" 

#NETW=`ip a | grep "inet " | grep global`

ip a | grep "inet " | grep global 
echo "" 
echo "" 


echo "=========Listening Ports===========" 
netstat -tnpl 
echo "" 
echo "" 


echo "#########Iptables rules#########" 
iptables -L 
echo "" 
echo "" 

echo "#########Apache Version#########" 
httpd -v 
echo "" 
echo "" 


echo "#########Apache Modules#########" 
httpd -M 
echo "" 
echo "" 


echo "#########PHP Version#########" 
php -v 
echo "" 
echo "" 


echo "#########PHP Modules#########"
php -m
echo ""
echo ""

echo "#########Mysql Version#########"
mysql -V
echo ""
echo ""


echo "#########Data's to be sync#########"
echo "/etc/password"
echo "/etc/password"
echo "/etc/group"
echo "Crontab"
echo ""
echo ""
exit

