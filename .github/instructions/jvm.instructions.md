---
applyTo: '**'
---
# JVM Common Instructions

## Language Preference
1. **Kotlin** (primary) – new code in Kotlin unless a justified exception.
2. **Java** – only when interoperability or external constraints require.
3. **Groovy** – restricted to build scripts (Gradle) or targeted DSL needs.
No new Scala/Clojure unless explicitly approved.

## Build / Tooling
- Runtime / Toolchain: Prefer GraalVM (current LTS) distribution of the JDK; pin via Gradle toolchain.
- Java toolchain: current LTS (e.g. 21) (GraalVM build) pinned via Gradle toolchain.
- Native Images: All deployable applications MUST be capable of building a GraalVM native image (`:app:nativeCompile` / `nativeImage`) unless explicitly exempted (document reason: heavy dynamic classpath scanning, unsupported agents, JVMTI tooling needs, extensive dynamic proxies, JNI complexity).
- Default Delivery Order: (1) Native image for production runtime (fast startup, low RSS), (2) JVM (HotSpot/GraalVM JIT) fallback for local dev & where native not yet viable.
- Provide startup scripts that auto-select native binary if present, else `java -jar`.
- For libraries / pure domain modules: stay JVM bytecode only; no native-specific code unless behind conditional build.
- Build: **Gradle** (Kotlin DSL `build.gradle.kts`). Avoid Maven for new modules.
- Kotlin: latest stable compatible with LTS JDK.
- Reproducible builds; lock versions (version catalogs `libs.versions.toml`).
- Separate API vs implementation dependencies.
- Enable incremental compilation and build caching (local + remote if CI supports).
- Use dependency substitution / version alignment (BOM) to avoid drift.
- Native Image Configuration: Automate generation (e.g. `-H:ConfigurationFileDirectories=...`) and include reflection / resource / JNI config under `native/` directory (checked in). Prefer build-time code generation over runtime reflection.

## Project Structure (example)
- modules kept small & cohesive (multi-module Gradle)
  - core-domain/
  - core-application/ (use-cases, services)
  - adapters:http/, adapters:db/, adapters:messaging/
  - infra:config/, infra:logging/
  - app/ (composition root: wiring, DI, main)
  - tests/ mirrors module layout (no production code in test sources)
- Pure domain: no framework imports.

## Testing

- Use JUnit 5 for all testing
- Write unit tests with descriptive names
- Aim for high test coverage on business logic
- Framework: JUnit 5 + Kotest (spec style) for Kotlin modules.
- Mocking: MockK (Kotlin) / Mockito (Java) – avoid overspecification.
- Pyramid: unit > integration > e2e.
- Deterministic tests only: no time / random without control (use fixed clocks, seeded RNG).
- Coverage target ≥ 70% meaningful (exclude generated code).
- Contract tests at adapter boundaries (HTTP, messaging).
- Testcontainers for DB / external services; reuse containers in CI for speed.
- Include at least one smoke test executing native binary (startup + health endpoint).

## Documentation

- **Kotlin**: Use KDoc for all public APIs
- **Java**: Use JavaDoc for all public APIs
- Document classes, methods, and complex logic
- Include @param, @return, and @throws tags
- README per module (purpose, public API).
- KDoc for complex algorithms / domain rules.
- Architecture Decision Records for major choices (include ADR justifying native image adoption & any exemptions).
- Dependency graph (Gradle tasks) reviewed periodically to prevent tangling.

## Code Quality

- Keep functions small and focused (single responsibility)
- Use immutable data structures when possible
- Prefer composition over inheritance
- Use meaningful variable and function names
- Minimize dependencies and coupling
- Kotlin: ktlint or Spotless + ktlint; Detekt (all critical rules enabled).
- Java: Checkstyle + Spotless + ErrorProne (if feasible).
- Fail CI on any warning (treat as error).
- No wildcard imports.
- Prefer data classes (Kotlin) / records (Java 21) for immutable DTOs.
- Use sealed interfaces / classes for restricted polymorphism.
- Avoid nullable unless necessary; model absence via sealed types or Optional (Java) sparingly.
- For constants: `object` / companion object; no magic numbers.

## Performance

- Avoid reflection in native image targets
- Use lazy initialization appropriately
- Prefer primitive collections for performance-critical code
- Profile and optimize hot paths
- Prefer non-blocking IO (Ktor, Netty, Loom structured concurrency when stable).
- Use coroutines for concurrent flows; avoid GlobalScope.
- Bound thread pools; monitor queue sizes.
- Stream large payloads; avoid loading entire result sets in memory.
- Measure with JMH or microbench harness before optimizing.
- For native images: measure startup time, RSS, throughput vs JVM; track regressions.

## Modern JVM Features

- Use records (Java 14+) or data classes (Kotlin)
- Leverage pattern matching and sealed classes
- **Use virtual threads (Java 21+) for concurrent operations** - preferred for I/O-bound workloads
- Utilize text blocks for multi-line strings

## Dependency Management
- Minimize external libs; prefer stdlib / JDK.
- Logging facade: SLF4J; backend: Logback (or JSON via logstash encoder).
- JSON: Jackson (Kotlin module) or kotlinx.serialization (prefer for new pure Kotlin modules). For native: prefer kotlinx.serialization when possible (reduced reflection).
- HTTP client: Ktor client (Kotlin) or Java 21 HttpClient; avoid Apache HttpClient unless required.
- Concurrency: Kotlin Coroutines (structured concurrency) over raw threads / Executors where Kotlin is used.
- DI: Koin or Dagger/Hilt for lightweight; avoid heavy reflection-based frameworks impeding native image (if using reflection at runtime, document and add configs).
- Persistence: Exposed, jOOQ, or Hibernate with strict configuration; no ad‑hoc SQL string concatenation. For native image builds, ensure chosen ORM's reflection config is maintained.

## Error Handling
- Domain errors: sealed hierarchy; never throw generic Exception in domain.
- Wrap external/infra exceptions; map to domain or a standardized error envelope.
- No silent catch; always log (debug) or propagate.
- Use Result/Either (Arrow or custom) sparingly—prefer clear throwing boundaries + controller translation.

## Configuration
- Single configuration module.
- Use typesafe config (HOCON) or environment variables mapped & validated (e.g. using Konf, or custom validator).
- Validate on startup; fail fast with clear message.
- No mutable global state after bootstrap.
- For native images: avoid runtime scanning for config; explicit binding.

## Logging & Observability
- Structured logging (JSON in production).
- Correlation / trace IDs propagated (MDC or Kotlin context element).
- Metrics: Micrometer or Prometheus client (ensure compatibility with native image: avoid dynamic classpath scanning).
- Tracing: OpenTelemetry SDK; instrument HTTP, DB, messaging (verify native support; supply reflection configs if needed).
- Redact secrets (tokens, passwords) before logging.

## Security
- Keep dependencies updated (Dependabot / Renovate).
- Enable JVM secure defaults: strong TLS, disable obsolete protocols.
- Parameterized queries only.
- Validate and sanitize all external input (HTTP, messaging, files).
- Threat model critical paths; document assumptions.

## Concurrency & Coroutines
- **Java 21+**: Prefer Virtual Threads for blocking I/O operations (database calls, HTTP requests, file operations)
- Use `Executors.newVirtualThreadPerTaskExecutor()` or `Thread.ofVirtual()` for high-concurrency scenarios
- Virtual Threads ideal for request-per-thread models and blocking operations
- **Kotlin**: Use structured coroutines; no launching without parent scope.
- Propagate cancellation.
- Avoid blocking calls inside coroutine contexts; if unavoidable use withContext(Dispatchers.IO).
- Prefer immutable shared state; if mutation needed, use explicit synchronization (Mutex, atomic).
- Choose Virtual Threads (Java) vs Coroutines (Kotlin) based on language and use case; both provide excellent concurrency for I/O-bound work.

## API / HTTP
- Framework: Ktor or Spring Boot (only if ecosystem benefits justify weight). For native first: prefer Ktor (lower reflection footprint) unless Spring features required; if Spring, enable AOT processing.
- Validation: Hibernate Validator (JSR 380) or Konform / custom for Kotlin (Konform often simpler for native).
- Consistent error envelope (code, message, correlationId).
- Use pagination / streaming for large lists.

## Serialization
- Stable external schemas; version explicit.
- Do not expose internal model directly; map to DTOs.
- Enforce null handling; forbid unknown fields unless explicitly allowed.
- Prefer compile-time serialization (kotlinx.serialization) for native image to reduce reflection config.

## Naming & Architecture
- Ubiquitous language in domain layer.
- No framework leakage into domain (no annotations there).
- Keep adapters thin; transformation + delegation only.
- Avoid cyclic dependencies between modules.

## CI / Delivery
- Pipelines: compile (JVM), static analysis, test, integration test, native image build, security scan.
- Build artifacts: include both native binary and JVM JAR (unless exemption).
- Build caches for native: leverage Gradle build cache; enable configuration caching.
- Build artifacts immutable; include commit SHA, version (SemVer).
- SBOM generated (CycloneDX/Gradle plugin).
- Sign artifacts if distribution external.

## Runtime
- Native default for production deployments (reduced cold start, memory).
- JVM fallback supported for diagnostics requiring full JVM (profilers, agents).
- JVM flags (fallback): enable container awareness, -XX:+UseG1GC (or generational ZGC when stable for low pause).
- Export health endpoints (liveness, readiness).
- Use memory/cpu limits aligned with GC tuning (when on JVM); monitor GC metrics.
- For native: monitor process RSS, startup, and add structured readiness delay if required.

## Error & Shutdown Handling
- Central exception mapper (HTTP / messaging) converting domain errors to responses.
- Graceful shutdown: stop accepting traffic, cancel coroutines, flush logs, close pools.
- JVM signals (SIGTERM) handled; timeout enforced before hard exit.
- Native image parity: ensure same shutdown hooks supported (avoid unsupported agents).

## Code Review Checklist (Abbreviated)
- Single responsibility? Module boundaries upheld?
- No unchecked exceptions leaking infrastructure details.
- Logging: no PII/secrets; structured fields present.
- Tests: meaningful, no brittle mocks.
- Concurrency: no unbounded growth risks.
- Types null-safe; no unnecessary platform types.
- Build passes with no warnings.
- Native image compatibility considered (avoid late reflection; configs updated).
- ADR updated if architectural deviation.

## Misc
- Avoid reflection unless required (document justification). If used, add reflection config for native.
- Prefer sealed + when exhaustive checks over instanceof chains.
- Use inline/value classes for domain primitives (IDs, amounts) to prevent type mixups.
- Clock & UUID generation abstracted for testability.
- For dynamic features (ServiceLoader, SPI): verify native support; add resource config where needed.

---

## Framework-Specific Guidelines

### Quarkus (Kotlin Primary)

#### Scope
Guidelines for Quarkus services built in Kotlin (primary), Gradle Kotlin DSL, GraalVM (Java 21 LTS) with mandatory native image build and container deployment.

#### Toolchain & Build
- Gradle Kotlin DSL only; central version catalog (libs.versions.toml).
- Enforce Java toolchain = GraalVM 21 (org.graalvm.buildtools.native plugin + quarkus plugin).
- Build tasks of interest:
  - ./gradlew quarkusDev (live reload)
  - ./gradlew build -x test (JAR)
  - ./gradlew quarkusBuild -Dquarkus.package.type=native (native)
  - ./gradlew test integrationTest nativeTest
- Enable configuration & build caching plus Gradle configuration cache.
- Reproducible builds: lock dependency versions; forbid dynamic + changing modules.

#### Project Structure (Multi‑Module Example)
- domain/ (pure Kotlin, no Quarkus)
- application/ (use cases, services, orchestrations)
- adapters:rest/ (JAX-RS or RESTEasy Reactive endpoints + DTO mapping)
- adapters:db/ (Panache / jOOQ / Hibernate ORM configuration)
- infra:messaging/ (Kafka / AMQP)
- infra:config/ (central ConfigMapping interfaces)
- infra:observability/ (metrics, tracing)
- app/ (main module aggregating others; minimal code)

Keep domain free from framework annotations. REST/DB modules only expose interfaces to application.

#### Dependencies & Extensions
Prefer minimal set:
- RESTEasy Reactive (or minimal Vert.x routes if ultra low overhead)
- SmallRye Config (built-in)
- JSON: Use Jackson only if interoperability required; prefer kotlinx-serialization (quarkus-kotlinx-serialization) for native friendliness.
- Persistence: Hibernate ORM with Panache (Reactive or classic) only if rich ORM needed; else jOOQ or reactive client.
- Messaging: SmallRye Reactive Messaging (Kafka) with explicit channel types.
- Observability: micrometer-registry-prometheus, opentelemetry-exporter-otlp.

Avoid heavy reflection / dynamic classpath scanning libraries.

**Approved Quarkus Extensions**:
- quarkus-resteasy-reactive - REST endpoints
- quarkus-kotlinx-serialization - JSON serialization (required for Kotlin)
- quarkus-hibernate-orm-panache - Database ORM
- quarkus-jdbc-postgresql - PostgreSQL driver
- quarkus-config-yaml - YAML configuration
- quarkus-smallrye-health - Health checks
- quarkus-micrometer-registry-prometheus - Metrics
- quarkus-smallrye-openapi - API documentation
- quarkus-test-h2 - Testing database

**Prohibited Extensions**:
- quarkus-resteasy-jackson - Use kotlinx-serialization instead
- quarkus-jackson - Use kotlinx-serialization instead
- Any Jackson-based extensions - Incompatible with optimal native image compilation

#### Kotlin Guidelines
- Enable: kotlinOptions.freeCompilerArgs += ["-Xjsr305=strict", "-Xcontext-receivers"]
- Treat all warnings as errors.
- Use data classes / value classes for simple DTOs and identifiers.
- Extension functions for mapping (no ModelMapper).
- Coroutines: Use quarkus-vertx for context; avoid blocking operations on event loop; use @Blocking where needed.
- Always add default values to data class properties for JSON deserialization when used as REST or GraphQL requests and responses.

#### Native Image
- Always produce native binary (quarkusBuild -Dquarkus.package.type=native).
- Avoid reflection; where unavoidable add src/main/resources/META-INF/native-image/ configs (register for reflection).
- Prefer compile-time serialization (kotlinx).
- Disable unused features: quarkus.hibernate-orm.sql-load-script=no-file if not needed.
- Verify startup & smoke tests on native in CI.

#### Configuration
- Use YAML configuration files (`application.yml`) over `application.properties`.
- Separate configs by profile (dev, test, prod).
- Use environment variables for sensitive data.
- Use @ConfigMapping (interfaces) for typed configuration; no direct ConfigProvider usage in business code.
- Validate critical settings at startup (throw IllegalStateException early).
- Externalize secrets to environment / vault; never commit defaults containing secrets.

#### Dependency Injection
- Use CDI (Arc).
- Keep bean scopes explicit (Singleton, ApplicationScoped, RequestScoped) – default to ApplicationScoped for stateless components.
- Avoid injecting EntityManager directly inside domain logic; wrap in repository interfaces defined in domain/application boundary.

#### REST & Serialization
- Maintain DTO layer; never expose entities directly.
- Use explicit MediaType (application/json).
- Error model: { code, message, correlationId } unified via ExceptionMapper.
- Validation: jakarta.validation annotations; fail-fast with meaningful messages.

**Serialization Strategy - Use kotlinx.serialization (Not Jackson)**:
- **Always use kotlinx.serialization for all JSON serialization/deserialization**
- **Never use Jackson, GSON, or other reflection-based serializers**
- kotlinx.serialization is compile-time and highly optimized for GraalVM native image
- Jackson requires extensive reflection configuration and increases native image size and build time
- Add `quarkus-kotlinx-serialization` extension to your project

**Serializable Class File Structure**:
- **Always define `@Serializable` classes in separate files**
- When multiple classes are in the same file with `@Serializable` classes, serialization compilation fails
- Each serializable DTO, request, or response class should have its own dedicated file
- This is a requirement of the kotlinx.serialization compiler plugin in Quarkus native builds

```kotlin
// Good: UserResponse.kt (separate file)
@Serializable
data class UserResponse(
    val id: String = "",
    val name: String = "",
    val email: String = ""
)

// Good: CreateUserRequest.kt (separate file)
@Serializable
data class CreateUserRequest(
    val name: String = "",
    val email: String = ""
)

// Bad: Multiple serializable classes in one file (UserDtos.kt)
@Serializable
data class UserResponse(...)

@Serializable
data class CreateUserRequest(...)  // Will cause serialization to fail
```

#### Data Classes Best Practices
Always provide default values for all properties in data classes used for JSON serialization/deserialization. This prevents "No default constructor found" errors with JSON-B.

```kotlin
// Good: Default values provided
data class UserResponse(
    val id: String = "",
    val name: String = "",
    val email: String = ""
)

// Bad: No default values
data class UserResponse(
    val id: String,
    val name: String,
    val email: String
)
```

#### REST API Example

```kotlin
@Path("/users")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
class UserResource {

    @GET
    fun listUsers(): List<User> = User.listAll()

    @POST
    @Transactional
    fun createUser(user: User): Response {
        user.persist()
        return Response.status(201).entity(user).build()
    }
}

@Entity
class User : PanacheEntity() {
    lateinit var name: String
    lateinit var email: String

    companion object : PanacheCompanion<User> {
        fun findByEmail(email: String) = find("email", email).firstResult()
    }
}
```

#### GraphQL Integration

When combining REST and GraphQL endpoints:

**Dependencies**:
Add to `build.gradle.kts`:
```kotlin
implementation("io.quarkus:quarkus-smallrye-graphql")
implementation("io.quarkus:quarkus-rest-kotlin-serialization")
```

Also ensure Kotlin serialization plugin is enabled:
```kotlin
plugins {
    kotlin("plugin.serialization") version "2.2.10"
}
```

**Service Layer Models (Shared)**:
Use Kotlin data classes with immutable properties for internal business logic:

```kotlin
import kotlinx.serialization.Serializable

@Serializable
data class User(
    val id: String,
    val name: String,
    val email: String
)

@Serializable
data class CreateUserRequest(
    val name: String,
    val email: String
)
```

**GraphQL Input Types (Separate)**:
**CRITICAL**: GraphQL input types must use regular classes with mutable properties:

```kotlin
@Input
class CreateUserInput {
    var name: String = ""
    var email: String = ""
}
```

**Why separate GraphQL inputs are required:**
- SmallRye GraphQL requires mutable properties (`var`) for field detection
- Kotlin data classes with `val` properties are not properly introspected
- Complex annotations (`@field:Name`, `@SerialName`) interfere with GraphQL schema generation
- GraphQL validation fails with "must define one or more fields" if properties aren't detected

**Combined REST and GraphQL (Recommended for Simple Cases)**:
Use when operations are identical and input/output types are simple.

```kotlin
@Path("/users")
@GraphQLApi
class UserResource {

    @Inject
    lateinit var userService: UserService

    // Combined REST and GraphQL query
    @GET
    @Query("users")
    fun getUsers(): List<User> = userService.getAllUsers()

    // Separate endpoints due to different input requirements
    @POST
    fun createUserRest(request: CreateUserRequest): User {
        return userService.createUser(request.name, request.email)
    }

    @Mutation("createUser")
    fun createUserGraphQL(@Name("input") input: CreateUserInput): User {
        return userService.createUser(input.name, input.email)
    }
}
```

**Separate REST and GraphQL (Recommended for Complex Cases)**:
Use when:
- Different validation requirements
- Complex input transformations needed
- Different error handling
- Different security requirements

```kotlin
// REST Resource
@Path("/users")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
class UserRestResource {

    @Inject
    lateinit var userService: UserService

    @GET
    fun getUsers(): List<User> = userService.getAllUsers()

    @POST
    fun createUser(request: CreateUserRequest): User {
        return userService.createUser(request.name, request.email)
    }
}

// GraphQL Resource
@GraphQLApi
class UserGraphQLResource {

    @Inject
    lateinit var userService: UserService

    @Query("users")
    fun getUsers(): List<User> = userService.getAllUsers()

    @Mutation("createUser")
    fun createUser(@Name("input") input: CreateUserInput): User {
        return userService.createUser(input.name, input.email)
    }
}
```

**GraphQL Input Type Requirements**:

✅ **Correct GraphQL Input**:
```kotlin
@Input
class UserInput {
    var name: String = ""
    var email: String = ""
    var age: Int = 0
}
```

❌ **Incorrect GraphQL Input**:
```kotlin
// Will cause "must define one or more fields" error
@Input
data class UserInput(
    val name: String = "",
    val email: String = ""
)

// Will cause field detection issues
@Input
data class UserInput(
    @field:Name("userName") val name: String = "",
    @SerialName("userEmail") val email: String = ""
)
```

#### Persistence
- For Hibernate:
  - Enable SQL parameter logging only in dev profile.
  - Use Flyway or Liquibase for migrations (single module controlling schema).
  - Prefer constructor expressions / projections over returning entire entities for read APIs.
- For reactive drivers ensure suspension-friendly API (e.g., Mutiny -> coroutine adapters).
- Use Panache repositories for database operations.

#### Logging & Observability
- JSON logs in prod (quarkus.log.console.json=true).
- Include traceId, spanId (OpenTelemetry), correlationId MDC.
- Micrometer metrics endpoint /q/metrics; health endpoints /q/health/live|ready.
- Export traces via OTLP; set sampling via config not code.

#### Error Handling
- Map domain errors to HTTP in a central ExceptionMapper.
- No stack traces in client responses; keep in logs at DEBUG level if sensitive.
- Wrap external adapter exceptions; prevent leaking low-level details.
- Implement proper error handling with exception mappers.

#### Security
- Use OIDC extension for authN; enforce RBAC via @RolesAllowed in resources only (not services).
- Validate all untrusted input (query, path, headers).
- Enable TLS termination at ingress; enforce HTTPS redirection if Quarkus serves directly.
- Keep dependencies updated; enable quarkus-devtools to audit.

#### Performance
- Favor RESTEasy Reactive + native for minimal latency.
- Avoid blocking calls on IO thread (use @Blocking or move to worker pool).
- Batch database operations; stream large result sets (Reactive Panache or Scrollable results).
- Measure with continuous benchmark (JMH module optional) before optimizing.

#### Testing
- Unit: pure Kotlin + JUnit5 (no QuarkusTest).
- QuarkusTest for integration (inject real beans).
- Use `@QuarkusTest` for integration tests.
- Test database operations with test containers.
- Testcontainers for DB / Kafka; reuse containers between tests.
- Native tests: ./gradlew nativeTest ensures parity.
- Contract tests for REST endpoints (JSON schema or snapshot with strict matching).
- Coverage target >= 70% (exclude generated code).
- Write unit tests for all business logic.
- Create integration tests for REST endpoints.

#### Profiles
- dev: hot reload, verbose logging, mock external services.
- test: deterministic; no random ports unless injected.
- prod: optimized log level (INFO), JSON logs, metrics/tracing enabled.

#### Containerization
- Use quarkus.container-image.* properties (e.g., build=true, group, name, tag).
- Base image: Distroless / UBI minimal for native (quay.io/quarkus/quarkus-micro-image base OK); consider scratch if fully static.
- Expose minimal ports; run as non-root (set USER).
- Include SBOM (CycloneDX gradle plugin) artifact.
- Configure for containerization (Docker/Podman).

#### CI Pipeline (Stages)
1. Validate (format, detekt / ktlint, dependency check)
2. Compile (JVM)
3. Unit tests
4. Integration tests (QuarkusTest + Testcontainers)
5. Native build + native tests
6. Security scan (container + dependencies)
7. Publish artifacts (JAR + native binary + container image)
8. SBOM + provenance

#### Observability & Shutdown
- Graceful shutdown hooks close DB pools, flush logs.
- Set quarkus.shutdown.timeout to bounded value.
- Health readiness waits for migrations completion.
- Add health checks for external dependencies.

#### Coding Conventions
- No wildcard imports.
- Sealed classes for domain errors.
- Inline/value classes for IDs (e.g., @JvmInline value class CustomerId(val value: UUID)).
- Clock & UUID providers abstracted for test determinism.

#### Documentation
- README in root + module READMEs (purpose, public API).
- ADR explaining Quarkus + native decision and any deviations.
- Update instructions when adding new extensions that affect native configuration.
- Maintain OpenAPI specifications.
- Update README with setup instructions.
- Document configuration properties.
- Include Docker/native build instructions.

#### Prohibited / Discouraged
- Reflection-heavy mappers (ModelMapper)
- Runtime classpath scanning libraries (unless AOT config provided)
- Mixing blocking & reactive styles without clear boundary
- Direct use of static singletons for stateful services

#### Best Practices
- Use CDI for dependency injection.
- Keep REST resources thin, delegate to services.
- Configure native image hints for reflection.

#### Quick Checklist Before Merge
- Native build passes
- No unused dependencies
- Domain free of Quarkus imports
- ConfigMapping covers new settings and validated
- Tests deterministic & passing (JVM + native)
- Logging structured, no secrets
- ADR updated if architectural change

#### DevContainer Template
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
    "ghcr.io/meaningful-ooo/devcontainer-features/homebrew:2": {}
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
      "extensions": [
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

**Post Create Command**:
```bash
#!/bin/bash

# Install Kotlin via SDKMAN
sdk install kotlin

# Install Node
curl https://get.volta.sh | bash
export PATH="$HOME/.volta/bin:$PATH"
$HOME/.volta/bin/volta install node@lts
$HOME/.volta/bin/volta install yarn@latest
```

---

### Spring Boot 3 (Java/Kotlin)

#### Overview
Guidelines for building modern Spring Boot 3.x services with a focus on GraalVM native image readiness, performance, observability, and maintainability.

#### Baseline
- Spring Boot: 3.x (keep patch versions current)
- Java: 17 (LTS) or 21 (preferred when using virtual threads) – never below 17
- Jakarta EE 9+ namespace migration (`jakarta.*`) complete – no lingering `javax.*`
- Prefer Kotlin for new services; Java acceptable for existing or performance‑sensitive hotspots
- Use Gradle Kotlin DSL (`build.gradle.kts`)

#### Project Structure
- Follow layered or hexagonal architecture: `api`, `application/service`, `domain`, `infrastructure`
- Keep controller classes thin – delegate to services/use-cases
- Group configuration by feature not by stereotype when it improves cohesion
- Avoid cyclic dependencies between modules / packages

#### Dependency Management
- Use Spring Boot dependency management – avoid hardcoding versions managed by the BOM
- Keep dependency footprint minimal (native image size & build time)
- Avoid reflection-heavy libraries unless necessary; prefer Spring-native supported libraries
- For JSON: prefer Jackson (already optimized) or Kotlin serialization (if fully Kotlin). Avoid Gson.
- Use `spring-boot-starter-validation` (Jakarta) for input validation
- Prefer `spring-boot-starter-actuator` for metrics/health

#### Configuration & Profiles
- Externalize configuration with environment vars / config server; never hardcode secrets
- Use profile-specific config: `application.yml`, plus minimal `application-{profile}.yml`
- Keep property keys stable; document breaking changes
- Fail fast on missing mandatory configuration via `@ConfigurationProperties` + `@Validated`
- Use constructor binding for `@ConfigurationProperties` classes

#### AOT & Native Image Strategy
- Enable native support: include `org.graalvm.buildtools.native` Gradle plugin
- Use Spring AOT processing (`springAot`) and verify native build in CI
- Keep reflection usage explicit; add reachability metadata only when unavoidable
- Avoid dynamic proxies where possible (prefer interfaces with Spring-managed components). Consider using `native-hint` annotations when required.
- Log native build warnings; fail build if unsupported features appear (configure CI step)
- Limit runtime classpath scanning: use `@Import` or explicit `@Bean` definitions instead of broad component scanning where beneficial
- Avoid runtime generated bytecode frameworks not supported without configuration (e.g. CGLIB heavy custom use) beyond standard Spring usage

**Native Build Example (Gradle)**:
```kotlin
plugins {
	id("org.springframework.boot") version "3.3.0"
	id("io.spring.dependency-management") version "1.1.5"
	id("org.graalvm.buildtools.native") version "0.10.2"
	kotlin("jvm") version "1.9.24" // if using Kotlin
	kotlin("plugin.spring") version "1.9.24"
}

tasks.withType<JavaCompile> { options.release.set(17) }

graalvmNative {
	binaries {
		named("main") {
			imageName.set("service")
			buildArgs.add("--enable-http")
			buildArgs.add("--enable-https")
			resources.autodetect()
		}
	}
}
```

**Native Testing**:
- Add a native test execution stage (`bootBuildImage` or `nativeCompile` + run) in CI
- Run smoke tests against native binary (health, simple endpoint, metrics endpoint)
- Track native build time; fail if regression > threshold (e.g. +20%)

#### Performance & Memory
- Favor constructor injection (better for AOT and testability)
- Use `record` (Java) / data classes (Kotlin) for DTOs to reduce boilerplate
- Avoid reflection / `Class.forName` / `ObjectMapper` dynamic polymorphic defaults when not needed
- Disable unused auto-configurations via `spring.autoconfigure.exclude` to shrink native image
- Configure connection pools explicitly (Hikari) size & timeouts; avoid unbounded growth
- Use pagination / streaming for large result sets; prefer `Chunked` or `Flux` for reactive
- For high concurrency adopt virtual threads (Java 21) with `spring.threads.virtual.enabled=true` (when stable for workload)

#### Persistence
- Prefer Spring Data JDBC or JPA depending on complexity; for simple CRUD where lazy loading not needed choose JDBC for leaner model (native-friendly)
- Use Flyway or Liquibase for schema migrations; run on startup in controlled environments only
- Keep entity graphs tight; avoid bidirectional relationships unless required
- Avoid `EAGER` fetching—default to `LAZY` and fetch join explicitly
- Use projection interfaces or records over returning full entities to controllers

#### REST & APIs
- Use `@RestController` with explicit `@RequestMapping` at class level
- Validate inputs with `@Valid` + Jakarta validation annotations
- Consistent error contract using `@ControllerAdvice` & problem+json style (RFC 7807) if feasible
- Return appropriate HTTP status codes; avoid 200 for error semantics
- Support pagination metadata in list endpoints (page, size, total)

#### Security
- Adopt Spring Security 6 (Boot 3) – stateless JWT or opaque tokens via OAuth2 Resource Server
- Centralize security config; minimize custom filters
- Use method security with `@PreAuthorize` for domain-sensitive operations
- Store secrets in AWS Secrets Manager / Parameter Store; inject via environment or config import

#### Observability
- Include Actuator endpoints: health, info, metrics, prometheus
- Tag metrics with minimal cardinality (service, region, environment)
- Expose tracing with OpenTelemetry auto-instrumentation (OTLP exporter) – no custom tracer singletons
- Define liveness & readiness probes for container platforms
- Redact sensitive fields in logs; use structured logging (JSON) in production

#### Testing
- Unit tests: JUnit 5 + Mockito/Kotest (avoid loading Spring context unless needed)
- Slice tests (e.g. `@WebMvcTest`, `@DataJpaTest`) for focused integration
- Full integration tests: use `@SpringBootTest` with minimal profiles
- Use Testcontainers for external dependencies (Postgres, Kafka) – reuse containers across tests for speed
- For native: dedicated tests running the produced binary performing a minimal scenario suite

#### Messaging & Async
- Prefer Spring Cloud Stream / Spring for Apache Kafka with explicit serialization classes
- Use retry/backoff policies; avoid infinite retries
- Use DLQs for poison messages
- For scheduling prefer `@Scheduled` minimal usage; consider managed platforms (EventBridge, CloudWatch Events) for distributed scheduling

#### Cloud & AWS Integration
- Use AWS SDK v2; avoid blocking on reactive pipelines (choose one paradigm: imperative or reactive)
- Externalize AWS endpoint & region configuration
- Avoid embedding AWS credentials; rely on IAM roles

#### Configuration Properties Example
```kotlin
@ConfigurationProperties("app.feature")
@Validated
data class FeatureProperties(
	@field:NotBlank val mode: String,
	@field:Min(1) @field:Max(60) val timeoutSeconds: Int = 10
)
```

#### Security Config Example (No WebSecurityConfigurerAdapter)
```kotlin
@Bean
fun filterChain(http: HttpSecurity): SecurityFilterChain = http
	.csrf { it.disable() }
	.authorizeHttpRequests { auth ->
		auth.requestMatchers("/actuator/health", "/actuator/info").permitAll()
			.anyRequest().authenticated()
	}
	.oauth2ResourceServer { it.jwt() }
	.build()
```

#### Virtual Threads (Optional - Java 21)
- Evaluate with realistic load before enabling
- Enable via property (when supported): `spring.threads.virtual.enabled=true`
- Avoid blocking operations inside virtual threads that hold scarce resources

#### Deprecated / Avoid
- `javax.*` imports – must be migrated
- Field injection (`@Autowired` on fields)
- Wildcard component scanning of broad packages (`@SpringBootApplication(scanBasePackages = ["com.company"])` with huge root) – be intentional
- Unbounded thread pools / custom executors without metrics
- Returning JPA entities directly from controllers
- Business logic inside controllers or repositories

#### Migration Notes (2.x -> 3.x)
- Replace `javax` with `jakarta` imports (Servlet API, JPA, Validation)
- Update security configuration: `WebSecurityConfigurerAdapter` removed – use `SecurityFilterChain` bean
- Actuator endpoint IDs may have changed; verify monitoring dashboards
- Adjust CORS & SameSite cookie config to new APIs if using security
- Review deprecations removed in Boot 3 (legacy metrics, binding APIs)

#### CI/CD
- Include steps: compile, unit tests, integration tests (JVM), native build, native smoke tests
- Cache `~/.gradle` and native image build layers (if using buildpacks) for speed
- Fail pipeline on any TODO/FIXME (optional static check)

#### Quality Gates
- Static analysis: Spotless / ktlint / Checkstyle, Detekt (Kotlin) – enforce formatting pre-commit
- Security scanning: OWASP Dependency Check / Snyk in pipeline
- Minimum test coverage thresholds (line/branch) defined at repo root

#### Checklist Before Release
- [ ] All `javax.*` removed
- [ ] Native image build passes & smoke tests green
- [ ] Actuator endpoints secured & accessible
- [ ] Configuration properties validated
- [ ] DB migrations applied in staging
- [ ] Observability (metrics, traces, logs) verified
- [ ] Performance baseline captured (JVM vs native if both distributed)
