FROM alpine
RUN echo http://mirror.yandex.ru/mirrors/alpine/v3.2/main > /etc/apk/repositories
RUN apk add --update openssl openjdk7-jre-base && rm -rf /var/cache/apk/*

# TeamCity data is stored in a volume to facilitate container upgrade
ENV TEAMCITY_DATA_PATH /data/teamcity
ENV URI_PREFIX cis
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
	rm -rf $TEAMCITY_PACKAGE

RUN wget https://jdbc.postgresql.org/download/postgresql-9.4-1204.jdbc41.jar && \
	mkdir -p $TEAMCITY_DATA_PATH/lib/jdbc && \
	mv postgresql-9.4-1204.jdbc41.jar $TEAMCITY_DATA_PATH/lib/jdbc/ 

RUN echo "<% response.sendRedirect(\"/$URI_PREFIX/overview.html\");%>" > TeamCity/webapps/ROOT/index.jsp
RUN mkdir -p $TEAMCITY_DATA_PATH/config && \
	echo connectionProperties.user=postgres >$TEAMCITY_DATA_PATH/config/database.properties && \
	echo connectionProperties.password=postgres >>$TEAMCITY_DATA_PATH/config/database.properties && \ 
	echo connectionUrl=jdbc\:postgresql\://db/$URI_PREFIX >>$TEAMCITY_DATA_PATH/config/database.properties 

VOLUME  ["/data/teamcity"]
EXPOSE 8111
CMD ["/opt/TeamCity/bin/teamcity-server.sh", "run"]
