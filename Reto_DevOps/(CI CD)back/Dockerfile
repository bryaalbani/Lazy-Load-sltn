FROM openjdk:8-jdk-alpine
EXPOSE 8080
VOLUME /tmp
ARG JAR_FILE
COPY ${JAR_FILE} app.JAR_FILE
ENTRYPOINT ["java","-jar","/app.jar"]

ENV DB_HOST ds029837.mlab.com
ENV DB_PORT 29837
ENV DB_NAME lazy_load_dev
ENV DB_USER user
ENV DB_PASS tnsPass0