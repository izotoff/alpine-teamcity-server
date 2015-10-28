FROM alpine
RUN echo http://mirror.yandex.ru/mirrors/alpine/v3.2/main > /etc/apk/repositories
RUN apk add --update perl openssl openjdk7-jre-base && rm -rf /var/cache/apk/*

# TeamCity data is stored in a volume to facilitate container upgrade
ENV TEAMCITY_DATA_PATH /data/teamcity
ENV URI_PREFIX cis
ENV URI_BACKUP ftp://art:art@art.kyiv.ciklum.net/teamcity/cis2/cis2_20150601_063043.zip
ENV JAVA_HOME /usr/lib/jvm/default-jvm
ENV TEAMCITY_APP_DIR $TEAMCITY_DATA_PATH/webapps/$URI_PREFIX


# Download and install TeamCity to /opt
ENV TEAMCITY_PACKAGE TeamCity-9.1.3.tar.gz
ENV TEAMCITY_DOWNLOAD http://download.jetbrains.com/teamcity
ENV TEAMCITY_DOWNLOAD ftp://art:art@art.kyiv.ciklum.net/teamcity
WORKDIR /opt 
RUN wget $TEAMCITY_DOWNLOAD/$TEAMCITY_PACKAGE && \
	tar zxf $TEAMCITY_PACKAGE && \
	rm -rf TeamCity/buildAgent && \
        mkdir TeamCity/webapps/$URI_PREFIX &&\
	mv TeamCity/webapps/ROOT/* TeamCity/webapps/$URI_PREFIX/ && \
	rm -rf $TEAMCITY_PACKAGE && \
	echo "<% response.sendRedirect(\"/$URI_PREFIX/overview.html\");%>" > TeamCity/webapps/ROOT/index.jsp

WORKDIR $TEAMCITY_DATA_PATH/lib/jdbc
RUN wget https://jdbc.postgresql.org/download/postgresql-9.4-1204.jdbc41.jar 

WORKDIR /tmp
RUN echo connectionProperties.user=postgres >database.properties && \
	echo connectionProperties.password=postgres >>database.properties && \ 
	echo "connectionUrl=jdbc:postgresql://db/$URI_PREFIX" >>database.properties 
RUN echo "#!/bin/sh" > restore.sh && \
	echo "wget -O /tmp/backup.zip $URI_BACKUP" >>restore.sh && \
	echo /opt/TeamCity/bin/maintainDB.sh restore -F /tmp/backup.zip -T /tmp/database.properties >>restore.sh && \
	chmod a+x restore.sh

WORKDIR /opt/TeamCity/bin
VOLUME  ["/data/teamcity"]
EXPOSE 8111
CMD ["/opt/TeamCity/bin/teamcity-server.sh", "run"]
