###################
# STAGE 1: builder
###################

FROM node:18-slim as builder

ARG MB_EDITION=oss
ARG VERSION

WORKDIR /home/node

# Install dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y openjdk-11-jdk curl git && \
    curl -O https://download.clojure.org/install/linux-install-1.11.1.1262.sh && \
    chmod +x linux-install-1.11.1.1262.sh && \
    ./linux-install-1.11.1.1262.sh && \
    rm -rf /var/cache/apt

# Copy source code
COPY . .

# Ensure Git can trust the directory due to owner mismatch
RUN git config --global --add safe.directory /home/node

# Install frontend dependencies
RUN yarn --frozen-lockfile

# Build the project
RUN INTERACTIVE=false CI=true MB_EDITION=$MB_EDITION bin/build.sh :version ${VERSION}

###################
# STAGE 2: runner
###################

FROM eclipse-temurin:21-jre-alpine as runner

ENV FC_LANG en-US LC_CTYPE en_US.UTF-8

# Install runtime dependencies
RUN apk add -U bash fontconfig curl font-noto font-noto-arabic font-noto-hebrew font-noto-cjk java-cacerts && \
    apk upgrade && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /app/certs && \
    curl https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -o /app/certs/rds-combined-ca-bundle.pem && \
    /opt/java/openjdk/bin/keytool -noprompt -import -trustcacerts -alias aws-rds -file /app/certs/rds-combined-ca-bundle.pem -keystore /etc/ssl/certs/java/cacerts -keypass changeit -storepass changeit && \
    curl https://cacerts.digicert.com/DigiCertGlobalRootG2.crt.pem -o /app/certs/DigiCertGlobalRootG2.crt.pem && \
    /opt/java/openjdk/bin/keytool -noprompt -import -trustcacerts -alias azure-cert -file /app/certs/DigiCertGlobalRootG2.crt.pem -keystore /etc/ssl/certs/java/cacerts -keypass changeit -storepass changeit && \
    mkdir -p /plugins && chmod a+rwx /plugins

# Add Metabase script and uberjar
COPY --from=builder /home/node/target/uberjar/metabase.jar /app/
COPY bin/docker/run_metabase.sh /app/

# Expose default runtime port
EXPOSE 3000

# Run Metabase
ENTRYPOINT ["/app/run_metabase.sh"]
