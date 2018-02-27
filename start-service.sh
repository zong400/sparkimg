#!/bin/bash
sudo service ssh start
if [ ! -d "/usr/local/hadoop/tmp/dfs" ]; then
  /usr/local/hadoop/bin/hadoop namenode -format
fi
/usr/local/hadoop/sbin/start-all.sh
/usr/local/spark/sbin/start-all.sh
