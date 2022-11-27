FROM eclipse-temurin:17-jre-alpine AS runtime
COPY target/helloworld-2.0.jar /

CMD ["java", "-cp", "/helloworld-2.0.jar", "dev.otherdevopsgene.helloworld.HelloWorld"]
