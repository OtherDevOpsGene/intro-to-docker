FROM ubuntu:latest AS development
RUN apt-get update && apt-get install -y --no-install-recommends \
  openjdk-17-jdk-headless \
  git \
  maven \
  && rm -rf /var/lib/apt-get/lists/*
RUN git clone https://github.com/OtherDevOpsGene/helloworld.git
WORKDIR /helloworld
RUN mvn clean package

FROM eclipse-temurin:17-jre-alpine AS runtime
COPY --from=development /helloworld/target/helloworld-2.0.jar /

CMD ["java", "-cp", "/helloworld-2.0.jar", "dev.otherdevopsgene.helloworld.HelloWorld"]
