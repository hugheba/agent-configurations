---
applyTo: '**'
---
## Scope
Guidelines for Quarkus services built in Kotlin (primary), Gradle Kotlin DSL, GraalVM (Java 21 LTS) with mandatory native image build and container deployment.

## Toolchain & Build
- Gradle Kotlin DSL only; central version catalog (libs.versions.toml).
- Enforce Java toolchain = GraalVM 21 (org.graalvm.buildtools.native plugin + quarkus plugin).
- Build tasks of interest:
  - ./gradlew quarkusDev (live reload)
  - ./gradlew build -x test (JAR)
  - ./gradlew quarkusBuild -Dquarkus.package.type=native (native)
  - ./gradlew test integrationTest nativeTest
- Enable configuration & build caching plus Gradle configuration cache.
- Reproducible builds: lock dependency versions; forbid dynamic + changing modules.

## Project Structure (Multi‑Module Example)
- domain/ (pure Kotlin, no Quarkus)
- application/ (use cases, services, orchestrations)
- adapters:rest/ (JAX-RS or RESTEasy Reactive endpoints + DTO mapping)
- adapters:db/ (Panache / jOOQ / Hibernate ORM configuration)
- infra:messaging/ (Kafka / AMQP)
- infra:config/ (central ConfigMapping interfaces)
- infra:observability/ (metrics, tracing)
- app/ (main module aggregating others; minimal code)
Keep domain free from framework annotations. REST/DB modules only expose interfaces to application.

## Dependencies & Extensions
Prefer minimal set:
- RESTEasy Reactive (or minimal Vert.x routes if ultra low overhead)
- SmallRye Config (built-in)
- JSON: Use Jackson only if interoperability required; prefer kotlinx-serialization (quarkus-kotlinx-serialization) for native friendliness.
- Persistence: Hibernate ORM with Panache (Reactive or classic) only if rich ORM needed; else jOOQ or reactive client.
- Messaging: SmallRye Reactive Messaging (Kafka) with explicit channel types.
- Observability: micrometer-registry-prometheus, opentelemetry-exporter-otlp.
Avoid heavy reflection / dynamic classpath scanning libraries.

## Kotlin Guidelines
- Enable: kotlinOptions.freeCompilerArgs += ["-Xjsr305=strict", "-Xcontext-receivers"]
- Treat all warnings as errors.
- Use data classes / value classes for simple DTOs and identifiers.
- Extension functions for mapping (no ModelMapper).
- Coroutines: Use quarkus-vertx for context; avoid blocking operations on event loop; use @Blocking where needed.

## Native Image
- Always produce native binary (quarkusBuild -Dquarkus.package.type=native).
- Avoid reflection; where unavoidable add src/main/resources/META-INF/native-image/ configs (register for reflection).
- Prefer compile-time serialization (kotlinx).
- Disable unused features: quarkus.hibernate-orm.sql-load-script=no-file if not needed.
- Verify startup & smoke tests on native in CI.

## Configuration
- Use @ConfigMapping (interfaces) for typed configuration; no direct ConfigProvider usage in business code.
- Validate critical settings at startup (throw IllegalStateException early).
- Externalize secrets to environment / vault; never commit defaults containing secrets.

## Dependency Injection
- Use CDI (Arc).
- Keep bean scopes explicit (Singleton, ApplicationScoped, RequestScoped) – default to ApplicationScoped for stateless components.
- Avoid injecting EntityManager directly inside domain logic; wrap in repository interfaces defined in domain/application boundary.

## REST & Serialization
- Maintain DTO layer; never expose entities directly.
- Use explicit MediaType (application/json).
- Error model: { code, message, correlationId } unified via ExceptionMapper.
- Validation: jakarta.validation annotations; fail-fast with meaningful messages.

## Persistence
- For Hibernate:
  - Enable SQL parameter logging only in dev profile.
  - Use Flyway or Liquibase for migrations (single module controlling schema).
  - Prefer constructor expressions / projections over returning entire entities for read APIs.
- For reactive drivers ensure suspension-friendly API (e.g., Mutiny -> coroutine adapters).

## Logging & Observability
- JSON logs in prod (quarkus.log.console.json=true).
- Include traceId, spanId (OpenTelemetry), correlationId MDC.
- Micrometer metrics endpoint /q/metrics; health endpoints /q/health/live|ready.
- Export traces via OTLP; set sampling via config not code.

## Error Handling
- Map domain errors to HTTP in a central ExceptionMapper.
- No stack traces in client responses; keep in logs at DEBUG level if sensitive.
- Wrap external adapter exceptions; prevent leaking low-level details.

## Security
- Use OIDC extension for authN; enforce RBAC via @RolesAllowed in resources only (not services).
- Validate all untrusted input (query, path, headers).
- Enable TLS termination at ingress; enforce HTTPS redirection if Quarkus serves directly.
- Keep dependencies updated; enable quarkus-devtools to audit.

## Performance
- Favor RESTEasy Reactive + native for minimal latency.
- Avoid blocking calls on IO thread (use @Blocking or move to worker pool).
- Batch database operations; stream large result sets (Reactive Panache or Scrollable results).
- Measure with continuous benchmark (JMH module optional) before optimizing.

## Testing
- Unit: pure Kotlin + JUnit5 (no QuarkusTest).
- QuarkusTest for integration (inject real beans).
- Testcontainers for DB / Kafka; reuse containers between tests.
- Native tests: ./gradlew nativeTest ensures parity.
- Contract tests for REST endpoints (JSON schema or snapshot with strict matching).
- Coverage target >= 70% (exclude generated code).

## Profiles
- dev: hot reload, verbose logging, mock external services.
- test: deterministic; no random ports unless injected.
- prod: optimized log level (INFO), JSON logs, metrics/tracing enabled.

## Containerization
- Use quarkus.container-image.* properties (e.g., build=true, group, name, tag).
- Base image: Distroless / UBI minimal for native (quay.io/quarkus/quarkus-micro-image base OK); consider scratch if fully static.
- Expose minimal ports; run as non-root (set USER).
- Include SBOM (CycloneDX gradle plugin) artifact.

## DevContainer Template
- Mirror existing project devcontainer.json:
  - Install GraalVM 21, native-image.
  - Pre-install Docker CLI for inner builds.
  - Provide tasks for quarkusDev, quarkusBuild (native).
  - Include extensions: RedHat Java, Kotlin, Quarkus tools.

## CI Pipeline (Stages)
1. Validate (format, detekt / ktlint, dependency check)
2. Compile (JVM)
3. Unit tests
4. Integration tests (QuarkusTest + Testcontainers)
5. Native build + native tests
6. Security scan (container + dependencies)
7. Publish artifacts (JAR + native binary + container image)
8. SBOM + provenance

## Observability & Shutdown
- Graceful shutdown hooks close DB pools, flush logs.
- Set quarkus.shutdown.timeout to bounded value.
- Health readiness waits for migrations completion.

## Coding Conventions
- No wildcard imports.
- Sealed classes for domain errors.
- Inline/value classes for IDs (e.g., @JvmInline value class CustomerId(val value: UUID)).
- Clock & UUID providers abstracted for test determinism.

## Documentation
- README in root + module READMEs (purpose, public API).
- ADR explaining Quarkus + native decision and any deviations.
- Update instructions when adding new extensions that affect native configuration.

## Prohibited / Discouraged
- Reflection-heavy mappers (ModelMapper)
- Runtime classpath scanning libraries (unless AOT config provided)
- Mixing blocking & reactive styles without clear boundary
- Direct use of static singletons for stateful services

## Quick Checklist Before Merge
- Native build passes
- No unused dependencies
- Domain free of Quarkus imports
- ConfigMapping covers new settings and validated
- Tests deterministic & passing (JVM + native)
- Logging structured, no secrets
- ADR updated if architectural change

## Devcontainer template
```json
{
  "name": "Java with GraalVM",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/devcontainers/features/common-utils:2": {
      "configureZshAsDefaultShell": true
    },
    "ghcr.io/devcontainers/features/aws-cli:1": {},
    "ghcr.io/devcontainers/features/java:1": {
      "version": "23",
      "jdkDistro": "graalce",
      "installMaven": true
    },
    "ghcr.io/ebaskoro/devcontainer-features/sdkman:1": {
      "candidate": "quarkus"
    },
    "ghcr.io/meaningful-ooo/devcontainer-features/homebrew:2": {},
  },
  "postCreateCommand": "bash ./.devcontainer/post-create-command.sh",
  "forwardPorts": [],
  "containerEnv": {
    "GRAALVM_HOME": "/usr/local/sdkman/candidates/java/current"
  },
  "remoteEnv": {
    "GRAALVM_HOME": "/usr/local/sdkman/candidates/java/current"
  },
  "mounts": [
    "type=bind,source=${localEnv:HOME}/.ssh,target=/home/vscode/.ssh,readonly",
    "type=bind,source=${localEnv:HOME}/.aws,target=/home/vscode/.aws",
    "type=bind,source=${localEnv:HOME}/.m2,target=/home/vscode/.m2",
    "type=bind,source=${localEnv:HOME}/.gradle,target=/home/vscode/.gradle"
  ],
  "customizations": {
    "vscode": {
      "settings": {
        "java.jdt.ls.java.home": "/usr/local/sdkman/candidates/java/current",
        "java.import.gradle.enabled": true,
        "java.import.gradle.java.home": "/usr/local/sdkman/candidates/java/current",
        "java.import.gradle.wrapper.enabled": true,
        "java.test.defaultFramework": "junit5",
        "groovy.lint.enabled": true,
        "gradle.nestedProjects": true,
        "groovy.java.home": "/usr/local/sdkman/candidates/java/current"
      },
        "extensions":[
          "vscjava.vscode-java-pack",
          "dontshavetheyak.groovy-guru",
          "geb.grailstest",
          "dbaeumer.vscode-eslint",
          "fill-labs.dependi",
          "redhat.vscode-quarkus",
          "redhat.vscode-openshift-connector",
          "mtxr.sqltools",
          "mtxr.sqltools-driver-pg",
          "github.vscode-github-actions",
          "PKief.material-icon-theme",
          "42crunch.vscode-openapi",
          "fwcd.kotlin"
        ]
    }
  }
}
```

## Post Create Command
```bash
#!/bin/bash
#!/usr/bin/env bash

# Install Kotlin via SDKMAN
sdk install kotlin

# Install Node
curl https://get.volta.sh | bash
export PATH="$HOME/.volta/bin:$PATH"
$HOME/.volta/bin/volta install node@lts
$HOME/.volta/bin/volta install yarn@latest
```