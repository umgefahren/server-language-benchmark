FROM maven:latest AS builder

COPY . .

RUN mvn clean compile assembly:single

FROM openjdk:latest

COPY --from=builder target/ServerBench-1.0-SNAPSHOT-jar-with-dependencies.jar .

EXPOSE 8080 

CMD ["java", "-cp", "ServerBench-1.0-SNAPSHOT-jar-with-dependencies.jar", "xyz.umgefahren.Main"]