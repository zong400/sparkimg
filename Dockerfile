FROM ubuntu:16.04
USER root

# install base tools
RUN apt update \
	&& apt install -y curl tar sudo openssh-server openssh-client rsync openjdk-8-jdk 
	
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 PATH=$PATH:$JAVA_HOME/bin

# add hadoop user and passwordless ssh 
RUN groupadd hadoop \
	&& useradd -g hadoop -G sudo -m hadoop \
	&& chmod u+w /etc/sudoers \
	&& echo 'hadoop ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
	&& chmod u-w /etc/sudoers
	
RUN echo "TZ='Asia/Shanghai'; export TZ" | tee -a /etc/profile

USER hadoop
RUN ssh-keygen -q -N "" -t rsa -f ~/.ssh/id_rsa \
	&& cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys \
	&& echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCfyJOeBBSHCQVlLSQYUSnid/d/tSHPvhsSKFdftvOiUze4bqV0S9oAqQtZ36VF0HRXclzPzLyxEqsB7e5oOTAN2g1ez0osUAmzx6Bzddf+QFvoZizQrkkCYTRNls1d5eY8IS01km/0kxgBcIqqE4eJIXPpY9IXqYZFlRlqi2faW2s5AR9MulOwL3whcZdBeb3PPFLD+9Y+U+T5JLqzpxlQ4LaPBZfU/eyHQuGtLY/pEmaWd//CGDp+0YBcntY3OmcYXHTc1R9RGI+f8qAQcEt1Zn2wY1Sn4SKujBqyZvQgwQb+rkG2Op0Ey+BIR9OjlygiN+0mRK+pDqNULB5t9u6/ ubuntu@wx" >>  ~/.ssh/authorized_keys \
	&& chmod 600 ~/.ssh/authorized_keys \
	&& echo 'StrictHostKeyChecking no' > ~/.ssh/config \
	&& sudo sed -i '/exit/i sudo /etc/init.d/ssh start' /etc/rc.local
	
# download and config hadoop
RUN curl -s http://mirror.bit.edu.cn/apache/hadoop/common/hadoop-2.7.5/hadoop-2.7.5.tar.gz  |sudo tar -xz -C /usr/local/ \
	&& sudo chown -R hadoop:hadoop /usr/local/hadoop-2.7.5 \
	&& sudo ln -s /usr/local/hadoop-2.7.5 /usr/local/hadoop \
	&& mkdir /usr/local/hadoop/tmp
	
ENV HADOOP_PREFIX /usr/local/hadoop
RUN sudo sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh \
	&& sudo sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

COPY ./*-site.xml $HADOOP_PREFIX/etc/hadoop/

# download and config spark
RUN curl -s http://mirror.bit.edu.cn/apache/spark/spark-2.2.1/spark-2.2.1-bin-hadoop2.7.tgz |sudo tar -xz -C /usr/local/ \
	&& sudo chown -R hadoop:hadoop /usr/local/spark-2.2.1-bin-hadoop2.7 \
	&& sudo ln -s /usr/local/spark-2.2.1-bin-hadoop2.7 /usr/local/spark 
	
ENV SPARK_HOME /usr/local/spark

RUN sudo mkdir /etc/slaves
COPY ./slaves /etc/slaves/slaves
RUN rm $HADOOP_PREFIX/etc/hadoop/slaves \
    && ln -s /etc/slaves/slaves $HADOOP_PREFIX/etc/hadoop/slaves \
    && ln -s /etc/slaves/slaves $SPARK_HOME/conf/slaves
	
RUN echo 'export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop' >> $SPARK_HOME/conf/spark-env.sh 

COPY ./start-service.sh /home/hadoop/start-service.sh
RUN sudo chmod +x /home/hadoop/start-service.sh

CMD [ "sh", "-c", "while : ; do sleep 300 ;done"]
