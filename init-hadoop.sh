# Run on namenode
sudo -u hdfs hadoop namenode -format

# Start namenode, secondarynamenode, and datanodes

# Then,
sudo -u hdfs hadoop fs -mkdir /tmp
sudo -u hdfs hadoop fs -chmod -R 1777 /tmp
sudo -u hdfs hadoop fs -mkdir /mapred/system
sudo -u hdfs hadoop fs -chown mapred:hadoop /mapred/system
sudo -u hdfs hadoop fs -mkdir /hbase
sudo -u hdfs hadoop fs -chown hbase:hbase /hbase
