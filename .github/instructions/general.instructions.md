---
applyTo: '**'
---
# General Development Instructions (SDLC Aligned)

> This document reorganizes our engineering standards to follow the Software Development Life Cycle (SDLC) flow: Plan → Design → Implement → Test → Secure → Optimize → Release → Operate & Govern. All prior content is retained (reordered, lightly retitled for clarity). Use this as the authoritative playbook.

Always use context7 to get latest documentation for library or framework specific standards.

## Table of Contents
1. Overview & Goals
  1.1 Goals
  1.2 Core Principles
  1.3 Scope / Applies To
2. Planning & Requirements
  2.1 Feature Flags (Strategy & Governance)
  2.2 Branching & Versioning
  2.3 Project Structure & Modularity
  2.4 Dependency Hygiene
3. Architecture & Design
  3.1 Toolchains & Technology Baseline
  3.2 Devcontainers (Environment Reproducibility)
  3.3 Configuration Strategy
  3.4 Error Handling Model
  3.5 Code Style & Static Analysis Standards
4. Implementation Standards
  4.1 Mandatory Pre-Change Test Requirement (Red‑Green‑Refactor Gate)
  4.2 Development Workflow & PR Process
  4.3 Documentation Requirements
  4.4 Collaboration & Communication
  4.5 Code Quality Practices
5. Testing Strategy
  5.1 Quality Gates (CI Stages)
  5.2 Test Pyramid Strategy
  5.3 Test Types (Unit, Integration, E2E, Coverage)
6. Security & Compliance
  6.1 Security Baseline
  6.2 Secure Coding & Dependency Management
  6.3 Incident Response
7. Performance, Reliability & Observability
  7.1 Performance & Resource Guidelines
  7.2 Performance Engineering (Testing, Profiling, Optimization)
  7.3 Observability (Logs, Metrics, Tracing, Health)
8. Release & Deployment
  8.1 Release & Deployment Policies
  8.2 DevOps (CI/CD & Infrastructure as Code)
9. Operations & Governance
  9.1 Governance & Review Checklist
  9.2 Non-Negotiables
  9.3 Exceptions Process
10. Appendices & Rationale
  10.1 Feature Flags Deep Dive (Original Detailed Section)
  10.2 Rationale: Mandatory Pre-Change Test Requirement
  10.3 Glossary / Abbreviations

---

## 1. Overview & Goals

### 1.1 Goals
Consistency across polyglot repos; fast, reproducible, secure builds; high-signal CI; native / optimized delivery (GraalVM / binaries) where practical; clear separation of domain vs infrastructure.

### 1.2 Core Principles
1. Strong typing & static analysis first; runtime errors last.
2. Immutable + pure logic in domain modules; side‑effects at edges.
3. Small, composable modules; explicit boundaries (no cyclic deps).
4. Deterministic builds (locked versions, repeatable env via devcontainers).
5. Automate everything (format, lint, test, security scan) in CI.
6. Security & observability are baseline features, not add‑ons.
7. Prefer standard library over third‑party; justify each dependency.
8. Documentation lives with code; updated in same PR as change.
9. Performance measured, not guessed (add benchmarks before tuning).
10. Shift‑left on quality: reject code that cannot pass native / strict toolchains when required.

### 1.3 Scope / Applies To
Languages & ecosystems: Java / Kotlin / Groovy (Gradle build scripts only), Node.js (TypeScript), Python, Rust. Tooling also covers containers & infrastructure automation.

---

## 2. Planning & Requirements

### 2.1 Feature Flags (Strategy & Governance)
Use feature flags to decouple deploy from release and enable progressive delivery.

Principles:
- Flags are temporary; each must have an owner, rationale, and planned removal date.
- No flag logic in pure domain modules; evaluation occurs at application / adapter boundary and results passed inward as plain typed parameters.
- All flags must be typed, validated, and defaulted (fail fast if required flag missing).
- Avoid cascading flag conditionals deep in code; consolidate decisions early (compose a FeatureToggles value object).
- No dynamic reflection to discover flags; enumerate explicitly for native-image friendliness.

Flag Types:
- Boolean: on/off (most common).
- Multivariate / Enum: controlled strategies (e.g., algorithm version).
- Percentage / Segment: gradual rollout using consistent hashing of stable key (e.g., userId); hashing implemented once and unit tested.

AWS AppConfig Usage:
1. Configuration Profile per environment (e.g., app-prod, app-staging).
2. Hosted configuration (JSON or YAML) containing a single structured document:
  {
    "version": 5,
    "flags": {
     "newSearch": { "type": "boolean", "enabled": true, "owner": "team-search", "expires": "2025-12-31" },
     "distanceAlgorithm": { "type": "enum", "value": "haversine", "allowed": ["haversine","vincenty"] },
     "mapClustering": { "type": "percent", "rollout": { "percent": 25, "salt": "mapClustering:v1" } }
    }
  }
3. Use AppConfig deployment strategies (canary, linear) rather than bespoke rollout code.
4. Enable AppConfig validators (JSON schema) to reject invalid flag sets before deployment.

Retrieval & Caching:
- Fetch via AWS SDK (preferred: cached client) or AppConfig Agent/extension if running in container environment that supports it.
- Cache in-memory with TTL (e.g., 30s–2m) + ETag/If-None-Match where supported. Never fetch per request.
- On retrieval failure, continue with last known good snapshot; log at WARN with correlation ID.
- Persist a startup snapshot (optional) for cold starts (e.g., file cache) if availability critical.

Evaluation:
- Central FeatureFlagService exposes pure functions:
  - isEnabled(flag: BooleanFlag, subject?: Subject)
  - variant(flag: EnumFlag, subject?: Subject)
- Percent rollout:
  - Stable hash = SHA-256(salt + ":" + subjectKey) % 100 < percent.
  - Document which subject key (userId, orgId) is applied; keep consistent to prevent flicker.
- Multivariate: store selected variant explicitly; avoid branching on multiple flags for single concern (introduce composed “mode” enum instead).

Testing:
- Provide a TestFlagProvider allowing explicit overrides (no global mutation; pass via dependency injection).
- Unit tests cover:
  - Hash boundary conditions (0%, 100%).
  - Expired flags produce warning (log) and default to safe value.
  - Schema validation rejects unknown types.
- Integration test ensures AppConfig retrieval + parsing + fallback path.

Governance:
- Each flag tracked in a FLAG_REGISTRY.md (id, description, owner, created, expires, removal PR link).
- CI check optionally fails if expires date < now.
- Removal process: delete code paths, then remove flag from AppConfig, then update registry.

Security & Audit:
- Limit IAM permissions: read-only access (appconfig:GetConfiguration / List*) for runtime role.
- Log flag version + hash seed at startup for reproducibility.
- Avoid embedding secrets in flag payloads (AppConfig not a secret store).

Performance:
- Single evaluation object created per request (if needed) to avoid repeated hashing.
- Do not allocate new hash objects per flag; reuse hashing function or implement lightweight FNV / Murmur if profiling shows cost (measure first).

Failure Modes:
- If initial fetch fails at startup and no cached snapshot: either (a) abort startup (critical flags) or (b) start with safe defaults (non-critical) — document per flag in registry.
- If JSON version regresses (version field decreases) log ERROR and keep current snapshot.

Observability:
- Expose metrics: flags_evaluated_total (counter), flag_rollout_percent (gauge per flag), flag_snapshot_age_seconds.
- Emit structured log entry on each new snapshot: { event: "featureFlagsUpdated", version, changed: [ids] }.
Applies To (repeat for clarity in feature flag context): Java, Kotlin, Groovy (Gradle build scripts only), Node.js (TypeScript), Python, Rust.

### 2.2 Branching & Versioning
- main: always releasable.
- feature/<scope>, fix/<issue>, chore/<task> (plus perf/, docs/, HOTFIX/ when appropriate).
- Conventional Commits -> automated CHANGELOG + SemVer.
- Release tags: vMAJOR.MINOR.PATCH; automation publishes artifacts & SBOM.
- Semantic Versioning rules: MAJOR (breaking), MINOR (backward-compatible feature), PATCH (bug/security fix).

### 2.3 Project Structure & Modularity
Establish clear module / service boundaries to preserve domain purity, enable incremental builds, and simplify ownership.

Mono Repo:
- Structure by domain + technology layer (e.g., services/, libs/, tooling/).
- Shared standards: root lint, formatting, security scan configs.
- Central dependency/version catalogs (Gradle version catalog, npm workspaces, pnpm/turborepo, Cargo workspaces).
- Enforce isolation & no circular dependencies (automated graph validation).
- Domain modules: zero framework imports.
- Aggregate test & coverage reporting; diff-aware CI; idempotent global scripts in ./tools.
- SBOM + license scan aggregated at root.

Separate Repositories:
- Use for distinct compliance, access, or release cadence boundaries.
- Common template (devcontainer + CI) to bootstrap.
- Shared contracts versioned (e.g. Protobuf / OpenAPI) in dedicated repo/package.

Branching Strategy (Extended):
- Long-lived branches discouraged; rebase frequently; early draft PRs.
- HOTFIX/<ticket> only for production breakage (w/ postmortem).

Versioning (Extended):
- Pre-release tags (-rc.N) before major upgrades.

### 2.4 Dependency Hygiene
- Central version catalog / lockfiles mandatory; ban wildcard versions.
- Periodic audit for unused dependencies; remove promptly.
- Justify heavy / reflective libraries (esp. native image constraints).
- Dependency update automation (Dependabot / Renovate).
- Unused dependency detector weekly; auto PR removal.

---

## 3. Architecture & Design

### 3.1 Toolchains & Technology Baseline
Toolchains (Pin Versions in Each Repo):
- JVM: GraalVM LTS (e.g., Java 21) via Gradle toolchains.
- Node: Current LTS, ESM only, TypeScript strict mode.
- Python: Latest stable 3.x (pyproject + lock), type check with mypy/pyright.
- Rust: Stable toolchain pinned (rust-toolchain.toml); clippy + rustfmt mandatory.
- Containers: Devcontainer + multi-stage Docker builds; never build on host directly.
- Native (where applicable): GraalVM native-image / Rust cargo build --release.

### 3.2 Devcontainers (Environment Reproducibility)
Devcontainers:
- Base: mcr.microsoft.com/devcontainers/base:ubuntu
- Features: Docker, Node.js, language toolchains (Java/GraalVM, Rust, Python).
- Mount host ~/.ssh and ~/.aws (read-only where possible).
- Post-create scripts validate tool versions.
- All development inside devcontainer (no host-only divergence).

### 3.3 Configuration Strategy
- Central typed config object per runtime (validated at startup, fail fast).
- Explicit env var documentation (name, type, default, required).
- No mutable global state after initialization.
- Secrets from env or vault (never committed defaults containing secrets).

### 3.4 Error Handling Model
- Domain errors typed (sealed classes / enums / custom types).
- Avoid generic catch & swallow; log (DEBUG) or propagate.
- Standardized error envelope at boundaries (HTTP, messaging).
- Prevent infrastructure stack traces leaking externally.

### 3.5 Code Style & Static Analysis Standards
- Always include `.editorconfig` file in project root for consistent formatting across editors and IDEs.
- No wildcard imports (JVM); consistent formatting (Spotless / Prettier / rustfmt / Black).
- Treat all compiler / linter warnings as errors.
- Prefer immutability; limit module & class size (avoid "god" modules).
- Strong static analysis & security scanning part of baseline.

---

## 4. Implementation Standards

### 4.1 Mandatory Pre-Change Test Requirement (Red‑Green‑Refactor Gate)
...existing code...
## Mandatory Pre-Change Test Requirement
...existing code...
### 4.2 Development Workflow & PR Process
Development Workflow (Local Dev):
- Devcontainer only; pre-flight script verifies toolchain & security baseline.
- Fast feedback loops (test watch, framework dev modes).
- Testcontainers / docker-compose for infra parity.
- Seed minimal deterministic data.
- Secrets via .env.local or parameter store fetch script.
- Makefile / task runner for standard commands (build, test, lint, native build).

Code Reviews:
- 1+ reviewer (2 for security-sensitive / migrations / crypto). Block merge on uncovered lines, missing docs, security/perf regressions.
- Encourage small PRs (<400 LOC diff).

Pull Requests:
- Template includes Purpose, Approach, Testing evidence, Risk, Rollback plan.
- CI & coverage green before human review (except docs-only).

Merging & Releases:
- Squash by default; HOTFIX fast-forward allowed w/ sign-off.
- Auto release via conventional commit parsing; artifact publish + SBOM.

### 4.3 Documentation Requirements
Documentation Requirements (recap):
- Root README (purpose, layout, build/test/run, release summary).
- Module README (scope, public API, boundaries).
- ADRs for significant decisions / deviations.
- CHANGELOG auto-generated; inline comments only for non-obvious logic.
- Put Any Markdown summaries created by LLM agents in the `/docs-agent-state` folder

### 4.4 Collaboration & Communication
Collaboration:
- Issues/PRs primary async medium.
- Architecture discussions: ADR + design doc.
- Incident bridges & standups summarized back to issues.
- Decision log maintained (CHANGELOG + ADR index).
- Knowledge sharing via scheduled tech reviews.

### 4.5 Code Quality Practices
Reinforces: linting, formatting, static analysis, metrics tracking (complexity, dependency graph, build time), and refactor thresholds.

---

## 5. Testing Strategy

### 5.1 Quality Gates (CI Stages)
Quality Gates (CI Mandatory Stages):
1. Format / Lint
2. Compile / Type Check
3. Unit Tests (≥70% meaningful coverage; exclude generated code)
4. Integration Tests
5. Security (dependencies + SAST + secret scan)
6. Native / Prod Artifact build
7. Smoke / Health startup test
8. SBOM + provenance + artifact signing
9. Performance smoke (optional gate)

### 5.2 Test Pyramid Strategy
Testing Strategy (Pyramid): Unit > Integration > Contract > E2E. Deterministic (fixed clocks, seeded randomness, no sleeps). Snapshot tests minimal & stable.

### 5.3 Test Types (Detail)
Unit Tests: pure logic, fast (<200ms), cover edge + typical paths.
Integration Tests: real adapters with Testcontainers, migrations applied once, assert persistence & transactional semantics.
End-to-End: minimal critical user journey smoke flows, idempotent, parallelizable.
Coverage: ≥70% meaningful (lines + branches). Diff coverage gate enforces non-regression. Exclude generated code, DTO mappers, config DTOs.

---

## 6. Security & Compliance

### 6.1 Security Baseline
...existing code...
Security Baseline:
...existing code...

### 6.2 Secure Coding & Dependency Management
Consolidates: Secure coding practices, vulnerability scanning, dependency management (lock files, unused dep removal, parameterized queries only, input validation, secrets handling, TLS enforcement, principle of least privilege).

### 6.3 Incident Response
Incident Response:
- Runbook per service (/docs/runbooks/).
- Create ticket & HOTFIX tag for incidents; postmortem within 48h (blameless).
- Maintain error budget & SLO dashboard.

---

## 7. Performance, Reliability & Observability

### 7.1 Performance & Resource Guidelines
Performance & Resource: measure first (profilers / benchmarks). Prevent N+1 via batching, streaming/pagination for large sets, non-blocking IO, track startup time & RSS.

### 7.2 Performance Engineering (Testing, Profiling, Optimization)
Performance Testing: baseline microbench (JMH / k6 / artillery). Regression alert on >10% latency/throughput delta.
Profiling: JVM (async-profiler/JFR), Native (perf/flame graphs), Node (clinic). Optimize with hypothesis → measure cycle; document ADR for architectural shifts.

### 7.3 Observability (Logs, Metrics, Tracing, Health)
Observability: structured JSON logs (correlation/trace IDs, no PII), metrics (Prometheus/Micrometer/OpenTelemetry), distributed tracing (OpenTelemetry for HTTP/DB/messaging), health endpoints (liveness/readiness), minimal actionable logging.

---

## 8. Release & Deployment

### 8.1 Release & Deployment Policies
Release & Deployment: immutable artifacts, multi-platform (native + JVM), automated rollback strategy, publish SBOM + signature + provenance (SLSA progression).

### 8.2 DevOps (CI/CD & Infrastructure as Code)
DevOps:
- CI: validate → compile → unit → integration → security → build → native tests → SBOM/provenance → performance smoke.
- CD: progressive promotion dev → staging → prod; canary + metrics guardrail; feature flags for exposure control.
- Infrastructure as Code: Terraform modules versioned; plans validated in PR; network/IAM codified.
- Monitoring & Logging: RED + USE metrics; standard dashboards; actionable alerts only.

---

## 9. Operations & Governance

### 9.1 Governance & Review Checklist
Governance & Review Checklist (Abbrev): boundary purity, deterministic tests, changed lines executed, security controls, structured logging, native image viability, minimal dependencies, docs updated, performance rationale.

### 9.2 Non-Negotiables
Non-Negotiables: no failing/skipped tests without issue; no TODO without ticket; no secrets committed; no unreviewed generated code.

### 9.3 Exceptions Process
Exceptions: require ADR with justification, impact, mitigation/exit strategy (e.g., skipping native build, adding heavy framework).

---

## 10. Appendices & Rationale

### 10.1 Feature Flags Deep Dive (Original Detailed Section)
Full detailed content retained above in Section 2.1 (this anchor maintained for legacy references).

### 10.2 Rationale: Mandatory Pre-Change Test Requirement
Rationale: Embedding the pre-change test gate ensures each change is test-driven or anchored, preventing dark code paths and enabling safe refactors & rapid regression detection. (Original rationale text preserved below.)
...existing code...
Rationale:
Embedding this gate ensures every change is test-driven or at minimum test-anchored, preventing "dark" code paths and enabling safe refactors & rapid regression detection.

### 10.3 Glossary / Abbreviations
- ADR: Architecture Decision Record
- CI: Continuous Integration
- CD: Continuous Deployment / Delivery
- SBOM: Software Bill of Materials
- SLO: Service Level Objective
- SLA: Service Level Agreement
- RPO: Recovery Point Objective
- RTO: Recovery Time Objective
- N+1: Pattern of executing one query per result row (inefficient)
- IaC: Infrastructure as Code
- RSC: React Server Component

---

## (Legacy Sections Retained For Reference / Search)
The following legacy headings are preserved verbatim (content already integrated above) to avoid broken inbound references. Do not add new content here; plan removal after external references updated.

### Legacy: Release & Deployment (Original)
...existing code...
Release & Deployment:
...existing code...

### Legacy: Observability (Original)
...existing code...
Observability:
...existing code...

### Legacy: Performance & Resource (Original)
...existing code...
Performance & Resource:
...existing code...

### Legacy: Documentation Requirements (Original)
...existing code...
Documentation Requirements:
...existing code...

### Legacy: Code Style & Static Analysis (Original)
...existing code...
Code Style & Static Analysis:
...existing code...

### Legacy: Error Handling (Original)
...existing code...
Error Handling:
...existing code...

### Legacy: Configuration (Original)
...existing code...
Configuration:
...existing code...

### Legacy: Development Workflow (Original)
...existing code...
Development Workflow:
...existing code...

### Legacy: Code Quality (Original)
...existing code...
Code Quality:
...existing code...

### Legacy: Security Baseline (Original)
...existing code...
Security Baseline:
...existing code...

### Legacy: Security (Expanded) (Original)
...existing code...
Security:
...existing code...

### Legacy: Performance (Expanded) (Original)
...existing code...
Performance:
...existing code...

### Legacy: DevOps (Original)
...existing code...
DevOps:
...existing code...

### Legacy: Collaboration (Original)
...existing code...
Collaboration:
...existing code...


Testing Strategy:
- Pyramid: Unit > Integration > Contract > E2E.
- No network / filesystem in unit tests.
- Integration uses ephemeral or containerized dependencies.
- Contract tests at adapter boundaries (HTTP schemas, messaging payloads).
- Snapshot tests minimal & stable only.
- Deterministic: fixed clocks, seeded randomness, no time.sleep hacks.

Security Baseline:
- Dependency update automation (Dependabot / Renovate).
- No plaintext secrets in code; env / vault only.
- Input validation at boundaries (HTTP, CLI, messaging).
- Parameterized queries only (DB).
- Static analysis (SAST) + secret scanning each PR.
- Supply SBOM (CycloneDX) + vulnerability diff on release.
- Enforce TLS & modern cipher defaults; drop deprecated protocols.
- Principle of least privilege for service accounts / DB roles.

Observability:
- Structured JSON logs (no PII/secrets) + correlation / trace IDs.
- Metrics: Prometheus/Micrometer/OpenTelemetry where language-appropriate.
- Distributed tracing (OpenTelemetry) for HTTP, DB, messaging.
- Health endpoints: liveness (process), readiness (deps initialized).
- Log only actionable info; DEBUG for internals; avoid log spam loops.

Performance & Resource:
- Measure (profilers / benchmarks) before optimizing.
- Avoid N+1 (DB, HTTP) via batching / joins.
- Use streaming / pagination for large result sets.
- Non-blocking IO where ecosystem supports (coroutines, async/await).
- Track startup time & RSS for native vs JVM; document tradeoffs.

Devcontainers:
- Base: mcr.microsoft.com/devcontainers/base:ubuntu
- Features: Docker, Node.js, language-specific toolchains (Java/GraalVM, Rust, Python).
- Mount host ~/.ssh and ~/.aws (read-only where possible).
- Post-create scripts install additional SDKs & validate tool versions.
- All contributors develop inside devcontainer—no “works on my machine”.

Dependency Hygiene:
- Central version catalog (Gradle), package manager lockfiles (npm/package-lock, Cargo.lock, poetry.lock).
- Ban wildcard / dynamic versions.
- Periodic audit for unused deps; remove promptly.
- Justify heavy / reflective libs (especially for native image compatibility).

Documentation Requirements:
- Root README: purpose, module layout, build/test/run commands, release process summary.
- Module README: scope, public API / boundaries.
- ADRs for significant architectural decisions & deviations.
- CHANGELOG auto-generated; manual notes only for context when needed.
- Inline comments for non-obvious algorithms / invariants (not restating code).

Code Style & Static Analysis:
- Enforce no wildcard imports (JVM).
- Consistent formatting enforced (Spotless / Prettier / rustfmt / Black).
- Treat all compiler / linter warnings as errors.
- Prefer immutable data constructs; explicit mutability where required.
- Avoid large “god” modules—enforce size / complexity thresholds (CI check optional).

Error Handling:
- Domain errors: typed (sealed classes / enums / custom error types).
- No generic catch & swallow; at least log (DEBUG) or map upward.
- Standard error envelope at boundaries (HTTP, messaging).
- Avoid leaking infrastructure stack traces externally.

Configuration:
- Central typed config object per runtime (validated at startup).
- Fail fast on invalid / missing required values.
- No mutable global state after initialization.
- Explicit environment variable documentation (name, type, default, required).

Release & Deployment:
- Immutable artifacts (digest referenced).
- Multi-platform builds (native + JVM fallback) where mandated.
- Automated rollback strategy documented.
- Publish SBOM + signature + provenance (SLSA level progression goal).

Governance & Review Checklist (Abbrev):
- Boundary purity (domain free of framework imports)?
- Tests meaningful & deterministic?
- Changed lines in this PR executed by at least one automated test (verify via coverage or targeted run)?
- Security controls present (validation, parameterized queries)?
- Logging structured, no secrets?
- Native image viability (reflection minimized) if required?
- Dependencies minimal & justified?
- Docs (README/ADR/CHANGELOG) updated?
- Performance-sensitive code measured or annotated with rationale?

Non-Negotiables:
- No committing failing or skipped (disabled) tests w/out issue reference.
- No TODO without linked ticket.
- No direct secrets / credentials in repo.
- No unreviewed generated code (document generation source).

Exceptions:
- Any deviation (e.g., skipping native build, adding heavy framework) requires ADR with:
  - Justification
  - Impact (perf, security, ops)
  - Mitigation / exit strategy

## Mandatory Pre-Change Test Requirement
Before modifying any non-comment, non-doc line of production (non-test) code you MUST ensure there is at least one automated test that:
1. Fails (red) without the intended change (for new behavior or bug fix), OR
2. Passes and characterizes existing behavior for pure refactors (no semantic change intended).

Process (Red / Green / Refactor enforced):
1. Identify target lines (file + function/method). Keep diff minimal.
2. Search for existing tests referencing the symbol(s). If found, confirm they execute the exact lines (use coverage or temporary breakpoint/log/"fail fast" assertion locally—revert any transient instrumentation before commit).
3. If NO direct test exists, write the smallest focused unit/contract test that would catch an incorrect implementation of the intended change. Name it to reflect intent (e.g., DistanceServiceTest.shouldComputeHaversineDistanceAccurately) and, if helpful, add a brief comment listing the primary lines covered.
4. For bug fixes: write the test to assert the correct (desired) behavior first; run to see it fail (prove necessity).
5. For refactors: create characterization tests capturing current externally observable behavior (inputs/outputs, side-effects). Do NOT change implementation until these pass.
6. Only then modify production code to make tests pass. Keep commits logically ordered (optional: separate commit for failing test, then fix; same PR is required either way).
7. If behavior change affects public API / contract:
  - Add/adjust contract or integration tests (HTTP schemas, messaging payloads, DB interactions) plus at least one negative test.
8. Run full test suite (or impacted subset + full CI) before requesting review; ensure coverage for new/changed lines ≥ existing project threshold (never lowers global threshold).
9. Reviewers must block if any changed executable line lacks test execution evidence.
10. Emergency hotfix exception (critical prod outage) may merge with follow-up test commit ONLY if explicitly tagged (HOTFIX) and ticketed; follow-up test must land within 24h.

Edge Case Allowances (document rationale in PR description if skipping creating new tests):
- Comment / formatting only changes.
- Generated code (regenerate from source-of-truth + ensure generator itself is tested).
- Build / infrastructure scripts where a smoke test already validates behavior (ensure script lines still executed in CI task). If novel logic added, add/extend tests.

Reviewer Checklist Additions:
- [ ] Each changed function/method has (a) an existing or new test referencing it and (b) evidence of execution (coverage diff or targeted run output).
- [ ] For bug fixes: initial failing test was demonstrated (commit history or PR description screenshot/log).
- [ ] No reduction in coverage threshold; net coverage for touched modules non-decreasing.
- [ ] Characterization tests present before refactor transformations (where applicable).

Automation Suggestions:
- CI job: diff-based coverage check failing build if any changed lines (excluding comments/whitespace) are uncovered.
- Pre-commit hook: parse git diff to warn on untested modifications (heuristic via running focused test/coverage tool).

Rationale:
Embedding this gate ensures every change is test-driven or at minimum test-anchored, preventing "dark" code paths and enabling safe refactors & rapid regression detection.


## Project Structure
Establish clear module / service boundaries to preserve domain purity, enable incremental builds, and simplify ownership.

### Mono Repo
- Structure by domain + technology layer (e.g., services/, libs/, tooling/).
- Shared standards: root lint, formatting, security scan configs.
- Central dependency/version catalogs (e.g., Gradle version catalog, npm workspaces, pnpm or turborepo, Cargo workspaces).
- Enforce isolation:
  - No circular dependencies (automated graph validation).
  - Domain modules have zero framework imports.
- Tooling:
  - Aggregate test + coverage reporting.
  - Diff-aware CI (only build/test affected modules).
  - Global scripts: ./tools/<task>.sh (idempotent).
- Cross-language:
  - Each language sub-tree owns its lock file.
  - Uniform CODEOWNERS per directory.
- SBOM + license scan aggregated at root.

### Separate Repositories
- Use when release cadence, compliance boundaries, or access control requires isolation.
- Common template repo for bootstrapping (devcontainer + CI).
- Keep shared contracts (e.g., Protobuf / OpenAPI) versioned in a dedicated contracts repo or published package.
- Automation:
  - Renovate / Dependabot for shared dependency alignment.
  - Release notes standardized (GitHub Release + CHANGELOG).

### Branching Strategy
- main: always green & releasable.
- feature/<scope>, fix/<issue>, chore/<task>, perf/<area>, docs/<topic>.
- Long‑lived branches discouraged; rebase frequently.
- Use draft PR early; CI must run on every push.
- HOTFIX/<ticket> branch only for production breakage (must include postmortem).

### Versioning
- Semantic Versioning (SemVer) for public artifacts.
- Increment logic:
  - MAJOR: breaking API/schema or contract change.
  - MINOR: backward-compatible features.
  - PATCH: bug/security fixes only.
- Tag format: vMAJOR.MINOR.PATCH (annotated).
- Auto-generated CHANGELOG from Conventional Commits; manual notes only for context.
- Libraries: publish pre-release tags (e.g., -rc.1) before MAJOR upgrades.

## Development Workflow
### Local Development
- Always use devcontainer; host-only flows prohibited.
- Pre-flight script verifies tool versions, lock files freshness, and security baseline.
- Fast feedback:
  - Watch mode for tests (unit).
  - Quarkus dev mode / Next.js dev server / nodemon equivalent.
- Environment parity:
  - Use docker-compose or Testcontainers for DB, Kafka, etc.
  - Seed minimal deterministic data (idempotent script).
- Secrets via .env.local (gitignored) or AWS Parameter Store fetch script (never in repo).
- Makefile or task runner aliasing standard commands (build, test, lint, native).

### Code Reviews
- Mandatory: 1+ reviewer (2 for security-sensitive code, DB migrations, cryptography).
- Reviewer checklist references governance points (included earlier).
- Block merge if:
  - Uncovered changed lines.
  - Unresolved TODO w/out issue.
  - Missing docs for new public API.
  - Security / perf regressions unaddressed.
- Encourage small PRs (<400 LOC diff).

### Pull Requests
- Template includes: Purpose, Approach, Testing (screenshots/log of failing test for bug fix), Risk, Rollback plan.
- CI status + coverage diff must be green before human review (except docs-only).
- Link issues (Closes #id).
- Label: type + domain + risk (e.g., feat, db, high-risk).

### Merging
- Squash by default (clean history); keep granular commit messages informative.
- HOTFIX branches can fast-forward with explicit sign-off.
- Post-merge: automated release (if conventional commit triggers version bump) or artifact publish.

### Release Process
1. Automated version bump via conventional commit parsing.
2. Build (JVM JAR + native image / Node dist / container).
3. Run full test suite + native smoke.
4. Generate SBOM + signatures.
5. Publish artifacts (registry, container registry).
6. Create GitHub Release with notes (CHANGELOG excerpt).
7. Deploy via GitHub Actions workflow (env promotion dev -> staging -> prod).
8. Post-deploy smoke + health + metric sanity (error rate, latency, startup).
9. Automated rollback trigger if SLO breach threshold.

## Testing
### Unit Tests
- Pure logic only; no network, filesystem.
- High ratio vs integration; fast (<200ms average).
- Deterministic: fixed clock + seeded randomness.
- Cover edge + typical paths (min, max, null, empty, large).

### Integration Tests
- Real adapters (DB, HTTP, messaging) using Testcontainers.
- Schema migrations applied once per suite; reuse containers.
- Assert persistence + query correctness + transaction semantics.

### End-to-End Tests
- Minimal smoke flows: critical user journeys.
- Idempotent & parallelizable.
- Fail fast on environment misconfig (feature flags, migrations, config drift).

### Test Coverage
- Target: ≥70% meaningful (lines + branches where practical).
- Enforce non-decreasing coverage on touched modules (diff coverage gate).
- Exclusions: generated code, DTO auto-mappers, config POJOs/records.

## Documentation
### Code Comments
- Only for non-obvious invariants, algorithms, trade-offs.
- KDoc / TSDoc required for public APIs.

### API Documentation
- Source-of-truth: OpenAPI / Protobuf / GraphQL schema versioned.
- Generated docs published (portal / README link).
- Breaking change checklist required (consumer impact, migration path).

### User Documentation
- README: quick start, architecture diagram (updated).
- ADRs: each major decision; link from README summary table.

### Changelog
- Auto-generated per release.
- Include security advisories (CVE references) and migration notes.

## Code Quality
### Linting
- Enforced in CI pre-test stage; zero warnings policy.
- Tools: ktlint + detekt, ESLint + TypeScript, markdown lint (docs).

### Formatting
- Spotless / Prettier / rustfmt / Black mandatory; run pre-commit (husky).

### Static Analysis
- Security (SAST) + dependency scan each PR.
- Detekt & ESLint strict configs; fail on new issues.

### Code Metrics
- Track: complexity (cyclomatic threshold), module dependency graph, build time.
- Alert if complexity > threshold; refactor before merge.

## Security
### Secure Coding Practices
- Input validation at boundaries; reject early with typed errors.
- Parameterized queries only; forbid string concatenated SQL in CI check.
- Sensitive fields redacted in logs (hash or placeholder).
- Principle of least privilege IAM & DB roles.

### Vulnerability Scanning
- Dependency scanning (daily + PR).
- Container image scan (Grype/Trivy) in pipeline.
- High severity blocks merge unless documented exception.

### Dependency Management
- Lock files mandatory; no dynamic versions.
- Unused dependency detector runs weekly; auto PR removal.

### Incident Response
- Runbook per service: location in /docs/runbooks/.
- On incident: create ticket, tag commits HOTFIX, postmortem within 48h (blameless).
- Maintain error budget & SLO dashboard.

## Performance
### Performance Testing
- Baseline microbench (JMH / k6 / artillery) for critical endpoints.
- Store historical metrics; regression alert >10% latency/throughput delta.

### Profiling
- JVM: async-profiler / JFR (JIT mode) staging only.
- Native: perf / flame graph generation script.
- Node: clinic flame, --inspect snapshots.

### Optimization
- Optimize only with empirical evidence.
- Checklist before change: reproduce, measure, hypothesize, implement, re-measure, document ADR if architectural shift.

## DevOps
### Continuous Integration
Stages (gated, fail-fast):
1. Validate (format/lint/static analysis).
2. Compile / type-check (warnings treated as errors).
3. Unit tests (parallel).
4. Integration tests (Testcontainers).
5. Security scans (SAST + dependencies + secrets).
6. Build artifacts (JAR, native, Node dist, containers).
7. Native tests / smoke.
8. SBOM + provenance + signing.
9. Performance smoke (optional threshold gate).
Artifacts cached between stages; diff-based test selection where safe.

### Continuous Deployment
- Progressive: dev -> staging -> prod with automated verification gates.
- Feature flags control gradual exposure (not code branches).
- Canary: small % traffic + metrics guardrail.
- Rollback: single command workflow; previous artifact retained.

### Infrastructure as Code
- Terraform modules versioned; no inline imperative scripting.
- Validate plan in PR (terraform plan comment).
- Security rules (network, IAM) codified + reviewed.

### Monitoring and Logging
- Metrics: RED + USE (request rate, errors, duration; resource saturation).
- Tracing: 100% head sampling in staging; production sampling adjustable via config.
- Dashboards: standard layout (latency p95/p99, error %, saturation, GC/native memory).
- Alerts: page only on actionable SLO breaches; no alert spam.

## Collaboration
### Communication Tools
- Issues / PRs: primary async medium.
- Architecture discussions: ADR + linked design doc.
- Standups / incident bridges: summarized back into issues.
- Decision log maintained (CHANGELOG + ADR index).
- Knowledge sharing: scheduled tech review sessions; recordings archived.


