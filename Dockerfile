FROM alpine
RUN echo http://mirror.yandex.ru/mirrors/alpine/v3.2/main > /etc/apk/repositories
RUN apk add --update perl openssl openjdk7-jre-base && rm -rf /var/cache/apk/*
#RUN apt-get install openjdk-7-jre
# TeamCity data is stored in a volume to facilitate container upgrade
ENV TeamCity_home /opt/TeamCity
ENV TEAMCITY_DATA_PATH /data/TeamCity
ENV TEAMCITY_APP_DIR $TeamCity_home/webapps/ROOT

ENV URI_PREFIX cis2
ENV URI_BACKUP ftp://art:art@art.kyiv.ciklum.net/teamcity/cis2/cis2_20150601_063043.zip
ENV URI_TEAMCITY http://download.jetbrains.com/teamcity
ENV URI_TEAMCITY ftp://art:art@art.kyiv.ciklum.net/teamcity
ENV URI_JDBC https://jdbc.postgresql.org/download
ENV URI_JDBC ftp://art:art@art.kyiv.ciklum.net/teamcity

ENV TEAMCITY_PACKAGE TeamCity-9.1.6.tar.gz
ENV PSQL_JDBC postgresql-9.4.1208.jre7.jar
ENV JAVA_HOME /usr/lib/jvm/default-jvm


# Download and install TeamCity to /opt

WORKDIR /opt
RUN wget -O- $URI_TEAMCITY/$TEAMCITY_PACKAGE |  tar -zx && \
        rm -rf TeamCity/buildAgent && \
        rm -rf $TEAMCITY_PACKAGE && \
        rm -rf TeamCity/webapps/ROOT/WEB-INF/plugins/idea-tool

#        mkdir TeamCity/webapps/$URI_PREFIX &&\
#       mv TeamCity/webapps/ROOT/* TeamCity/webapps/$URI_PREFIX/ && \
#       echo "<% response.sendRedirect(\"/$URI_PREFIX/overview.html\");%>" > TeamCity/webapps/ROOT/index.jsp

WORKDIR $TEAMCITY_DATA_PATH/lib/jdbc
RUN wget $URI_JDBC/$PSQL_JDBC

WORKDIR /tmp
RUN echo connectionProperties.user=postgres >database.properties && \
        echo connectionProperties.password=postgres >>database.properties && \
        echo "connectionUrl=jdbc:postgresql://db/$URI_PREFIX" >>database.properties
RUN echo "#!/bin/sh" > restore.sh && \
        echo "wget -O /tmp/backup.zip $URI_BACKUP" >>restore.sh && \
        echo /opt/TeamCity/bin/maintainDB.sh restore -F /tmp/backup.zip -T /tmp/database.properties >>restore.sh && \
        chmod a+x restore.sh

WORKDIR /opt/TeamCity/bin
#RUN sed  -i 's/\.\/catalina\.sh /exec &/' teamcity-server.sh
VOLUME  ["/data/teamcity"]
EXPOSE 8111
#CMD ["/opt/TeamCity/bin/teamcity-server.sh", "run"]
CMD ["/tmp/restore.sh"]
