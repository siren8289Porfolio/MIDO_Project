# ── Build (Gradle / Spring Boot) ──────────────────────────────────────────────
FROM eclipse-temurin:21-jdk AS build

WORKDIR /app

COPY spring/gradlew spring/gradlew.bat ./
COPY spring/gradle ./gradle
COPY spring/build.gradle.kts spring/settings.gradle.kts ./

RUN chmod +x gradlew \
 && ./gradlew dependencies --no-daemon -q || true

COPY spring/src ./src

RUN ./gradlew bootJar --no-daemon -x test

# ── Run ───────────────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre

WORKDIR /app

RUN useradd --create-home --shell /bin/bash appuser
USER appuser

COPY --from=build /app/build/libs/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
