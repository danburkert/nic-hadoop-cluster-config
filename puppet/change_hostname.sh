mac_addr=`ifconfig | grep eth0 | awk '{ print $5 }'`
case $mac_addr in
00:25:90:96:3a:90) hostname=nic-hadoop-smmc01 ;;
00:25:90:96:3a:a0) hostname=nic-hadoop-smmc02 ;;
00:25:90:96:3b:10) hostname=nic-hadoop-smmc03 ;;
00:25:90:96:3a:fc) hostname=nic-hadoop-smmc04 ;;
00:25:90:96:3b:e4) hostname=nic-hadoop-smmc05 ;;
00:25:90:96:3a:6a) hostname=nic-hadoop-smmc06 ;;
00:25:90:96:3d:42) hostname=nic-hadoop-smmc07 ;;
00:25:90:96:3d:80) hostname=nic-hadoop-smmc08 ;;
*) hostname=`hostname` ;;
esac
echo "MAC Address is $mac_addr"
echo "Setting hostname to $hostname"
echo $hostname > /etc/hostname
service hostname restart
