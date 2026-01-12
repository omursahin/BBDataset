# ============================================================================
# MODIFIED: Multi-stage build to automatically compile WebGoat inside Docker
# No need to run 'mvnw package' manually - everything is automated
# ============================================================================

# Build stage - Compile WebGoat
FROM docker.io/eclipse-temurin:25-jdk-noble AS builder

WORKDIR /build

# Copy Maven wrapper and pom.xml first (better layer caching)
COPY mvnw .
COPY mvnw.cmd .
COPY .mvn .mvn
COPY pom.xml .

# Fix Windows CRLF line endings and permissions for mvnw
RUN sed -i 's/\r$//' ./mvnw && chmod +x ./mvnw

# Download dependencies (cached layer if pom.xml doesn't change)
RUN ./mvnw dependency:go-offline -B

# Copy source code
COPY src src
COPY config config
COPY docs docs

# Build the application (skip tests for faster build)
RUN ./mvnw clean package -DskipTests -B

# Runtime stage - Run WebGoat
FROM docker.io/eclipse-temurin:25-jdk-noble

LABEL name="WebGoat: A deliberately insecure Web Application"
LABEL maintainer="WebGoat team"

RUN \
  useradd -ms /bin/bash webgoat && \
  chgrp -R 0 /home/webgoat && \
  chmod -R g=u /home/webgoat

USER webgoat

# Copy built jar from builder stage
COPY --from=builder --chown=webgoat /build/target/webgoat-*.jar /home/webgoat/webgoat.jar

EXPOSE 8080
EXPOSE 9090

ENV TZ=Europe/Amsterdam

WORKDIR /home/webgoat
ENTRYPOINT [ "java", \
   "-Duser.home=/home/webgoat", \
   "-Dfile.encoding=UTF-8", \
   "--add-opens", "java.base/java.lang=ALL-UNNAMED", \
   "--add-opens", "java.base/java.util=ALL-UNNAMED", \
   "--add-opens", "java.base/java.lang.reflect=ALL-UNNAMED", \
   "--add-opens", "java.base/java.text=ALL-UNNAMED", \
   "--add-opens", "java.desktop/java.beans=ALL-UNNAMED", \
   "--add-opens", "java.desktop/java.awt.font=ALL-UNNAMED", \
   "--add-opens", "java.base/sun.nio.ch=ALL-UNNAMED", \
   "--add-opens", "java.base/java.io=ALL-UNNAMED", \
   "--add-opens", "java.base/java.util=ALL-UNNAMED", \
   "--add-opens", "java.base/sun.nio.ch=ALL-UNNAMED", \
   "--add-opens", "java.base/java.io=ALL-UNNAMED", \
   "-Drunning.in.docker=true", \
   "-jar", "webgoat.jar", "--server.address", "0.0.0.0" ]

HEALTHCHECK --interval=5s --timeout=3s \
  CMD curl --fail http://localhost:8080/WebGoat/actuator/health || exit 1
