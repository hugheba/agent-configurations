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
  5.4 Testing Requirements & Best Practices
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
  8.3 Git Platform Management (GitHub / GitLab)
  8.4 Infrastructure as Code (Terraform)
  8.5 Database Management (PostgreSQL)
  8.6 Authentication & Identity
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

**Note**: A monorepo is NOT required. Use separate repositories for most projects unless you have specific needs for shared code coordination, atomic cross-project changes, or unified CI/CD. Choose the approach that best fits your team's workflow and project interdependencies.

#### Mono Repo (When Needed)
Use monorepo when you have:
- Multiple tightly coupled projects requiring atomic changes
- Significant shared code that changes frequently
- Need for consistent tooling and standards enforcement
- Team benefits from simplified dependency management

**Structure**:
- Structure by domain + technology layer (e.g., services/, libs/, tooling/).
- Use consistent directory structure:
  - `/apps` or `/services` - deployable applications
  - `/shared` or `/common` or `/libs` - shared libraries
  - `/infrastructure` - infrastructure as code (Terraform, etc.)
  - `/tools` - build scripts and utilities
- Shared standards: root lint, formatting, security scan configs.
- Central dependency/version catalogs (Gradle version catalog, npm workspaces, pnpm/turborepo, Cargo workspaces).
- Enforce isolation & no circular dependencies (automated graph validation).
- Domain modules: zero framework imports.
- Aggregate test & coverage reporting; diff-aware CI; idempotent global scripts in ./tools.
- SBOM + license scan aggregated at root.
- Maintain root-level README with project overview and inter-service dependencies.
- Keep separate README files for each project/service.

**Dependency Management**:
- Use workspace features of package managers (npm workspaces, yarn workspaces, pnpm, poetry workspaces).
- Define shared dependencies at root level where appropriate.
- Pin dependency versions consistently across projects.
- Use lockfiles and commit them to version control.
- Implement dependency vulnerability scanning at root level.

**Build and CI/CD**:
- Implement selective builds based on changed files (path-based triggers).
- Use build caching to optimize CI/CD performance.
- Create separate deployment pipelines for each service/app.
- Implement parallel builds where possible.
- Run tests only for changed code and dependencies.
- Use test result caching to speed up CI/CD.

**Code Organization**:
- Enforce consistent coding standards across all projects.
- Use shared linting and formatting configurations.
- Implement pre-commit hooks for code quality.
- Use consistent naming conventions for projects and modules.
- Document inter-service dependencies and communication patterns.

**Version Control**:
- Use conventional commit messages.
- Implement semantic versioning for releases.
- Tag releases at monorepo level with project-specific tags (e.g., `app-name/v1.2.3`).
- Use branch protection rules.
- Implement automated changelog generation per project.

#### Separate Repositories (Default Approach)
- Use for distinct compliance, access, or release cadence boundaries.
- Common template (devcontainer + CI) to bootstrap.
- Shared contracts versioned (e.g. Protobuf / OpenAPI) in dedicated repo/package.
- Simpler dependency management and CI/CD per project.
- Clear ownership and access control boundaries.

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

#### Environment Files (.env) Best Practices
**File Structure & Naming:**
- `.env` - Never commit (gitignored); local development secrets/overrides
- `.env.example` or `.env.template` - Committed; documents all required variables with placeholder values
- `.env.local` - Never commit (gitignored); developer-specific overrides
- `.env.test` - Committed; test environment defaults (no secrets)
- `.env.production` - Never exists in repo; managed via deployment platform/vault

**Mandatory Security Controls:**
1. **Pre-commit Hook (REQUIRED)**: Install pre-commit hook to scan .env files for secrets before any commit
   - Use tools: `gitleaks`, `detect-secrets`, or `git-secrets`
   - Block commits containing high-entropy strings, API keys, tokens, passwords
   - Scan both staged files and commit messages
   - Example hook configuration (`.pre-commit-config.yaml`):
     ```yaml
     repos:
       - repo: https://github.com/gitleaks/gitleaks
         rev: v8.18.0
         hooks:
           - id: gitleaks
       - repo: https://github.com/Yelp/detect-secrets
         rev: v1.4.0
         hooks:
           - id: detect-secrets
             args: ['--baseline', '.secrets.baseline']
     ```
2. **Gitignore Protection**: Ensure `.gitignore` includes:
   ```
   .env
   .env.local
   .env*.local
   **/.env
   ```
3. **No Secrets in Example Files**: `.env.example` must only contain:
   - Variable names
   - Type hints (as comments)
   - Placeholder values (e.g., `DATABASE_URL=postgresql://user:password@localhost:5432/dbname`)
   - Never real credentials, even "development" ones

**Loading & Validation:**
- Load environment files in order of precedence (process.env > .env.local > .env)
- Validate all required variables at startup; fail fast with clear error listing missing vars
- Use typed loaders: `zod` (Node), `pydantic-settings` (Python), `typesafe-config` (JVM)
- Example validation pattern:
  ```typescript
  import { z } from 'zod';
  const ConfigSchema = z.object({
    DATABASE_URL: z.string().url(),
    API_KEY: z.string().min(20),
    PORT: z.coerce.number().default(3000),
  });
  export const config = ConfigSchema.parse(process.env);
  ```

**Documentation Requirements:**
- README must include "Configuration" section listing:
  - All required environment variables
  - Type, purpose, and example value for each
  - Where to obtain sensitive values (e.g., "Request API_KEY from #platform-team")
- Inline comments in `.env.example` for non-obvious variables
- Document any variable dependencies (e.g., "If REDIS_ENABLED=true, REDIS_URL required")

**CI/CD Integration:**
- CI environments load secrets from secure stores (GitHub Secrets, AWS Parameter Store, HashiCorp Vault)
- Never log secret values; redact in application logs and CI output
- Rotate secrets on exposure; treat as security incident

**Developer Workflow:**
1. Clone repo
2. Copy `.env.example` to `.env`: `cp .env.example .env`
3. Install pre-commit hooks: `pre-commit install` (or equivalent for your tooling)
4. Fill in local secrets in `.env`
5. Verify startup: app should fail clearly if misconfigured

**Prohibited Patterns:**
- Committing `.env` files with any secrets (even "fake" ones that look real)
- Hardcoded fallback secrets in application code
- Sharing `.env` files via Slack, email, or unencrypted channels
- Using production secrets in local development

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

#### Project Documentation Standards
- Every project must be properly documented
- Keep README.md current and comprehensive
- Document all setup, development, testing, and deployment procedures
- Include troubleshooting and FAQ sections

#### README.md Structure
- **Project Overview**: Purpose and key features
- **Prerequisites**: Required tools and versions
- **Checkout**: Git clone and initial setup instructions
- **Development**: Local development environment setup
- **Testing**: How to run unit and integration tests
- **Running**: How to start the application locally
- **Deployment**: Manual deployment and CI/CD instructions
- **Configuration**: Environment variables and settings
- **Contributing**: Development guidelines and standards

#### Documentation Requirements (Summary)
- Root README (purpose, layout, build/test/run, release summary)
- Module README (scope, public API, boundaries)
- ADRs for significant decisions / deviations
- CHANGELOG auto-generated; inline comments only for non-obvious logic

#### Code Documentation Standards
- Document all public APIs (files, classes, methods, functions)
- Include parameter descriptions and return values
- Document exceptions and error conditions
- Provide usage examples for complex functions
- Keep documentation synchronized with code changes

#### Approved Documentation Libraries by Language
- **JavaScript/TypeScript**: JSDoc
- **Java**: JavaDoc
- **Kotlin**: KDoc
- **Python**: pydoc, Sphinx
- **C#/.NET**: XML Documentation Comments
- **Go**: godoc
- **Rust**: rustdoc

#### Documentation Format Examples

**JSDoc (JavaScript/TypeScript)**
```javascript
/**
 * Calculates user permissions based on role
 * @param {string} userId - The user identifier
 * @param {string} role - User role type
 * @returns {Promise<Permission[]>} Array of user permissions
 * @throws {AuthorizationError} When user lacks access
 */
```

**JavaDoc/KDoc (Java/Kotlin)**
```java
/**
 * Processes payment transaction
 * @param amount Transaction amount in cents
 * @param currency ISO currency code
 * @return Transaction result with status
 * @throws PaymentException When payment fails
 */
```

**XML Documentation (.NET)**
```csharp
/// <summary>
/// Validates user input data
/// </summary>
/// <param name="input">User input to validate</param>
/// <returns>True if valid, false otherwise</returns>
/// <exception cref="ValidationException">Thrown when validation fails</exception>
```

#### Documentation Generation
- Generate source code documentation using language-specific tools
- Publish generated documentation to project pages (e.g., GitLab Pages, GitHub Pages)
- Automate documentation generation in CI/CD pipeline
- Keep generated documentation current with each release

#### Generation Tools by Language
- **JavaScript/TypeScript**: JSDoc → HTML
- **Java**: JavaDoc → HTML
- **Kotlin**: Dokka → HTML
- **Python**: Sphinx, pydoc → HTML
- **C#/.NET**: DocFX, Sandcastle → HTML
- **Go**: godoc → HTML
- **Rust**: rustdoc → HTML

#### Documentation Maintenance
- Review and update documentation during code reviews
- Validate documentation accuracy during releases
- Remove outdated documentation promptly

#### Agent-Generated Documentation & State Management
All markdown summaries, analysis, or state files created by LLM agents (Amazon Q, Cline, Copilot, GitHub Copilot, etc.) MUST be placed in the `.ai/` directory with the following structure:

```
.ai/
├── session.md           # Current session working notes (ephemeral)
├── architecture.md      # Architectural insights and decisions (persistent)
└── implementation.md    # Implementation progress and patterns (persistent)
```

**Agent Documentation Guidelines:**
- **Maximum 3 files**: Session notes (ephemeral), Architecture analysis (persistent), Implementation log (persistent)
- **Session Notes** (`.ai/session.md`): 
  - Temporary working notes for current conversation
  - Cleared/archived at logical session boundaries
  - Contains TODO lists, quick observations, scratch work
  - May be git-ignored or committed based on team preference
- **Architecture Analysis** (`.ai/architecture.md`):
  - Persistent architectural insights and system design decisions
  - Dependencies, patterns, and structural observations
  - Technology choices and rationale
  - Updated via append or dated sections (maintain history)
  - Should be committed to preserve team knowledge
- **Implementation Log** (`.ai/implementation.md`):
  - Persistent implementation history with chronological entries
  - Key code changes and their reasoning
  - Integration patterns and lessons learned
  - Refactoring notes and migration steps
  - Should be committed to track evolution

**Prohibited Patterns:**
- Creating multiple dated or timestamped markdown files (e.g., `analysis-2025-01-15.md`)
- Scattered documentation across various directories
- Per-feature or per-task documentation files (consolidate into the 3 files above)
- Duplicate information across multiple files
- Creating new markdown files without explicit user request
- Using root-level or arbitrary directories for agent state

**File Maintenance:**
- Archive old session notes to `.ai/archive/` before starting new major work
- Keep architecture analysis focused on current system state (archive deprecated sections)
- Prune implementation log if it exceeds 1000 lines (move older entries to archive)
- Use Git history for detailed change tracking, not proliferated markdown files
- Review and consolidate quarterly to prevent bloat

**Gitignore Recommendations:**
Add to `.gitignore` if session notes should remain local:
```
.ai/session.md
.ai/archive/
```
Commit architecture and implementation logs for team visibility.

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

### 5.4 Testing Requirements & Best Practices

#### General Testing Requirements
- All projects must have comprehensive test coverage
- Implement unit, integration, and end-to-end tests
- Use Katalon for automated UI/API testing where applicable
- Strive for above 80% code coverage (≥70% minimum, aim higher)
- Write tests alongside feature development

#### Test Types Detailed
- **Unit Tests**: Test individual components in isolation
- **Integration Tests**: Test component interactions
- **End-to-End Tests**: Test complete user workflows
- **Katalon Tests**: Automated UI and API testing

#### Approved Testing Tools by Language

**Java/Kotlin**
- **Unit Testing**: JUnit 5, TestNG
- **Mocking**: Mockito, MockK (Kotlin)
- **Integration**: Testcontainers
- **Coverage**: JaCoCo

**JavaScript/TypeScript/Node.js**
- **Unit Testing**: Jest, Vitest
- **Mocking**: Jest mocks, Sinon.js
- **Integration**: Supertest, Testcontainers
- **Coverage**: Istanbul, c8

**Python**
- **Unit Testing**: pytest, unittest
- **Mocking**: unittest.mock, pytest-mock
- **Integration**: Testcontainers-python
- **Coverage**: coverage.py, pytest-cov

**.NET/C#**
- **Unit Testing**: xUnit, NUnit, MSTest
- **Mocking**: Moq, NSubstitute
- **Integration**: Testcontainers.DotNet
- **Coverage**: Coverlet, dotCover

#### CI/CD Integration
- Run unit tests before build stage in CI/CD pipeline
- Configure pre-commit hooks to run unit tests before commits
- Fail builds on test failures or coverage drops
- Generate and publish test reports

#### External Dependencies
- Mock external services for unit tests
- Use test doubles (mocks, stubs, fakes) appropriately
- Implement testcontainers for integration tests
- Ensure tests run consistently in local and CI/CD environments

#### Test Environment Setup
- Use testcontainers for database and service dependencies
- Configure isolated test environments
- Implement proper test data management
- Clean up test resources after execution

#### Coverage Requirements
- Maintain minimum 70% code coverage (aim for 80%+)
- Focus coverage on business logic and critical paths
- Exclude configuration and boilerplate code from coverage
- Monitor coverage trends and prevent regression
- Diff coverage gate enforces non-regression

#### Testing Best Practices
- Write descriptive test names that explain behavior
- Follow AAA pattern (Arrange, Act, Assert)
- Keep tests independent and deterministic
- Use parameterized tests for multiple scenarios
- Implement proper test categorization and tagging
- Tests must be fast: unit tests <200ms average
- Use fixed clocks and seeded randomness (no time/random without control)
- Snapshot tests: minimal & stable only

#### Pre-commit Hooks
- Configure git hooks to run unit tests before commits
- Prevent commits that break existing tests
- Run linting and formatting checks
- Validate code coverage thresholds

#### Test Data Management
- Use factories or builders for test data creation
- Implement database seeding for integration tests
- Clean test data between test runs
- Use realistic but anonymized test data

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

#### Continuous Integration (CI)
**Pipeline Stages** (gated, fail-fast):
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

**CI/CD Platform Requirements**:
- All projects must have CI/CD configuration (`.gitlab-ci.yml`, `.github/workflows/`, etc.).
- Configure pipeline for testing and deployment.
- Use appropriate stages: build, test, deploy.
- Implement proper artifact management.
- Use environment-specific deployments.

**Pipeline Structure Best Practices**:
- Use Docker images for consistent environments.
- Cache dependencies between pipeline runs.
- Implement proper secret management.
- Use platform environments for deployment tracking.
- Configure manual approval for production deployments.
- Implement rollback strategies.

**Test and Coverage in CI**:
- Generate JUnit XML test reports.
- Publish test results to CI platform.
- Generate code coverage reports (JaCoCo, Istanbul, coverage.py, etc.).
- Upload coverage artifacts.
- Configure coverage thresholds and quality gates.
- Display coverage badges in project README.
- Fail builds on test failures or coverage drops.

**Sample GitLab CI/CD Template**:
```yaml
stages:
  - build
  - test
  - coverage
  - deploy

test:
  stage: test
  script:
    - run-tests
  artifacts:
    reports:
      junit: test-results.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
    paths:
      - coverage/
    expire_in: 1 week
  coverage: '/Coverage: \d+\.\d+%/'
```

**Required Variables**:
- Set project-specific variables in CI/CD settings.
- Use environment variables for configuration.
- Implement proper variable scoping (project/group/instance).
- Never commit secrets to repository.
- Use CI/CD platform variables for sensitive data.

#### Continuous Deployment (CD)
- Progressive: dev → staging → prod with automated verification gates.
- Feature flags control gradual exposure (not code branches).
- Canary: small % traffic + metrics guardrail.
- Rollback: single command workflow; previous artifact retained.

**Deployment Monitoring**:
- Configure pipeline notifications.
- Track deployment metrics.
- Implement health checks post-deployment.
- Set up alerting for failed deployments.

#### AWS Authentication in CI/CD
- **Prefer OIDC** (OpenID Connect) for AWS authentication in CI/CD pipelines.
- Do not use AWS access keys or long-lived credentials in environment variables.
- Configure AWS IAM roles with CI/CD platform OIDC provider.
- Use assume role with web identity for secure authentication.
- Implement least privilege access for IAM roles.

#### Infrastructure as Code
- Terraform modules versioned; no inline imperative scripting.
- Validate plan in PR (terraform plan comment).
- Security rules (network, IAM) codified + reviewed.
- Maintain infrastructure code in version control.
- Use consistent directory structure (e.g., `/infrastructure` at root).

#### Monitoring & Logging
- Metrics: RED + USE (request rate, errors, duration; resource saturation).
- Tracing: 100% head sampling in staging; production sampling adjustable via config.
- Dashboards: standard layout (latency p95/p99, error %, saturation, GC/native memory).
- Alerts: page only on actionable SLO breaches; no alert spam.

#### Security in CI/CD
- Never commit secrets to repository.
- Implement least privilege access.
- Scan for vulnerabilities in dependencies.
- Use SAST tools in pipeline.
- Scan container images for vulnerabilities.
- Validate SBOM and provenance.

### 8.3 Git Platform Management (GitHub / GitLab)

#### GitHub Best Practices

**Repository Security**:
- Enable branch protection for main/master branches
- Require pull request reviews before merging
- Enable status checks and require branches to be up to date
- Use signed commits (GPG/SSH)
- Enable Dependabot security updates
- Configure secret scanning and push protection
- Use GitHub Advanced Security features (code scanning, secret scanning)

**Access Control**:
- Use teams for group-level permissions
- Implement least privilege principle
- Enable two-factor authentication requirement for organization
- Use deploy keys for automated deployments
- Regular access reviews and cleanup
- Use CODEOWNERS file for automatic review requests

**Pull Request Guidelines**:
- Use descriptive PR titles and descriptions
- Link PRs to issues (Closes #123, Fixes #456)
- Require code review before merging
- Use PR templates for consistency
- Enable auto-merge after approval (optional)
- Configure required reviewers based on changed paths

**Actions & Automation**:
- Use GitHub Actions for CI/CD workflows
- Store secrets in GitHub Secrets (repository or organization level)
- Use environments for deployment protection
- Implement proper workflow permissions (principle of least privilege)
- Cache dependencies for faster builds
- Use reusable workflows for consistency

**Issue Management**:
- Use issue templates for bug reports and feature requests
- Label issues consistently
- Link commits to issues using keywords (fixes, closes, resolves)
- Use projects (beta) for workflow management
- Enable discussions for community engagement

**Repository Configuration**:
- Use meaningful repository descriptions and topics
- Configure webhooks for external integrations
- Enable GitHub Pages for documentation (if applicable)
- Use repository templates for consistent setup
- Configure security policies (SECURITY.md)

#### GitLab Best Practices

**Repository Security**:
- Enable branch protection for main/master branches
- Require merge request approvals before merging
- Enable push rules to prevent force pushes to protected branches
- Use signed commits where possible
- Enable vulnerability scanning and dependency scanning
- Configure secret detection to prevent credential leaks

**SAST and Security Scanning**:
- Enable GitLab SAST (Static Application Security Testing) in CI/CD pipelines
- Configure dependency scanning for known vulnerabilities
- Use container scanning for Docker images
- Enable license compliance scanning
- Set up security dashboard monitoring
- Configure security policies and approval rules

**Access Control and Permissions**:
- Use least privilege principle for project access
- Configure group-level permissions appropriately
- Use deploy keys for automated deployments
- Implement proper role-based access control
- Enable two-factor authentication for all users
- Regular access reviews and cleanup

**Merge Request Guidelines**:
- Use descriptive merge request titles and descriptions
- Link merge requests to issues where applicable
- Require code review before merging
- Use merge request templates for consistency
- Enable merge request approvals
- Configure automatic merge after approval

**Issue and Project Management**:
- Use issue templates for bug reports and feature requests
- Label issues consistently for better organization
- Link commits to issues using keywords
- Use milestones for release planning
- Configure issue boards for workflow management
- Enable time tracking for project metrics

**Repository Configuration**:
- Use meaningful repository descriptions
- Configure repository topics/tags for discoverability
- Set up repository mirroring if needed
- Configure webhooks for external integrations
- Use repository templates for consistent project setup
- Enable container registry for Docker images

**Compliance and Auditing**:
- Enable audit logging for security events
- Configure compliance frameworks where required
- Use push rules for commit message standards
- Implement automated compliance checks
- Regular security and access audits
- Document security procedures and incident response

#### Common Git Platform Practices
- Use conventional commits for automated changelog generation
- Implement semantic versioning for releases
- Tag releases with annotated tags
- Maintain CHANGELOG.md (auto-generated preferred)
- Use branch protection rules consistently
- Enable required status checks before merge
- Configure auto-deletion of merged branches

---

### 8.4 Infrastructure as Code (Terraform)

#### Language & Format
- Use HCL (HashiCorp Configuration Language) exclusively
- Format code with `terraform fmt`
- Validate with `terraform validate`
- Use consistent naming conventions (snake_case)

#### Deployment Environments
- **Local Workstation**: Use AWS_PROFILE for credentials
- **CI/CD (GitHub/GitLab)**: Use OIDC credential roles (preferred) or OAuth

#### Authentication Configuration

**Local Development**:
```hcl
provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

variable "aws_profile" {
  description = "AWS profile to use for authentication"
  type        = string
  default     = "default"
}
```

**CI/CD with OIDC** (Preferred):
```hcl
provider "aws" {
  region = var.aws_region
  # Credentials automatically loaded from OIDC token exchange
  # Configure trust relationship in AWS IAM for GitHub/GitLab OIDC provider
}
```

#### Best Practices
- Use remote state backend (S3 + DynamoDB for locking)
- Implement state locking to prevent concurrent modifications
- Use workspaces for environment separation
- Pin provider versions to avoid unexpected changes
- Use data sources over hardcoded values
- Implement proper resource tagging for cost allocation and management
- Use modules for reusable infrastructure components
- Keep modules small and focused on single responsibility
- Version modules using Git tags

#### File Structure
```
infrastructure/
├── main.tf          # Main configuration
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── versions.tf      # Provider versions and Terraform version constraints
├── backend.tf       # Backend configuration (S3)
├── terraform.tfvars.example  # Example variable values (not committed)
└── modules/         # Reusable modules
    ├── vpc/
    ├── eks/
    └── rds/
```

#### Required Variables
```hcl
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
}
```

#### State Configuration
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "project-name/environment/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
  
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

#### Workflow
1. `terraform init` - Initialize backend and download providers
2. `terraform plan` - Preview changes (review in PR)
3. `terraform apply` - Apply changes (in CI/CD or with approval)
4. `terraform destroy` - Clean up resources (with caution)

#### Security & Validation
- Run `terraform validate` in CI/CD pipeline
- Use `terraform plan` output in PR comments for review
- Never commit `.tfstate` files or `.tfvars` with secrets
- Use `.gitignore` for sensitive files
- Implement policy-as-code with Sentinel or OPA (optional)
- Use `tfsec` or similar tools for security scanning

---

### 8.5 Database Management (PostgreSQL)

#### Version & Hosting
- Target PostgreSQL 18+ (enable new planner, performance, SQL features)
- Preferred managed providers: 
  - Neon (branching, autoscaling) for development/preview environments
  - Supabase (auth, storage, edge functions) when integrated platform desired
  - AWS RDS/Aurora for production with HA requirements
- Enforce minimum server_version in migration bootstrap
- Leverage modern PostgreSQL features (JSONB, CTEs, window functions)
- Keep PostgreSQL updated to latest stable version

#### Core Usage Modes
1. Traditional RDBMS (normalized OLTP)
2. Semi-structured NoSQL via JSONB (selective schema flexibility)
3. Vector similarity (pgvector) for embeddings / hybrid search
4. Geospatial (PostGIS) for location, distance, routing enrichment
5. Durable lightweight message queue (pgmq) replacing RabbitMQ for moderate throughput
6. Time-series (TimescaleDB for compression + continuous aggs)
7. Consolidated persistence to reduce operational sprawl (avoid polyglot unless justified)

#### Essential Extensions
Enable explicitly per database:
- pgvector (vector similarity search)
- postgis, postgis_topology (geospatial)
- pgmq (message queue)
- timescaledb (time-series)
- citext (case-insensitive text)
- ltree (hierarchical paths)
- pg_trgm (trigram similarity / fast ILIKE)
- btree_gin / btree_gist (composite index flexibility)
- uuid-ossp or gen_random_uuid() (pgcrypto)
- pg_stat_statements (query insights)
- pg_cron (scheduled maintenance / TTL cleanup)

Only load what is used (lean shared_preload_libraries).

#### Database Design
- Use proper normalization (3NF minimum); denormalize only for measured read hot paths
- Implement foreign key constraints (FK, CHECK, UNIQUE) — never rely solely on application logic
- Use appropriate data types (UUID, JSONB, arrays)
- Follow consistent naming conventions (snake_case)
- Use BIGINT / UUID primary keys (avoid SERIAL for portability)
- Store immutable events (append-only) separately from mutable aggregates
- Partition large fact/time-series tables (native RANGE by time, hash for hotspots)
- Prefer narrow tables; isolate large JSONB/text blobs to side tables if sparse

#### JSONB (Flexible Documents)
Use when attribute set is:
- Sparse / user-defined
- Evolving faster than schema

Best practices:
- Still index frequently queried keys (GIN jsonb_path_ops or expression indexes)
- Promote stable keys to typed columns when frequently filtered/joined
- Avoid deeply nested polymorphic shapes; maintain a version field

#### Indexing Strategy
- Always justify each index (read vs write cost)
- Create indexes based on actual query patterns
- Use composite indexes for multi-column queries; order by selectivity + usage
- Implement partial indexes for filtered queries to shrink hot sets
- Use expression indexes for computed values
- For JSONB: expression indexes or GIN (jsonb_path_ops)
- Prefer covering multicolumn indexes over numerous single-column ones

#### Query Optimization
- Use EXPLAIN ANALYZE for query performance analysis
- Avoid SELECT * in production queries
- Use appropriate JOIN types (INNER, LEFT, etc.)
- Implement proper WHERE clause ordering
- Use LIMIT for pagination queries
- Prevent N+1 queries with batching/joins

#### Performance Best Practices
- Set appropriate work_mem and shared_buffers
- Use connection pooling (PgBouncer, built-in pooling)
- Monitor slow query logs (log_min_duration_statement)
- Use prepared statements to prevent SQL injection and reduce plan churn
- VACUUM tuning: low autovacuum_vacuum_scale_factor for bloat-prone tables
- Analyze after bulk loads
- Benchmark with EXPLAIN (ANALYZE, BUFFERS)

#### Transactions & Concurrency
- Default isolation: READ COMMITTED; escalate to SERIALIZABLE only when anomaly proven
- Keep transactions short; avoid open idle sessions
- Use optimistic concurrency with version / xmin if update contention detected
- For queue consumers: ack via UPDATE / DELETE inside single transaction per message

#### Migrations
- Tooling: declarative versioned migrations (Flyway, Prisma migrate, or similar)
- One migration per logical change, immutable post-merge
- Zero-downtime patterns:
  - Add columns NULLable → backfill → set NOT NULL
  - Create new index CONCURRENTLY
  - Avoid long exclusive locks
- Store migration checksum audit table; block startup if drift
- Validate migrations forward + rollback (where safe) in CI

#### Connection Management
- Use pooled connections (PgBouncer in transaction pooling mode)
- Keep max_connections low; rely on pool sizing (2–4 × CPU cores backend)
- Avoid long-lived idle sessions to reduce memory footprint

#### Monitoring and Maintenance
- Monitor query performance with pg_stat_statements
- Run VACUUM and ANALYZE regularly (automated via autovacuum)
- Monitor database size and growth
- Set up alerts for connection limits and slow queries
- Capture metrics: throughput (tx/s), cache hit ratio, connections, replication lag, bloat
- Log settings: log_min_duration_statement, log_line_prefix includes %m %p %u %d %r %a

#### Security
- Use least privilege principle for database users
- Implement row-level security (RLS) for multi-tenant tables
- Use SSL/TLS for connections (enforce with sslmode=require)
- Enforce SCRAM-SHA-256 authentication; no MD5
- Separate roles: app writer, reader, migrator
- Restrict extension creation to superuser
- Use pgcrypto or external KMS for sensitive column encryption

#### Backup and Recovery
- Implement automated backups with pg_dump or pg_basebackup
- Test backup restoration procedures regularly
- Use point-in-time recovery (PITR) with WAL archiving
- Store backups in separate locations
- For multi-region: async physical replica; document promote runbook

#### Testing & CI
- Spin ephemeral Neon branches for integration tests
- Use Testcontainers with official Postgres 18 image + required extensions
- Seed minimal deterministic data; no production dumps
- Validate migrations forward + rollback in CI

#### Query Review Checklist
- Parameterized queries? (prevent SQL injection)
- Uses correct index?
- Avoids sequential scan on large table (unless justified)?
- Bounded result set (LIMIT / pagination)?
- No N+1 queries (prefer set-based operators / JOIN / LATERAL)?

---

### 8.6 Authentication & Identity

#### Supabase Authentication Integration

**Core Principle**:
- Use Supabase Auth for user authentication in Supabase-backed applications
- Implement proper session management with Supabase
- Follow OAuth best practices for social logins

**CRITICAL: Schema Management**:
- **NEVER modify built-in Supabase schemas** (auth, storage, realtime, etc.) via external SQL or ORMs
- **DO NOT** alter tables, indexes, or constraints in auth.* schemas
- Built-in schemas are managed by Supabase and modifications will break functionality
- Only interact with auth.users through Supabase Auth APIs, never direct SQL modifications
- Create custom tables in the public schema or custom schemas for application data

**Auth Patterns**:
- Protect routes using middleware with Supabase auth checks
- Implement role-based access control using custom permissions
- Store user data in the auth.users table (managed by Supabase)
- Store custom user metadata in raw_user_meta_data JSONB field
- Handle authentication errors gracefully

**Example Implementation**:
```typescript
// Client-side auth (src/lib/supabase/client.ts)
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}

// Server-side auth (src/lib/supabase/server.ts)
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()
  
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // Server Component - ignore cookie setting errors
          }
        },
      },
    }
  )
}

// Usage in components
const supabase = createClient()
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'password'
})
```

**Best Practices**:
- Never expose service_role key to client-side code
- Use Row Level Security (RLS) policies for data access control
- Implement proper error handling for auth failures
- Use refresh tokens appropriately
- Implement logout functionality properly
- Handle session expiration gracefully
- Use email verification for new signups
- Implement password reset flows
- Consider implementing MFA for sensitive operations

#### General Authentication Guidelines
- Use established authentication libraries/services (Supabase, Auth0, AWS Cognito, etc.)
- Never roll your own cryptography
- Store passwords using strong hashing algorithms (bcrypt, argon2)
- Implement rate limiting on authentication endpoints
- Use secure session management practices
- Implement CSRF protection
- Use secure, HttpOnly, SameSite cookies for session tokens
- Implement proper logout that invalidates sessions
- Use HTTPS everywhere (enforce with HSTS headers)
- Implement account lockout after failed login attempts
- Log authentication events for security monitoring

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


