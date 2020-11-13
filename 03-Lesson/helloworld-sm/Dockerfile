FROM ubuntu:latest AS development
RUN apt-get update && apt-get install -y --no-install-recommends \
  default-jdk-headless \
  git \
  maven \
  && rm -rf /var/lib/apt-get/lists/*
RUN git clone https://github.com/SteampunkFoundry/helloworld.git
WORKDIR /helloworld
RUN mvn clean package

FROM openjdk:11-jre-slim AS runtime
COPY --from=development /helloworld/target/helloworld-1.0.jar /

CMD ["java", "-cp", "/helloworld-1.0.jar", "com.steampunk.helloworld.HelloWorld"]
