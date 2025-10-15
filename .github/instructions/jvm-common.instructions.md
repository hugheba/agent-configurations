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
