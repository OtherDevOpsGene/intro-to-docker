FROM openjdk:11-jre-slim AS runtime
COPY target/helloworld-1.0.jar /

CMD ["java", "-cp", "/helloworld-1.0.jar", "com.steampunk.helloworld.HelloWorld"]
