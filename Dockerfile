FROM maven:3.9.3-eclipse-temurin-17-alpine AS builder

COPY ./src/project /home/maven

WORKDIR /home/maven

RUN mvn package && cp /home/maven/target/*.jar /enclave.jar

# Enclave image build stage
FROM enclaive/gramine-os:jammy-33576d39

RUN apt-get update \
    && apt-get install -y libprotobuf-c1 openjdk-17-jre-headless \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /enclave.jar /app/
COPY ./kotlin.manifest.template /app/
COPY ./entrypoint.sh /app/

WORKDIR /app

RUN gramine-argv-serializer "/usr/lib/jvm/java-17-openjdk-amd64/bin/java" "-XX:CompressedClassSpaceSize=8m" "-XX:ReservedCodeCacheSize=8m" "-Xmx8m" "-Xms8m" "-jar" "/app/enclave.jar" > jvm_args.txt

RUN gramine-sgx-gen-private-key \
    && gramine-manifest -Dlog_level=error -Darch_libdir=/lib/x86_64-linux-gnu kotlin.manifest.template kotlin.manifest \
    && gramine-sgx-sign --manifest kotlin.manifest --output kotlin.manifest.sgx

ENTRYPOINT ["sh", "entrypoint.sh"]

