# ========== Stage 1: Build ==========
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
COPY ai-agent-api/pom.xml ai-agent-api/
COPY ai-agent-app/pom.xml ai-agent-app/
COPY ai-agent-domain/pom.xml ai-agent-domain/
COPY ai-agent-trigger/pom.xml ai-agent-trigger/
COPY ai-agent-infrastructure/pom.xml ai-agent-infrastructure/
COPY ai-agent-types/pom.xml ai-agent-types/
RUN mvn dependency:go-offline -B || true
COPY . .
RUN mvn clean package -DskipTests -B

# ========== Stage 2: Run ==========
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=builder /app/ai-agent-app/target/*.jar app.jar
EXPOSE 8066
ENTRYPOINT ["java", "-jar", "-Dserver.address=0.0.0.0", "-Dspring.data.redis.host=redis", "app.jar"]
