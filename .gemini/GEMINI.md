# AWS Common Rules

## Credential Management

- NEVER hardcode AWS credentials in code, configuration files, or environment variables
- Use AWS profiles for local development: `aws configure --profile <profile-name>`
- Use OIDC roles for CI/CD and production environments
- Reference profiles in AWS CLI commands: `aws s3 ls --profile <profile-name>`
- Use IAM roles for EC2 instances and Lambda functions
- Store sensitive configuration in AWS Systems Manager Parameter Store or AWS Secrets Manager

## Security Best Practices

- Follow principle of least privilege for IAM policies
- Enable MFA for AWS console access
- Use resource-based policies when appropriate
- Implement proper VPC security groups and NACLs
- Enable CloudTrail for audit logging
- Use AWS Config for compliance monitoring

## Resource Naming

- Use consistent naming conventions with environment prefixes
- Include project/application identifiers in resource names
- Use tags for resource organization and cost allocation
- Follow AWS tagging best practices

## Cost Optimization

- Use appropriate instance types and sizes
- Implement auto-scaling where applicable
- Use Reserved Instances or Savings Plans for predictable workloads
- Monitor costs with AWS Cost Explorer and budgets
- Clean up unused resources regularly

## Monitoring and Logging

- Use CloudWatch for metrics and alarms
- Implement structured logging
- Set up appropriate log retention policies
- Use X-Ray for distributed tracing when needed

---

## Service-Specific Guidelines

### AWS Lambda

#### Configuration Management

- Minimize use of environment variables for sensitive data
- Pull configuration from AWS Systems Manager Parameter Store within the application
- Use AWS Secrets Manager for sensitive credentials and API keys
- Cache SSM parameters to reduce API calls and improve performance
- Implement proper error handling for configuration retrieval

#### Deployment Best Practices

- Always use Lambda versions for deployments, never deploy to $LATEST
- Always use the latest available runtime version for the programming language
- Use aliases to manage traffic routing between versions
- Implement blue/green deployments using weighted aliases
- Tag versions with deployment metadata (commit hash, build number, timestamp)
- Use Terraform for infrastructure as code deployments

#### Observability and Debugging

- Always enable AWS X-Ray tracing for distributed request tracking
- Integrate Dynatrace OneAgent for comprehensive application monitoring
- Configure enhanced monitoring and logging
- Use structured logging with JSON format
- Include correlation IDs in all log entries
- Set appropriate log retention periods in CloudWatch
- Implement custom metrics for business logic monitoring
- Use Dynatrace for performance profiling and error tracking

#### Performance Optimization

- Right-size memory allocation based on profiling
- Use provisioned concurrency for latency-sensitive functions
- Implement connection pooling for database connections
- Minimize cold start impact with proper initialization
- Use Lambda layers for shared dependencies

#### Security

- Follow principle of least privilege for IAM execution roles
- Enable VPC configuration only when necessary
- Use Lambda authorizers for API Gateway authentication
- Validate all input parameters and sanitize data
- Implement proper error handling without exposing sensitive information

#### Code Organization

- Keep handler functions lightweight and focused
- Separate business logic from AWS-specific code
- Use dependency injection for testability
- Implement proper exception handling and logging
- Follow single responsibility principle for function design
# .NET Common Rules

## .NET Version

- Use .NET 8+ (LTS) or .NET 9+ for new projects
- Target modern .NET (not .NET Framework)
- Use latest C# language version (C# 12+)
- Enable nullable reference types

## Project Structure

```
src/
├── MyApp.Api/          # Web API project
├── MyApp.Core/         # Business logic
├── MyApp.Infrastructure/ # Data access
└── MyApp.Tests/        # Test projects
```

## Language Features

- Use modern C# features (records, pattern matching, init-only properties)
- Prefer async/await over synchronous operations
- Use nullable reference types with proper annotations
- Leverage minimal APIs for simple endpoints

## Code Quality

- Use EditorConfig for consistent formatting
- Enable code analysis with .editorconfig
- Use StyleCop or similar for style enforcement
- Configure warnings as errors for critical issues

## Dependency Injection

- Use built-in DI container
- Register services with appropriate lifetimes
- Use IOptions pattern for configuration
- Implement proper service abstractions

## Configuration

- Use appsettings.json with environment overrides
- Implement strongly-typed configuration with IOptions
- Use user secrets for development
- Use environment variables for production secrets

## Example Configuration

```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.Services.Configure<DatabaseOptions>(
    builder.Configuration.GetSection("Database"));

builder.Services.AddScoped<IUserService, UserService>();

var app = builder.Build();
```

## Error Handling

- Use global exception handling middleware
- Implement proper logging with ILogger
- Use Result patterns for business logic errors
- Return appropriate HTTP status codes

## Testing

- Use xUnit for unit testing
- Use NSubstitute or Moq for mocking
- Write integration tests with WebApplicationFactory
- Use Testcontainers for database testing

## Performance

- Use async/await throughout the application
- Implement proper caching strategies
- Use memory-efficient collections
- Profile with dotMemory or PerfView

## Documentation

- Use XML documentation comments
- Generate API documentation with Swagger/OpenAPI
- Document public APIs comprehensively
- Include code examples in documentation

## Example XML Documentation

```csharp
/// <summary>
/// Retrieves user information by identifier
/// </summary>
/// <param name="userId">The unique user identifier</param>
/// <param name="cancellationToken">Cancellation token</param>
/// <returns>User information if found</returns>
/// <exception cref="UserNotFoundException">When user doesn't exist</exception>
public async Task<User?> GetUserAsync(Guid userId, CancellationToken cancellationToken = default)
{
    // Implementation
}
```

## Security

- Use HTTPS everywhere
- Implement proper authentication (JWT, Identity)
- Validate all input data
- Use parameterized queries to prevent SQL injection
- Enable security headers
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

#### Specification-Driven Development with Spec-Kit

**Overview:**
This project uses [GitHub Spec-Kit](https://github.com/github/spec-kit) for structured feature development. Specifications are created before implementation and serve as the source of truth for requirements.

**Directory Structure:**

```
project/
├── .specify/                    # Spec-kit configuration
│   ├── memory/
│   │   └── constitution.md     # Project constitution (non-negotiables)
│   ├── templates/              # Spec, plan, task templates
│   └── scripts/                # Automation scripts
│
├── specs/                       # Feature specifications
│   ├── ###-feature-name/       # Each feature gets numbered directory
│   │   ├── spec.md             # Feature specification
│   │   ├── plan.md             # Implementation plan
│   │   ├── tasks.md            # Task breakdown
│   │   ├── research.md         # Technical research
│   │   └── implementation.md   # Implementation notes (post-completion)
│   └── README.md               # Specs index
│
├── docs/                        # Project documentation
│   ├── README.md               # Documentation index
│   ├── adr/                    # Architecture Decision Records
│   ├── setup/                  # Setup & configuration guides
│   ├── features/               # Feature documentation
│   ├── guides/                 # How-to guides
│   ├── api/                    # API documentation
│   └── runbooks/               # Operational procedures
│
├── CHANGELOG.md                # Version history (auto-generated)
├── CONTRIBUTING.md             # Contribution guidelines
└── README.md                   # Project overview
```

**Spec-Kit Workflow:**

1. **Constitution** (`/speckit.constitution`):
   - Define non-negotiable project principles
   - Stored in `.specify/memory/constitution.md`
   - Updated via amendment process with version control

2. **Specify** (`/speckit.specify "feature description"`):
   - Creates `/specs/###-feature-name/spec.md`
   - Defines user scenarios, requirements, success criteria
   - Technology-agnostic, focuses on WHAT not HOW

3. **Plan** (`/speckit.plan`):
   - Generates `/specs/###-feature-name/plan.md`
   - Technical approach, architecture, dependencies
   - Includes constitution compliance check

4. **Tasks** (`/speckit.tasks`):
   - Creates `/specs/###-feature-name/tasks.md`
   - Breaks plan into actionable tasks
   - Each task independently testable

5. **Implement**:
   - Follow tasks in order
   - Link commits to tasks
   - Update implementation.md with notes

**Documentation Types:**

| Type | Location | Purpose | Maintained By |
|------|----------|---------|---------------|
| Specifications | `/specs` | Feature requirements | Spec-kit + team |
| Constitution | `.specify/memory/` | Non-negotiables | Team consensus |
| Setup Guides | `/docs/setup` | Getting started | Developers |
| Feature Docs | `/docs/features` | How features work | Developers |
| How-To Guides | `/docs/guides` | Task-oriented | Developers |
| ADRs | `/docs/adr` | Architectural decisions | Architects |
| API Docs | `/docs/api` | API reference | Auto-generated + manual |
| Runbooks | `/docs/runbooks` | Operations | DevOps |
| Changelog | `CHANGELOG.md` | Version history | Auto-generated |

**Best Practices:**

- ✅ Write specs before code (specification-first)
- ✅ Keep specs focused and testable
- ✅ Update specs when requirements change
- ✅ Archive completed specs with implementation notes
- ✅ Link commits to spec tasks
- ✅ Use constitution for non-negotiable principles
- ✅ Create ADRs for significant architectural decisions
- ✅ Keep documentation synchronized with code
- ✅ Auto-generate CHANGELOG from conventional commits

**Prohibited Patterns:**

- ❌ Implementing features without approved specifications
- ❌ Scattered markdown files in root directory
- ❌ Duplicate documentation across multiple locations
- ❌ Outdated documentation (update in same PR as code)
- ❌ Specifications that describe implementation details (keep technology-agnostic)

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

#### Environment Management & Service Branching Strategies

**Core Principle**: Leverage built-in environment branching features of modern cloud services instead of creating separate projects/accounts for each environment. This reduces costs, simplifies management, and enables better collaboration.

**General Best Practices**:
- Use service-native branching/environment features when available
- Map environments to branches: development → feature branches, staging → staging branch, production → main branch
- Automate environment provisioning and teardown via CI/CD
- Tag resources consistently with environment labels for cost tracking
- Document environment-specific configurations and limitations
- Always research the specific service's best practices before implementation

**Database Services**

**Neon (PostgreSQL)**:
- **Use Database Branching**: Neon's primary feature for environment management
- **Development**: Create branch per feature/PR from main database
  - Instant branching with copy-on-write (no data duplication cost)
  - Automatically deleted when PR closes (configure in CI/CD)
  - Each developer/feature gets isolated database
- **Staging**: Maintain dedicated staging branch from production
  - Refresh periodically from production data (with PII scrubbing)
  - Reset to production state for testing migrations
- **Production**: Main branch with compute autoscaling
- **CI/CD Integration**: Use Neon API to create/delete branches automatically
- **Cost Optimization**: Branches share storage; only active compute costs
```bash
# Example: Create branch via Neon API in CI
curl -X POST "https://console.neon.tech/api/v2/projects/$PROJECT_ID/branches" \
  -H "Authorization: Bearer $NEON_API_KEY" \
  -d '{"name":"feature-123","parent_id":"main"}'
```

**Supabase**:
- **Project-based environments**: Use Supabase CLI and branching workflows
- **Development**: Local Supabase instance via Docker (`supabase start`)
  - Run locally for development with seeded data
  - Migrations tracked in version control
- **Preview/Staging**: 
  - Option 1: Separate Supabase project with Preview Project links
  - Option 2: Use Supabase Branches (beta feature when available)
  - Link to Neon database branch for data isolation
- **Production**: Dedicated Supabase project
- **Database**: Connect Supabase to external Neon database and use Neon branching
- **Migration Strategy**: 
  - Develop migrations locally
  - Test in preview environment
  - Deploy to production via CI/CD (`supabase db push`)
```yaml
# Example: supabase/config.toml
[db]
  major_version = 15
  port = 54322
  
# Link to external Neon database per environment
# Dev: Neon branch for feature
# Staging: Neon staging branch  
# Prod: Neon main branch
```

**AWS RDS/Aurora**:
- **Avoid multiple RDS instances per environment** (cost prohibitive)
- **Use database/schema separation**:
  - Single RDS instance with separate databases: `myapp_dev`, `myapp_staging`, `myapp_prod`
  - Or schema-level isolation: `dev.users`, `staging.users`, `prod.users`
- **Alternative**: RDS Snapshots for staging refresh
- **Prefer Neon for cost-effective branching** over multiple RDS instances

**Hosting & Compute Services**

**AWS Amplify Hosting**:
- **Branch-based deployments**: Automatic per Git branch
- **Development**: Feature branches auto-deploy to preview URLs
  - `https://feature-123.d1234.amplifyapp.com`
  - Automatic deletion when branch deleted
- **Staging**: Deploy from `staging` branch
  - `https://staging.d1234.amplifyapp.com`
  - Requires manual approval gate in CI/CD
- **Production**: Deploy from `main` branch
  - Custom domain mapping
  - Enable production-only features (CDN, WAF)
- **Environment Variables**: Configure per branch in Amplify console
- **Database Connection**: Map Amplify branch to corresponding Neon branch
```yaml
# amplify.yml - environment-specific builds
version: 1
frontend:
  phases:
    preBuild:
      commands:
        # Inject environment-specific Neon connection
        - |
          if [ "${AWS_BRANCH}" = "main" ]; then
            export DATABASE_URL="${NEON_PROD_URL}"
          elif [ "${AWS_BRANCH}" = "staging" ]; then
            export DATABASE_URL="${NEON_STAGING_URL}"
          else
            # Feature branch - create Neon branch
            export DATABASE_URL=$(create_neon_branch.sh)
          fi
```

**Vercel**:
- **Git Integration**: Automatic preview deployments per branch/PR
- **Development**: Preview URLs for every commit
  - Automatic environment variable injection
  - Preview database connections to Neon branches
- **Production**: Deploy from production branch
- **Environment Variables**: Configure per environment (Development/Preview/Production)
- **Serverless Functions**: Automatically deployed per environment

**AWS Lambda + API Gateway**:
- **Single Lambda, Multiple Versions/Aliases**:
  - Publish new Lambda version on code change
  - Create aliases for environments: `dev`, `staging`, `prod`
  - API Gateway stages map to Lambda aliases
- **API Gateway Stages**:
  - `/dev` → Lambda alias `dev`
  - `/staging` → Lambda alias `staging`  
  - `/prod` → Lambda alias `prod`
- **Environment Variables**: Set per Lambda alias
- **Canary Deployments**: Use Lambda weighted aliases
```bash
# Example: Deploy Lambda with aliases
aws lambda publish-version --function-name myFunction
aws lambda update-alias --function-name myFunction \
  --name staging --function-version 5
  
# API Gateway stage mapping
aws apigateway update-stage --rest-api-id abc123 \
  --stage-name staging --patch-operations \
  op=replace,path=/variables/lambdaAlias,value=staging
```

**Cloudflare Workers/Pages**:
- **Branch Previews**: Automatic preview deployments
- **Environments**: Production and Preview (automatically managed)
- **Environment Variables**: Configure per environment in dashboard
- **Durable Objects**: Use separate namespaces per environment

**Backend-as-a-Service (BaaS)**

**Firebase**:
- **Projects as Environments**: Use separate Firebase projects
  - Development project with emulator suite
  - Staging project (clone of production)
  - Production project
- **Emulator Suite**: Run Firebase services locally
- **Cost Management**: Use Blaze plan; set budget alerts
- **Firestore**: Use separate collections or subcollections per environment within same project (anti-pattern, prefer separate projects)

**Networking & CDN**

**CloudFront**:
- **Single Distribution, Multiple Behaviors**: Route patterns to different origins
- **Lambda@Edge**: Deploy different function versions per environment
- **Use Cases**: Route `/api/dev/*` to dev API, `/api/prod/*` to prod API

**API Management**

**AWS API Gateway**:
- **Stages for Environments**: 
  - Create stages: `dev`, `staging`, `prod`
  - Deploy API to specific stage
  - Each stage has unique invoke URL
- **Stage Variables**: Environment-specific configuration
  - Database endpoints
  - Lambda function versions/aliases
  - Feature flags
- **Canary Releases**: Enable canary on production stage (% traffic split)
```json
{
  "stageVariables": {
    "lambdaAlias": "prod",
    "dbEndpoint": "${NEON_PROD_URL}",
    "featureFlagEndpoint": "https://prod.flags.example.com"
  }
}
```

**Monitoring & Observability Per Environment**

- **CloudWatch/Datadog**: Use environment tags for log/metric filtering
- **Sentry/Error Tracking**: Separate projects or use environment tags
- **Application Insights**: Configure different instrumentation keys
- **Distributed Tracing**: Tag spans with environment metadata

**Cost Optimization Strategies**

1. **Consolidate where possible**: Single service instance with logical separation
2. **Auto-scaling**: Use serverless/auto-scaling for non-prod (scale to zero)
3. **Scheduled shutdown**: Shut down dev/staging resources outside business hours
4. **Ephemeral environments**: Create on-demand, destroy after use (preview environments)
5. **Shared resources**: Use same monitoring, logging, CI/CD infrastructure
6. **Database branching**: Leverage copy-on-write (Neon) vs full database copies

**Anti-Patterns to Avoid**

❌ **Multiple AWS accounts per environment** (for small teams/projects)
  - Overhead of account management
  - Complicated cross-account access
  - ✅ **Better**: Use single account with resource tagging

❌ **Full database clones for each environment**
  - Storage costs multiply
  - Data drift issues
  - ✅ **Better**: Use database branching (Neon) or schema separation

❌ **Separate Supabase/Firebase projects for every feature branch**
  - Cost explosion
  - Management complexity
  - ✅ **Better**: Local emulators + single staging project

❌ **Production data in development/staging**
  - Security/compliance risk
  - ✅ **Better**: Synthetic data or anonymized snapshots

**Environment Lifecycle Management**

```yaml
# Example: GitHub Actions workflow for ephemeral environments
name: Preview Environment
on: pull_request

jobs:
  deploy-preview:
    runs-on: ubuntu-latest
    steps:
      - name: Create Neon Branch
        id: neon
        run: |
          BRANCH_ID=$(curl -X POST ... | jq -r '.branch.id')
          echo "branch_id=$BRANCH_ID" >> $GITHUB_OUTPUT
          
      - name: Deploy to Amplify Preview
        run: |
          # Amplify auto-deploys on branch push
          # Set DATABASE_URL to Neon branch connection string
          
      - name: Comment PR with URLs
        run: |
          gh pr comment ${{ github.event.pull_request.number }} \
            --body "Preview: https://pr-${{ github.event.pull_request.number }}.amplifyapp.com"
            
  cleanup:
    runs-on: ubuntu-latest
    if: github.event.pull_request.merged == true || github.event.pull_request.state == 'closed'
    steps:
      - name: Delete Neon Branch
        run: curl -X DELETE "https://console.neon.tech/api/v2/projects/$PROJECT/branches/$BRANCH_ID"
```

**Checklist: Choosing Environment Strategy**

- [ ] Service supports native branching/environments? (Prefer this)
- [ ] Cost implications of multiple projects vs branching?
- [ ] Data isolation requirements (compliance, security)?
- [ ] Team size and collaboration needs?
- [ ] Automation capabilities (API, CLI, IaC)?
- [ ] Monitoring and observability requirements?
- [ ] Disaster recovery and backup strategies aligned?

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
Non-Negotiables: no failing/skipped tests without issue; no TODO without ticket; no secrets committed; no unreviewed generated code; after any schema, code, or configuration changes, verify the application builds, compiles, passes linting, and all unit tests succeed before considering the change complete.

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
- After any schema, code, or configuration changes, verify the application builds, compiles, passes linting, and all unit tests succeed before considering the change complete.

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
---
applyTo: '**'
---

# Node.js Common Instructions
## Runtime Selection
- **Development**: Use Node.js LTS to maintain VS Code debugger compatibility and tooling support.
- **Production**: Prefer Bun for containerized deployments and production environments where possible for better performance and smaller footprint.
- **Compatibility**: Ensure code works with both runtimes; test with Node.js during development and Bun in staging/production.

## General Guidelines
- Always use TypeScript (no new JavaScript source files).
- Target current LTS Node.js for development; prefer ESM (`"type": "module"` in package.json).
- Enable strictness: `"strict": true`, `"noUncheckedIndexedAccess": true`, `"exactOptionalPropertyTypes": true`.
- Fail CI on TypeScript, ESLint, and test errors; treat warnings as errors.
- Prefer composition over inheritance; keep functions pure where practical.
- Enforce single responsibility; keep files small and cohesive.
- Never ignore promise rejections; use `await` or `.catch`.
- Use async/await; avoid raw callback patterns.
- Validate all external input (e.g. API, env vars) early.
- Centralize configuration; no hard-coded magic values.

## Project Structure (example)
- src/
  - domain/ (pure logic)
  - services/ (I/O boundaries)
  - adapters/ (wrappers: HTTP, DB, queues)
  - infra/ (configuration, logging)
  - index.ts (composition root)
- tests/ mirrors src structure.

## Approved Libraries / APIs
- HTTP / Fetch: Built-in global fetch (Node 18+). For advanced cases: undici.
- Dates / Time: date-fns (avoid moment).
- Validation: zod.
- Environment loading: dotenv (only in dev), never commit .env.
- Logging: pino (structured JSON).
- Testing: vitest or jest (pick one per repo).
- Mocking: test framework built-ins; avoid brittle manual mocks.
- HTTP server: ElysiaJS (https://elysiajs.com) (preferred), fastify, hono, or express (legacy only).
- HTTP client (if richer than fetch needed): undici.
- Task scheduling / queues: bullmq (Redis-backed) when required.
- Database (if using PostgreSQL): Prefer Prisma ORM; defer to project if using pure supabase.js instead.
- Caching: ioredis.
- UUIDs: uuid (v7 when available).
Unapproved: moment, request, deprecated or unmaintained packages.

## TypeScript Conventions
- Target TypeScript 6.0+ for enhanced schema-based type inference and validation
- Use path aliases via tsconfig `paths` instead of deep relative imports.
- Export types separately when helpful (`export type { Foo }`).
- Narrow unknown/any at boundaries only; forbid implicit any.
- Prefer readonly for immutable shapes; use `as const` intentionally.
- Avoid enums; use union string literals + type guards.
- Leverage TypeScript 6.0's automatic type inference with Zod schemas (no manual `z.infer<>` needed)
- Use Zod for runtime validation at all data boundaries (APIs, user input, environment variables)

## Runtime Validation with Zod
- **Validate at boundaries**: All external data (API responses, user input, environment variables) MUST be validated with Zod
- **TypeScript 6.0 integration**: Use automatic type inference instead of manual `z.infer<typeof schema>`
- **Fail fast**: Validate environment variables and critical configuration at startup
- **API response validation**: Never trust external APIs - validate all responses to catch breaking changes early

**Environment Variable Validation**:
```typescript
// lib/env.ts
import { z } from 'zod';

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  API_KEY: z.string().min(32),
  NODE_ENV: z.enum(['development', 'production', 'test'])
});

export const env = envSchema.parse(process.env); // Fail fast if invalid
```

**API Response Validation**:
```typescript
const apiResponseSchema = z.object({
  data: z.array(z.object({
    id: z.number(),
    title: z.string(),
    status: z.enum(['draft', 'published'])
  })),
  meta: z.object({
    page: z.number(),
    total: z.number()
  })
});

async function fetchPosts() {
  const res = await fetch('/api/posts');
  const json = await res.json();
  return apiResponseSchema.parse(json); // Crash early if API breaks contract
}
```

**TypeScript 6.0 Function Signatures**:
```typescript
const userSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  age: z.number().min(18)
});

// TypeScript 6.0 automatically infers types
function saveUser(data: typeof userSchema._input) {
  const validated = userSchema.parse(data);
  // validated is now fully typed without manual inference
}
```

## Error Handling
- Throw domain-specific error classes (`extends Error`) with a code property.
- Never throw strings.
- Wrap external failures; do not leak low-level error types beyond adapters.
- Provide a global process-level handler logging and performing graceful shutdown.

## Logging
- Structured logs (JSON); no console.log outside quick scripts.
- Include correlation/request IDs and error.stack.
- Redact secrets (tokens, passwords, keys).

## Configuration
- Load once in infra layer.
- Validate with zod before exporting a typed config object.
- No dynamic mutation after bootstrap.

## Environment Variables & .env Files
- Use minimal .env files; prefer platform-native configuration (AWS Systems Manager, Amplify env vars).
- Never commit .env files; add to .gitignore.
- Provide .env.example with placeholder values only.
- Framework-specific: only use what the framework requires.

### Next.js Environment Variables
Next.js requires only:
- `.env.local` for local development (gitignored)
- `.env.example` for documentation (committed)

**Minimal .env.local example**:
```
DATABASE_URL="postgresql://user:pass@localhost:5432/db"
NEXT_PUBLIC_API_URL="http://localhost:3000"
```

**Rules**:
- `NEXT_PUBLIC_*` prefix exposes to browser (use sparingly)
- All other vars are server-only
- Validate all env vars with Zod at startup
- Never use .env.development, .env.production, or .env.test unless absolutely necessary

**Validation example**:
```typescript
// lib/env.ts
import { z } from 'zod';

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  NEXT_PUBLIC_API_URL: z.string().url(),
});

export const env = envSchema.parse(process.env);
```

## Security
- Keep dependencies updated (automation via dependabot / renovate).
- Run `npm audit` in CI; address high severity promptly.
- Use parameterized queries / ORM safeguards; never string-concatenate SQL.
- Sanitize and validate all external input.

## Performance
- Avoid premature optimization; measure with benchmarks / profiling.
- Stream large payloads; avoid loading entire files/blobs into memory.
- Use AbortController with fetch for timeouts and cancellation.

## Testing
- 70%+ meaningful coverage; prefer behavior tests over implementation details.
- Use: unit (pure functions), integration (I/O boundaries), e2e (happy paths).
- No network calls in unit tests; mock at adapter boundary only.
- Snapshot tests sparingly (stable, low-noise outputs).

## Git / CI
- Conventional Commits (feat, fix, chore, refactor, docs, test).
- Enforce lint, type-check, test on pull requests.
- Auto-generate changelog via commit messages.
- Use semantic versioning.

## Linting / Formatting
- ESLint with @typescript-eslint; no unused variables (`noUnusedLocals` true).
- Prettier for formatting; run pre-commit (lint-staged + husky).
- Disallow default exports except framework-required.

## Documentation
- README: setup, run, test, build, deploy steps.
- JSDoc only for non-obvious logic; prefer expressive naming.
- Maintain ADRs (Architecture Decision Records) for significant choices.

## Runtime Practices
- Graceful shutdown: listen for SIGINT/SIGTERM, close servers, flush logs.
- Use async local storage or request context for correlation IDs.
- Propagate AbortSignal across async boundaries where cancellation matters.

## Dependencies
- Prefer standard library before adding a dependency.
- Lock file (package-lock.json) committed.
- Periodically audit bundle / cold-start size for serverless contexts.

## Deployment
- Build step outputs to dist/ (no ts-node in production).
- Source maps generated; upload to error tracking if used.
- **Runtime Selection**:
  - Use Bun for containerized production deployments (smaller images, faster startup, better performance).
  - Use Node.js LTS when Bun compatibility issues exist or when specific Node.js features are required.
- **Docker Images**:
  - Immutable multi-stage builds with non-root user.
  - For Bun: use `oven/bun:1-alpine` or `oven/bun:1-distroless` as base.
  - For Node.js: use distroless/node or alpine with care.
  - Example multi-stage Dockerfile with Bun:
    ```dockerfile
    # Build stage
    FROM oven/bun:1-alpine AS builder
    WORKDIR /app
    COPY package.json bun.lockb ./
    RUN bun install --frozen-lockfile
    COPY . .
    RUN bun run build
    
    # Production stage
    FROM oven/bun:1-distroless
    WORKDIR /app
    COPY --from=builder /app/dist ./dist
    COPY --from=builder /app/node_modules ./node_modules
    USER nonroot
    CMD ["bun", "dist/index.js"]
    ```

## Code Review Checklist (abbreviated)
- Clear responsibility? Test coverage adequate?
- No TODO without linked issue.
- No secret values / credentials in code.
- Proper error handling and logging added?
- Types strict, no any leaks?

---

## Framework-Specific Guidelines

### Fastify (Backend API Framework)

#### Project Structure
```
src/
├── app.ts              # Main Fastify app configuration
├── server.ts           # Local/container server entry point
├── handler.ts          # AWS Lambda handler (if needed)
├── routes/             # Route definitions
│   ├── index.ts        # Route registration
│   ├── users.ts        # User routes
│   └── health.ts       # Health check routes
├── plugins/            # Custom Fastify plugins
├── schemas/            # JSON schemas for validation
├── services/           # Business logic services
└── types/              # TypeScript type definitions
```

#### Application Architecture
- **app.ts**: Export configured Fastify instance
- **server.ts**: Start server for local/container deployment
- **handler.ts**: AWS Lambda handler using @fastify/aws-lambda

#### Example Implementation

**app.ts**:
```typescript
import fastify from 'fastify';
import { registerRoutes } from './routes';

export function buildApp() {
  const app = fastify({
    logger: true,
    ajv: { customOptions: { strict: false } },
  });

  app.register(registerRoutes);
  return app;
}
```

**server.ts**:
```typescript
import { buildApp } from './app';

const start = async () => {
  const app = buildApp();
  await app.listen({ port: 3000, host: '0.0.0.0' });
};

start();
```

**handler.ts**:
```typescript
import awsLambdaFastify from '@fastify/aws-lambda';
import { buildApp } from './app';

const app = buildApp();
export const handler = awsLambdaFastify(app);
```

#### Best Practices
- Use Fastify plugins for modular architecture
- Implement JSON schema validation for all routes
- Use async/await for all async operations
- Register routes using autoload or manual registration
- Implement proper error handling with error schemas

#### Naming Conventions
- Use kebab-case for route paths (`/user-profile`)
- Use camelCase for TypeScript variables and functions
- Use PascalCase for types and interfaces
- Prefix interfaces with 'I' (IUserRequest)

#### Validation and Serialization
- Use Zod for request/response validation
- Convert Zod schemas to JSON schemas for Fastify
- Use Fastify's built-in serialization
- Implement custom error responses
- Validate environment variables on startup

**Zod Validation Example**:
```typescript
import { z } from 'zod';
import { zodToJsonSchema } from 'zod-to-json-schema';

// Define Zod schema
const CreateUserSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
  age: z.number().min(18),
});

// Convert to JSON schema for Fastify
const createUserJsonSchema = zodToJsonSchema(CreateUserSchema);

// Route with validation
app.post(
  '/users',
  {
    schema: {
      body: createUserJsonSchema,
      response: {
        201: zodToJsonSchema(z.object({ id: z.string(), name: z.string() })),
      },
    },
  },
  async (request, reply) => {
    const userData = CreateUserSchema.parse(request.body);
    // Handle validated request
  }
);
```

#### Performance
- Enable Fastify's built-in compression
- Use connection pooling for databases
- Implement proper caching strategies
- Configure appropriate timeouts

---

### Next.js + React (Frontend Framework)

#### Stack Requirements
- Use Next.js 16+ with App Router (no legacy Pages Router)
- Use React 18+ with Server Components by default
- Use TypeScript in strict mode
- Use TailwindCSS as primary styling utility with Shadcn/UI and Radix Themes
- Target modern evergreen browsers
- Use ESM everywhere (`"type": "module"`)
- Use the context7 tool with id `/builderio/builder` for latest Builder.io documentation

#### Project Structure
```
src/
├── app/                # App Router directory
│   ├── layout.tsx      # Root layout
│   ├── page.tsx        # Home page
│   ├── globals.css     # Global styles
│   ├── api/            # API routes
│   └── (marketing)/    # Route groups
├── components/         # Shared presentational components
│   ├── server/         # Server components (optional organization)
│   └── client/         # Client components (optional organization)
├── lib/                # Pure functions, service wrappers, utilities
├── hooks/              # Custom React hooks
├── styles/             # Global styles, design tokens
├── types/              # TypeScript definitions
└── test/               # Test files (mirror structure)
```

Avoid deep nesting; prefer segment groups and parallel routes only when justified.

#### React Server vs Client Components
- Default to Server Components (no 'use client')
- Use 'use client' only when needed for:
  - Stateful UI interactions
  - Event handlers
  - Browser-only APIs
- Keep client component bundle size minimal
- Pass only serializable props between server and client
- Avoid marking entire layouts as client components
- Promote data loading, heavy computation, and serialization to server component boundary
- Client components must keep bundle size low; avoid re-exporting large server-only modules

#### Data Fetching & Caching
- Use fetch() in Server Components with proper caching strategies
- Use `cache: 'force-cache'` for static data
- Use `cache: 'no-store'` for dynamic data
- Implement ISR with revalidate tags/time
- Use Route Handlers (app/api) instead of legacy pages/api
- **When using Prisma**: Prefer Server Actions over API routes for database operations unless explicitly specified otherwise in prompt or instructions
  - Server Actions provide type-safe, co-located data mutations
  - Eliminate unnecessary API route boilerplate for database operations
  - Better integration with React Server Components and form handling
  - Use API routes only when needed for external API integrations, webhooks, or when explicitly requested
- Co-locate server actions near form components
- Use tag-based revalidation for selective cache busting
- Use TanStack Query or SWR only for client-side real-time data
- Prefer incremental static regeneration (ISR) via revalidate or tag invalidation; minimize fully dynamic routes unless required
- Wrap external fetchers in lib/ with consistent error mapping; never leak raw HTTP layer details to components
- Ensure server actions are idempotent where possible
- Do not block rendering with artificial awaits; parallelize fetches

#### Component Best Practices
- Use TypeScript for all components with proper interfaces
- Implement single responsibility principle
- Use React hooks appropriately (useState, useEffect, useCallback)
- Use React.memo only when profiling shows benefit
- Follow proper prop typing patterns
- Follow atomic design principles when appropriate

#### Component Organization
- Place page components in `src/app/(routes)`
- Place reusable UI components in `src/components/`
- Keep client components small and focused
- Implement proper error boundaries

#### Performance Optimization
- Analyze bundle size with `next build` output
- Use dynamic imports for heavy components
- Implement proper image optimization with next/image
- Use next/font for typography without layout shift
- Tree-shake icon libraries (prefer lucide-react)
- Use Streaming and Suspense for progressive rendering
- Parallelize data fetches, avoid artificial awaits
- Memoization: only where profiling shows benefit (React.memo, useMemo, useCallback)
- Dynamic import for rarely used interactive parts (e.g. charts, editors) with SSR disabled only if necessary
- Prefer server-side image transformations (next/image) over shipping large raw images

#### Styling with TailwindCSS
- Use design tokens via @layer base and theme config
- Create semantic wrapper components instead of repeating classes
- Use clsx for conditional classes
- Keep globals.css minimal (resets, variables only)
- Configure consistent dark mode strategy
- Ensure proper purge configuration

#### State Management
- Use useState/useReducer for local state
- Use Zustand or Jotai for lightweight cross-component state
- Prefer server state hydration over heavy client state libraries
- Avoid Redux unless complex cross-cutting concerns justify it

#### Forms & Validation
- Use react-hook-form for complex forms
- Use Zod for schema validation with TypeScript inference
- Validate on both client and server (never trust client only)
- Implement accessible error messages with aria-live

**Server Actions with TypeScript 6.0 + Zod**:
```typescript
'use server';

import { z } from 'zod';

const formSchema = z.object({
  username: z.string().min(3).max(20),
  email: z.string().email()
});

export async function createUser(formData: FormData) {
  const raw = Object.fromEntries(formData);
  const result = formSchema.safeParse(raw);
  
  if (!result.success) {
    return { errors: result.error.flatten() };
  }
  
  // result.data is now typed AND validated with TypeScript 6.0
  await db.users.create(result.data);
}
```

#### Accessibility Requirements
- Use semantic HTML elements first (button, nav, header, main)
- Use Radix UI primitives for complex widgets
- Ensure keyboard accessibility for all interactive elements
- Provide proper alt text, aria-labels, and heading hierarchy
- Meet WCAG AA color contrast requirements
- Validate with automated tooling

#### Error & Loading States
- Use loading.tsx and error.tsx for route segments
- Implement proper Error Boundaries
- Create fast skeleton UIs, avoid spinner-only states
- Use not-found.tsx for 404 handling
- Surface user-friendly error messages
- Log detailed errors server-side only

#### Security Best Practices
- Validate all inputs with Zod in route handlers and server actions
- Sanitize HTML content, avoid dangerouslySetInnerHTML
- Set proper security headers via middleware
- Only expose NEXT_PUBLIC_ prefixed environment variables
- Never leak sensitive data to client logs

#### Testing Strategy
- Use Jest/Vitest and React Testing Library for unit tests
- Use Playwright for integration and accessibility tests
- Mock network requests with MSW
- Focus on behavior testing, not implementation details
- Enforce coverage thresholds
- Test custom hooks separately

#### Approved Libraries
- Core: next, react, react-dom
- Styling: tailwindcss, postcss, autoprefixer, clsx
- UI: @radix-ui/react-*, lucide-react
- State: zustand or jotai (if needed)
- Forms: react-hook-form, zod
- Data: @tanstack/react-query or swr
- Testing: @testing-library/react, playwright, msw
- Animation: framer-motion (use sparingly)

#### Deployment (AWS Amplify)
- Target AWS Amplify Hosting with Next.js support
- Use immutable build artifacts
- Configure environment variables in Amplify console
- Enable dependency caching in amplify.yml
- Set proper security headers
- Monitor bundle size budgets in CI

**Example amplify.yml**:
```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - env | grep -E '^(AWS|AMPLIFY|NEXT|NPM|NODE|YARN|PATH|DATABASE|BETTER_AUTH|NEXT_PUBLIC|NEXT_PRIVATE)' >> .env.production
        - nvm install $(cat .nvmrc)
        - nvm use $(cat .nvmrc)
        - npm ci
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: .next
    files:
      - '**/*'
  cache:
    paths:
      - node_modules/**/*
      - .next/cache/**/*
  customHeaders:
    - pattern: '**/*'
      headers:
        - key: 'Cache-Control'
          value: 'public, max-age=31536000, immutable'
        - key: 'X-Content-Type-Options'
          value: 'nosniff'
        - key: 'X-Frame-Options'
          value: 'SAMEORIGIN'
        - key: 'Referrer-Policy'
          value: 'strict-origin-when-cross-origin'
        - key: 'Permissions-Policy'
          value: 'geolocation=(self), microphone=()'
        - key: 'Content-Security-Policy'
          value: "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'self';"
```

#### Internationalization (if used)
- Use Next.js built-in i18n routing or lightweight library; avoid runtime-only heavy libs.
- Load translation dictionaries server-side, pass minimal subset to client.

#### Images / Media
- Always use next/image for dynamic optimization unless exact 1:1 needed from public/.
- Provide width/height to prevent layout shift.
- Use modern formats (AVIF/WebP) via automatic conversion.

#### Logging & Observability
- Client: minimal logging (development only); sensitive data never logged.
- Use web-vitals (reportWebVitals) to send metrics (e.g., to an analytics endpoint).
- Server errors mapped; no stack traces surfaced to user.

#### Styling Alternatives
- Prefer Tailwind; CSS Modules only for rare complex cascade or third-party overrides.
- No SCSS unless legacy; avoid CSS-in-JS runtime solutions (styled-components) unless critical (adds bundle/runtime cost).

#### Naming & Components
- File names: kebab-case or PascalCase for components; consistent choice documented (prefer PascalCase for component files).
- Named exports for components; index.ts barrels sparingly to avoid tree-shaking impediments.
- Avoid default exports except Next.js route segment (layout.tsx, page.tsx) and configuration files.

#### Environment & Config
- next.config.mjs: keep minimal; document experimental flags.
- Distinguish runtime vs build-time configuration; avoid dynamic require.
- Feature flags: simple module returning typed config; optionally integrate with remote flags (lazy loaded).

#### Migration / Deprecation
- Mark deprecated components with clear JSDoc @deprecated and link to replacement.
- Remove unused feature flags / dead routes promptly.

#### Example Component Pattern
```typescript
// components/UserCard.tsx
import { useCallback } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';

interface UserCardProps {
  user: {
    id: string;
    name: string;
    email: string;
  };
  onEdit?: (id: string) => void;
}

export function UserCard({ user, onEdit }: UserCardProps) {
  const handleEdit = useCallback(() => {
    onEdit?.(user.id);
  }, [user.id, onEdit]);

  return (
    <Card>
      <CardHeader>
        <CardTitle>{user.name}</CardTitle>
        <CardDescription>{user.email}</CardDescription>
      </CardHeader>
      {onEdit && (
        <CardContent>
          <Button onClick={handleEdit} variant="default" size="sm">
            Edit
          </Button>
        </CardContent>
      )}
    </Card>
  );
}
```

#### Example Button Component with Variants (Shadcn/UI Pattern)
```typescript
// components/ui/button.tsx
import * as React from 'react';
import { Slot } from '@radix-ui/react-slot';
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/utils';

const buttonVariants = cva(
  'inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
        outline: 'border border-input bg-background hover:bg-accent hover:text-accent-foreground',
        secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
        ghost: 'hover:bg-accent hover:text-accent-foreground',
        link: 'text-primary underline-offset-4 hover:underline',
      },
      size: {
        default: 'h-10 px-4 py-2',
        sm: 'h-9 rounded-md px-3',
        lg: 'h-11 rounded-md px-8',
        icon: 'h-10 w-10',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : 'button';
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    );
  }
);
Button.displayName = 'Button';

export { Button, buttonVariants };
```

#### Example Dialog Component (Radix UI + Shadcn Pattern)
```typescript
// components/UserEditDialog.tsx
'use client';

import { useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

interface UserEditDialogProps {
  user: {
    id: string;
    name: string;
    email: string;
  };
  onSave: (user: { id: string; name: string; email: string }) => void;
}

export function UserEditDialog({ user, onSave }: UserEditDialogProps) {
  const [open, setOpen] = useState(false);
  const [name, setName] = useState(user.name);
  const [email, setEmail] = useState(user.email);

  const handleSave = () => {
    onSave({ id: user.id, name, email });
    setOpen(false);
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button variant="outline">Edit User</Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Edit User</DialogTitle>
          <DialogDescription>
            Make changes to the user profile here. Click save when you're done.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-4 py-4">
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="name" className="text-right">
              Name
            </Label>
            <Input
              id="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="col-span-3"
            />
          </div>
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="email" className="text-right">
              Email
            </Label>
            <Input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="col-span-3"
            />
          </div>
        </div>
        <DialogFooter>
          <Button type="submit" onClick={handleSave}>
            Save changes
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
```

#### Prohibited Patterns
- Large date/time libraries (use native Date or date-fns)
- Client-side rendering entire pages when SSR/SSG suffices
- Global mutable singletons without justification
- Unbounded polling (prefer server-sent events)
- Heavy UI component libraries without ADR justification
- CSS-in-JS runtime solutions (adds bundle cost)

---

### Angular (Frontend Framework)

#### Angular Version Requirements
- Use recent versions of Angular (16+)
- Do not use AngularJS (1.x) for new projects
- Keep Angular CLI updated to latest stable version
- Use Angular LTS versions for production applications

#### Project Structure
- Follow Angular style guide conventions
- Use feature modules for organization
- Implement lazy loading for route modules
- Separate shared components into modules

#### TypeScript Configuration
- Use strict mode in Angular projects
- Enable Angular strict template checks
- Use Angular ESLint rules
- Configure path mapping for clean imports

#### Component Best Practices
- Use OnPush change detection strategy
- Implement OnDestroy for cleanup
- Use reactive forms over template-driven forms
- Follow single responsibility principle

#### State Management
- Use Angular services for simple state
- Implement NgRx for complex state management
- Use RxJS operators effectively
- Avoid memory leaks with proper subscriptions

#### Testing
- Use Jasmine and Karma for unit tests
- Write component tests with TestBed
- Use Angular Testing Library for better tests
- Mock HTTP calls with HttpClientTestingModule

#### Build and Deployment
- Use Angular CLI for builds
- Configure environment-specific builds
- Implement proper bundling and tree-shaking
- Use Angular Universal for SSR when needed

#### Performance
- Implement lazy loading
- Use OnPush change detection
- Optimize bundle sizes
- Use trackBy functions in \*ngFor

---

## Database ORM Guidelines

### Prisma ORM

#### Core Principle
- **All SQL operations MUST be performed through the Prisma schema and Prisma Client**
- Never write raw SQL queries directly - use Prisma's type-safe query API
- Database schema changes MUST be made through Prisma migrations

#### Schema Management
- Define all models in `prisma/schema.prisma`
- Use `npx prisma migrate dev` for development migrations
- Use `npx prisma migrate deploy` for production deployments
- Run `npx prisma generate` after schema changes to update Prisma Client

#### Naming Conventions (PostgreSQL)
- **CRITICAL**: Use camelCase for Prisma model properties
- **CRITICAL**: Map to snake_case database columns using `@map("column_name")`
- This maintains TypeScript/JavaScript conventions while following PostgreSQL best practices
- Example:
  ```prisma
  model User {
    id        String   @id @default(uuid())
    firstName String   @map("first_name")
    lastName  String   @map("last_name")
    createdAt DateTime @default(now()) @map("created_at")
    updatedAt DateTime @updatedAt @map("updated_at")

    @@map("users")
  }
  ```

#### Query Patterns
- Use Prisma Client methods: `findMany`, `findUnique`, `create`, `update`, `delete`, `upsert`
- Leverage Prisma's relation queries instead of manual joins
- Use transactions with `prisma.$transaction()` for atomic operations

#### Best Practices
- Always regenerate Prisma Client after schema modifications
- Use Prisma Studio (`npx prisma studio`) for database inspection
- Validate schema with `npx prisma validate`
- Format schema with `npx prisma format`

---

## Next.js + Supabase Authentication Best Practices

### Overview
This section provides comprehensive best practices for implementing Supabase Auth in Next.js 15+ applications using the App Router and `@supabase/ssr` package.

### Core Principles

1. **Let Supabase Handle Session Management**: Don't implement custom session refresh logic
2. **Proper Cookie Handling**: Follow Supabase's exact cookie patterns to prevent race conditions
3. **PKCE Flow**: Always use PKCE (Proof Key for Code Exchange) for secure authentication
4. **Auth Callbacks**: Implement proper callback routes for email verification and OAuth
5. **Minimal Middleware**: Keep authentication middleware simple and focused

### Required Packages

```json
{
  "dependencies": {
    "@supabase/ssr": "latest",
    "@supabase/supabase-js": "latest"
  }
}
```

### Environment Configuration

**Required Environment Variables**:
```bash
# .env.local
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key

# Optional: For custom redirects
NEXT_PUBLIC_BASE_URL=http://localhost:3000
```

**Validation with Zod**:
```typescript
// lib/env.ts
import { z } from 'zod';

const envSchema = z.object({
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1),
  NEXT_PUBLIC_BASE_URL: z.string().url().optional(),
});

export const env = envSchema.parse(process.env);
```

### Supabase Client Configuration

#### Server Client (SSR)

**CRITICAL Configuration Points**:
- `detectSessionInUrl: true` - Required for auth callbacks
- `autoRefreshToken: true` - Explicit auto-refresh
- `persistSession: true` - Ensure sessions persist across requests
- `flowType: 'pkce'` - Use secure PKCE flow

```typescript
// lib/supabase/server.ts
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            );
          } catch {
            // Server Component - ignore cookie setting errors
          }
        },
      },
      auth: {
        detectSessionInUrl: true,  // CRITICAL: Must be true
        flowType: 'pkce',
        autoRefreshToken: true,     // Explicit auto-refresh
        persistSession: true,       // Persist across requests
      },
    }
  );
}
```

#### Client Component Client

```typescript
// lib/supabase/client.ts
import { createBrowserClient } from '@supabase/ssr';

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
```

### Middleware Pattern

**CRITICAL: Simplified Middleware**
- No custom session refresh logic
- No manual expiry checking
- Let Supabase SDK handle everything
- No code between `createServerClient` and `getUser()`

```typescript
// middleware.ts
import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

export async function middleware(req: NextRequest) {
  let response = NextResponse.next({
    request: req,
  });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return req.cookies.getAll();
        },
        setAll(cookiesToSet) {
          // Update request cookies
          cookiesToSet.forEach(({ name, value }) =>
            req.cookies.set(name, value)
          );
          
          // Create new response with cookies
          response = NextResponse.next({
            request: req,
          });
          
          // Set response cookies with proper options
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options)
          );
        },
      },
    }
  );

  // CRITICAL: Call getUser() immediately after client creation
  // No code in between - this allows Supabase to handle refresh
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // Optional: Redirect logic for protected routes
  if (!user && req.nextUrl.pathname.startsWith('/dashboard')) {
    const redirectUrl = new URL('/login', req.url);
    redirectUrl.searchParams.set('redirectTo', req.nextUrl.pathname);
    return NextResponse.redirect(redirectUrl);
  }

  return response;
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};
```

### Auth Callback Route

**CRITICAL: Required for email verification, magic links, and password resets**

```typescript
// app/auth/confirm/route.ts
import { createClient } from '@/lib/supabase/server';
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  const { searchParams, origin } = new URL(request.url);
  const token_hash = searchParams.get('token_hash');
  const type = searchParams.get('type');
  const next = searchParams.get('next') ?? '/';

  // Create redirect URL
  const redirectTo = new URL(next, origin);

  if (token_hash && type) {
    const supabase = await createClient();

    // Verify OTP token
    const { error } = await supabase.auth.verifyOtp({
      type: type as any,
      token_hash,
    });

    if (!error) {
      redirectTo.searchParams.delete('token_hash');
      redirectTo.searchParams.delete('type');
      return NextResponse.redirect(redirectTo);
    }
  }

  // Return error page if verification fails
  const errorUrl = new URL('/auth/error', origin);
  errorUrl.searchParams.set('error', 'verification_failed');
  return NextResponse.redirect(errorUrl);
}
```

### Auth Error Page

```typescript
// app/auth/error/page.tsx
import { Suspense } from 'react';

function ErrorContent() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="text-center">
        <h1 className="text-2xl font-bold">Authentication Error</h1>
        <p className="mt-2 text-gray-600">
          There was a problem with your authentication request.
        </p>
        <a href="/login" className="mt-4 inline-block text-blue-600">
          Return to login
        </a>
      </div>
    </div>
  );
}

export default function AuthErrorPage() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <ErrorContent />
    </Suspense>
  );
}
```

### Supabase Dashboard Configuration

**CRITICAL: Configure these settings in your Supabase Dashboard**

1. **Authentication → URL Configuration**:
   - Add redirect URLs:
     - Development: `http://localhost:3000/auth/confirm`
     - Production: `https://yourdomain.com/auth/confirm`
   - Add site URL: Your production domain

2. **Authentication → Settings**:
   - JWT expiry: 86400 seconds (24 hours) recommended
   - Enable auto-refresh token: ✅ Checked
   - Refresh token rotation: ✅ Checked (recommended)

3. **Authentication → Email Templates**:
   - Ensure confirmation URL uses: `{{ .SiteURL }}/auth/confirm?token_hash={{ .TokenHash }}&type=email`
   - Ensure magic link uses: `{{ .SiteURL }}/auth/confirm?token_hash={{ .TokenHash }}&type=magiclink`

### Common Anti-Patterns to Avoid

❌ **DON'T: Implement Custom Session Refresh**
```typescript
// BAD - Causes race conditions
const SESSION_CONFIG = {
  refreshThresholdSeconds: 7200,
  maxRefreshAttempts: 3,
};

async function customRefresh(supabase: SupabaseClient) {
  const { data: { session } } = await supabase.auth.getSession();
  if (session && needsRefresh(session)) {
    await supabase.auth.refreshSession();
  }
}
```

❌ **DON'T: Disable Session Detection**
```typescript
// BAD - Breaks auth callbacks
auth: {
  detectSessionInUrl: false, // Don't do this
}
```

❌ **DON'T: Add Code Between Client Creation and getUser()**
```typescript
// BAD - Interferes with automatic refresh
const supabase = createServerClient(...);
await someOtherFunction(); // Don't do this
const { data: { user } } = await supabase.auth.getUser();
```

❌ **DON'T: Manually Check Session Expiry**
```typescript
// BAD - Duplicates Supabase's built-in logic
if (session.expires_at < Date.now() / 1000) {
  await supabase.auth.refreshSession();
}
```

### Best Practices Checklist

✅ **DO: Let Supabase Handle Everything**
- Automatic session refresh
- Token rotation
- Cookie management

✅ **DO: Follow Exact Cookie Patterns**
```typescript
cookies: {
  getAll() {
    return req.cookies.getAll();
  },
  setAll(cookiesToSet) {
    cookiesToSet.forEach(({ name, value, options }) =>
      response.cookies.set(name, value, options)
    );
  },
}
```

✅ **DO: Implement Auth Callback Route**
- Required for email verification
- Required for magic links
- Required for password resets

✅ **DO: Configure Supabase Dashboard Properly**
- Add redirect URLs
- Set appropriate JWT expiry (24 hours recommended)
- Enable auto-refresh token

✅ **DO: Use Proper Error Handling**
```typescript
const { data, error } = await supabase.auth.signInWithPassword({
  email,
  password,
});

if (error) {
  // Handle specific error cases
  if (error.message.includes('Invalid login credentials')) {
    return { error: 'Invalid email or password' };
  }
  return { error: error.message };
}
```

### Session Monitoring and Debugging

**Browser DevTools Inspection**:
1. Open DevTools → Application → Cookies
2. Look for cookies: `sb-<project>-auth-token`
3. Verify attributes:
   - HttpOnly: Yes
   - Secure: Yes (production)
   - SameSite: Lax
   - Max-Age: 86400 (or configured JWT expiry)

**Console Logging (Development Only)**:
```typescript
// Add to middleware for debugging
console.log('User:', user?.id);
console.log('Session expires:', session?.expires_at);
console.log('Cookies:', req.cookies.getAll().map(c => c.name));
```

### Testing Checklist

After implementing authentication, verify:
- [ ] Users can sign up with email
- [ ] Email verification links work
- [ ] Users can log in
- [ ] Sessions persist across page refreshes
- [ ] Sessions persist for configured duration (24 hours)
- [ ] Automatic refresh happens invisibly
- [ ] Protected routes redirect properly
- [ ] Users can log out successfully
- [ ] Password reset flow works
- [ ] Magic link login works (if enabled)

### Performance Considerations

1. **Cookie Size**: Supabase auth tokens are ~500-1000 bytes - acceptable
2. **Middleware Performance**: Simplified middleware adds <10ms overhead
3. **Session Refresh**: Happens automatically before token expires (no user impact)
4. **Client-Side**: Use React Context for user state, not prop drilling

### Security Considerations

1. **Never expose service_role key** to client-side code
2. **Use Row Level Security (RLS)** for all database tables
3. **Validate auth state** server-side for sensitive operations
4. **Implement rate limiting** on auth endpoints
5. **Use HTTPS** in production (always)
6. **Set secure cookie attributes** (handled by Supabase)

### Troubleshooting Common Issues

**Issue: Users logged out every minute**
- ✅ Solution: Follow patterns above (no custom refresh logic)
- ✅ Verify: `detectSessionInUrl: true` in server client
- ✅ Check: Auth callback route exists at `/auth/confirm`

**Issue: Email verification links don't work**
- ✅ Check: Redirect URL configured in Supabase Dashboard
- ✅ Verify: Auth callback route implemented correctly
- ✅ Verify: Email template uses correct URL format

**Issue: Sessions don't persist**
- ✅ Check: Cookie `setAll()` implementation matches pattern
- ✅ Verify: `persistSession: true` in client config
- ✅ Check: Middleware matcher not excluding routes

**Issue: Race conditions during refresh**
- ✅ Solution: Remove all custom refresh logic
- ✅ Verify: No code between `createServerClient` and `getUser()`
- ✅ Check: Using Supabase SSR package (not deprecated auth-helpers)

### Migration from Deprecated Packages

If migrating from `@supabase/auth-helpers-nextjs`:

1. Uninstall old package: `npm uninstall @supabase/auth-helpers-nextjs`
2. Install new package: `npm install @supabase/ssr`
3. Update imports: `@supabase/auth-helpers-nextjs` → `@supabase/ssr`
4. Update client creation: Use `createServerClient` / `createBrowserClient`
5. Update middleware: Follow patterns above
6. Add auth callback route: Required for SSR package
7. Test thoroughly: All auth flows should work

### Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Supabase SSR Package](https://supabase.com/docs/guides/auth/server-side/nextjs)
- [Supabase Server-Side Auth with Next.js App Router](https://supabase.com/docs/guides/auth/server-side/nextjs?router=app&queryGroups=router)
- [Next.js Middleware Documentation](https://nextjs.org/docs/app/building-your-application/routing/middleware)
- [PKCE Flow Specification](https://oauth.net/2/pkce/)

---

## Next.js 16: Middleware Deprecated - Use Proxy Instead

### Breaking Change in Next.js 16

**Next.js 16 deprecates middleware.ts in favor of proxy.ts** for routing and request handling.

**Migration Required:**
- `middleware.ts` → `proxy.ts`
- Updated API and configuration
- See: https://nextjs.org/docs/messages/middleware-to-proxy

### Proxy Configuration

**Create `proxy.ts` in project root:**

```typescript
// proxy.ts
import { NextRequest, NextResponse } from 'next/server';

export function proxy(req: NextRequest) {
  // Your routing logic here
  return NextResponse.next();
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};
```

**Key Differences from Middleware:**
- File name: `proxy.ts` instead of `middleware.ts`
- Export function: `proxy()` instead of `middleware()`
- Same Edge Runtime constraints apply
- Same matcher configuration

### Migration Checklist

- [ ] Rename `middleware.ts` to `proxy.ts`
- [ ] Rename exported function from `middleware` to `proxy`
- [ ] Update imports if referencing middleware elsewhere
- [ ] Test all routing and authentication flows
- [ ] Update documentation and comments

---

## Next.js Middleware & Database Access

### Critical: Edge Runtime Constraints

**Next.js proxy/middleware runs in Edge Runtime**, which has significant limitations compared to Node.js runtime:

- **Edge Runtime**: Limited Node.js APIs, optimized for low latency
- **Node.js Runtime**: Full Node.js APIs (Server Components, Server Actions, API Routes)

### Database Access Strategy

**Prefer Prisma ORM for PostgreSQL projects**, but respect existing project choices:
- If project uses Prisma: Continue with Prisma patterns
- If project uses pure supabase.js: Continue with Supabase client patterns
- For new projects: Default to Prisma ORM unless specified otherwise

### Prisma ORM Cannot Run in Proxy/Middleware

**❌ NEVER use Prisma in Next.js proxy/middleware**

```typescript
// ❌ BAD - This will cause runtime errors
import prisma from '@/lib/prisma';

export async function proxy(req: NextRequest) {
  // This WILL FAIL in Edge runtime
  const user = await prisma.user.findUnique({
    where: { id: userId }
  });
}
```

**Why Prisma doesn't work in proxy/middleware:**
- Prisma requires full Node.js APIs (fs, crypto, etc.)
- Edge runtime only provides a subset of Node.js APIs
- Prisma generates Node.js-specific code that cannot execute in Edge
- Will cause "Module not found" or "Cannot find module" errors

### Use Supabase Direct Database Queries Instead

**✅ DO: Use Supabase's direct table API in proxy/middleware**

```typescript
// ✅ GOOD - Works in Edge runtime
import { createServerClient } from '@supabase/ssr';

export async function proxy(req: NextRequest) {
  const supabase = createServerClient(...);
  
  // Use Supabase direct queries - Edge compatible
  const { data: userRoles } = await supabase
    .from('user_roles')
    .select('role')
    .eq('user_id', userId);
}
```

### Where to Use Each Approach

**Use Prisma (Node.js Runtime):**
- ✅ Server Components (`app/**/page.tsx`)
- ✅ Server Actions (`'use server'` functions)
- ✅ API Routes (`app/api/**/route.ts`)
- ✅ Server-side utilities called from above contexts

**Use Supabase Direct Queries (Edge Runtime):**
- ✅ Proxy/Middleware (`proxy.ts` in Next.js 16+, `middleware.ts` in older versions)
- ✅ Edge API Routes (with `export const runtime = 'edge'`)
- ✅ Any code that needs to run in Edge runtime

### Database Column Naming

**CRITICAL: Mind the naming convention differences:**

```typescript
// Prisma uses camelCase (from schema.prisma @map())
const roles = await prisma.userRole.findMany({
  where: { userId: user.id }  // camelCase
});

// Supabase uses actual database column names (snake_case)
const { data: roles } = await supabase
  .from('user_roles')
  .eq('user_id', user.id);  // snake_case - matches database
```

### Migration Example: Prisma to Supabase in Proxy/Middleware

**Before (Broken):**
```typescript
import prisma from '@/lib/prisma';

const userRoles = await prisma.userRole.findMany({
  where: { userId: user.id },
  select: { role: true }
});

const hasRole = userRoles.some(ur =>
  requiredRoles.includes(ur.role)
);
```

**After (Fixed):**
```typescript
// No Prisma import needed

const { data: userRoles, error } = await supabase
  .from('user_roles')
  .select('role')
  .eq('user_id', user.id);

if (error) {
  logger.error({ error: error.message }, 'Failed to fetch roles');
  return NextResponse.redirect(new URL('/unauthorized', req.url));
}

const hasRole = userRoles?.some(ur =>
  requiredRoles.includes(ur.role)
);
```

### Best Practices for Proxy/Middleware Database Access

1. **Always use Supabase client created in proxy/middleware** - don't import separate instances
2. **Use direct table queries** - `supabase.from('table_name')`
3. **Handle errors explicitly** - Edge runtime errors may differ from Node.js
4. **Use snake_case for column names** - match actual database schema
5. **Keep queries simple** - complex joins may be slower in Edge runtime
6. **Consider caching** - Edge has limited memory, but responses are cached
7. **Test thoroughly** - Edge runtime behavior differs from local Node.js

### Common Pitfalls

❌ **Importing Prisma client in proxy/middleware file**
```typescript
import prisma from '@/lib/prisma'; // Will fail!
```

❌ **Using camelCase for Supabase queries**
```typescript
.eq('userId', id) // Wrong - database uses user_id
```

❌ **Not handling Supabase errors**
```typescript
const { data } = await supabase.from('users').select();
// Missing error handling!
```

❌ **Complex queries with multiple joins**
```typescript
// May be slow or fail in Edge runtime
const { data } = await supabase
  .from('users')
  .select('*, roles(*), organizations(*, members(*))')
```

### Debugging Tips

If you see these errors in proxy/middleware, you're likely using Prisma:
- "Cannot find module '@prisma/client'"
- "Module not found: Can't resolve 'fs'"
- "Cannot find module 'crypto'"
- "PrismaClient is unable to be run in the browser"

**Solution:** Replace Prisma queries with Supabase direct database queries as shown above.

### Reference Documentation

- [Next.js Edge Runtime](https://nextjs.org/docs/app/building-your-application/rendering/edge-and-nodejs-runtimes)
- [Supabase JavaScript Client](https://supabase.com/docs/reference/javascript)
- [Supabase Server-Side Auth (Next.js)](https://supabase.com/docs/guides/auth/server-side/nextjs?router=app&queryGroups=router)

# Python Common Rules

## Python Version

- Use Python 3.9+ (prefer 3.11 or 3.12)
- Avoid Python 2.x for all new development
- Use pyenv for Python version management

## Package and Environment Management

- Prefer uv for fast package management and virtual environments
- Fall back to venv if uv is not available
- Never install packages globally
- Use pyproject.toml for modern dependency management

## Environment Setup with uv

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create project and virtual environment
uv init my-project
cd my-project
uv add package-name
uv run python script.py
```

## Fallback Environment Setup (venv)

```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows
pip install -r requirements.txt
```

## Dependency Management

- Use uv for fast dependency resolution and installation
- Use pip-tools as fallback for dependency pinning
- Separate dev and production dependencies
- Pin exact versions in requirements.txt or use uv.lock

## Code Quality

- Use Black for code formatting
- Use isort for import sorting
- Use flake8 or ruff for linting
- Use mypy for type checking
- Configure pre-commit hooks

## Type Hints

- Use type hints for all functions and methods
- Import types from typing module
- Use Union, Optional, List, Dict appropriately
- Enable strict mypy checking

## Project Structure

```
project/
├── src/
│   └── package/
├── tests/
├── requirements.txt
├── requirements-dev.txt
├── pyproject.toml
├── .gitignore
└── README.md
```

## Documentation

- Use docstrings for all modules, classes, and functions
- Follow Google or NumPy docstring style
- Use Sphinx for documentation generation
- Include type information in docstrings

## Testing

- Use pytest for testing framework
- Write unit tests with descriptive names
- Use fixtures for test data setup
- Implement proper test isolation

## Example Code Style

```python
from typing import List, Optional

def process_users(users: List[dict], active_only: bool = True) -> Optional[List[str]]:
    """
    Process user data and return active user names.

    Args:
        users: List of user dictionaries
        active_only: Filter for active users only

    Returns:
        List of user names or None if no users found
    """
    if not users:
        return None

    filtered_users = [u for u in users if not active_only or u.get('active', False)]
    return [user['name'] for user in filtered_users]
```

## Performance

- Use list comprehensions over loops when appropriate
- Use generators for memory efficiency
- Profile code with cProfile when needed
- Use appropriate data structures (set, dict, list)

---

## Framework-Specific Guidelines

### FastAPI

#### Project Structure

```
src/
├── app/
│   ├── main.py         # FastAPI app configuration
│   ├── server.py       # Local/container server entry point
│   ├── handler.py      # AWS Lambda handler
│   ├── routers/        # API route modules
│   ├── models/         # Pydantic models
│   ├── services/       # Business logic
│   └── dependencies/   # Dependency injection
├── tests/
└── requirements.txt
```

#### Application Architecture

- **main.py**: Export configured FastAPI instance
- **server.py**: Uvicorn server for local/container deployment
- **handler.py**: AWS Lambda handler using Mangum

#### Example Implementation

**main.py**:
```python
from fastapi import FastAPI
from app.routers import users, health

def create_app() -> FastAPI:
    app = FastAPI(
        title="My API",
        version="1.0.0",
        docs_url="/docs"
    )

    app.include_router(health.router)
    app.include_router(users.router, prefix="/api/v1")

    return app

app = create_app()
```

**server.py**:
```python
import uvicorn
from app.main import app

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
```

**handler.py**:
```python
from mangum import Mangum
from app.main import app

handler = Mangum(app, lifespan="off")
```

#### Pydantic Models

- Use Pydantic v2 for request/response models
- Implement proper validation with Field
- Use BaseModel for all data structures
- Separate request and response models

**Example Models**:
```python
from pydantic import BaseModel, Field, EmailStr
from typing import Optional
from datetime import datetime

class UserCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr
    age: int = Field(..., ge=18, le=120)

class UserResponse(BaseModel):
    id: str
    name: str
    email: str
    created_at: datetime
```

#### Best Practices

- Use dependency injection for database connections
- Implement proper error handling with HTTPException
- Use async/await for all route handlers
- Implement request/response validation
- Use background tasks for non-blocking operations

#### Database Integration

- Use SQLAlchemy with async support
- Implement proper connection pooling
- Use Alembic for database migrations
- Create database dependencies for injection

#### Testing

- Use pytest with pytest-asyncio
- Use TestClient for API testing
- Mock external dependencies
- Test both success and error scenarios

#### Security

- Implement proper authentication (JWT, OAuth2)
- Use HTTPS in production
- Validate all input data
- Implement rate limiting
- Use CORS middleware appropriately

#### Performance

- Use async database drivers
- Implement proper caching strategies
- Use connection pooling
- Enable compression middleware
- Profile and optimize slow endpoints

---

### Robyn Framework

#### Framework Overview
- Robyn is a high-performance Python web framework built with Rust
- Async-first design with support for both sync and async handlers
- Built-in WebSocket support and middleware system

#### Project Structure
```
project/
├── main.py              # Application entry point
├── routes/              # Route handlers
├── middleware/          # Custom middleware
├── models/              # Data models
└── requirements.txt     # Dependencies
```

#### Application Setup
- Initialize app with `Robyn(__file__)`
- Use `app.start(host="0.0.0.0", port=8080)` for production
- Enable hot reload in development: `app.start(dev=True)`

#### Route Handlers
- Use decorators: `@app.get()`, `@app.post()`, `@app.put()`, `@app.delete()`
- Prefer async handlers for I/O operations: `async def handler(request)`
- Return Response objects: `Response(status_code=200, headers={}, body="")`
- Access request data: `request.body`, `request.headers`, `request.query_params`

#### Request/Response
- Parse JSON: `request.json()`
- Set response headers: `Response(headers={"Content-Type": "application/json"})`
- Return JSON: serialize with `json.dumps()` or use dict with proper headers
- Handle path parameters: `@app.get("/users/:id")` then `request.path_params["id"]`

#### Middleware
- Define with `@app.before_request()` for pre-processing
- Use `@app.after_request()` for post-processing
- Middleware receives request object and must return it
- Order matters: middleware executes in definition order

#### Error Handling
- Use try-except blocks in handlers
- Return appropriate status codes: 400, 404, 500
- Create custom error responses with Response object
- Log errors for debugging

#### Performance
- Use async handlers for database/API calls
- Leverage Robyn's Rust-based performance
- Minimize blocking operations in handlers
- Use connection pooling for databases

#### WebSockets
- Define with `@app.websocket(route)`
- Handle events: `connect`, `message`, `disconnect`
- Send messages: `websocket.send(message)`
- Broadcast to all: maintain client list and iterate

#### Static Files
- Serve with `app.serve_directory(route="/static", directory_path="./static")`
- Place assets in dedicated directory
- Use absolute paths for directory_path

#### Configuration
- Use environment variables for secrets and config
- Load with `os.getenv()` or python-dotenv
- Separate dev/prod configurations
- Never commit secrets to version control

#### Dependencies
```
robyn
python-dotenv  # For environment variables
```

#### Testing
- Test handlers as regular async functions
- Mock request objects for unit tests
- Use pytest with pytest-asyncio
- Test middleware independently

#### Common Patterns
- Group related routes in separate modules
- Use dependency injection for database connections
- Implement health check endpoint: `@app.get("/health")`
- Version APIs: `/api/v1/resource`

#### Security
- Validate all input data
- Sanitize user-provided content
- Use HTTPS in production
- Implement rate limiting via middleware
- Set security headers (CORS, CSP, etc.)

#### Telemetry & Monitoring
- Use structured logging with `logging` module or `structlog`
- Log request/response via middleware: method, path, status, duration
- Track metrics: request count, response time, error rate
- Implement OpenTelemetry for distributed tracing
- Use Prometheus client for metrics export
- Monitor with `/metrics` endpoint for scraping
- Add correlation IDs to requests for tracing
- Log to stdout/stderr for container environments
- Use log levels appropriately: DEBUG, INFO, WARNING, ERROR
- Include context in logs: user_id, request_id, timestamp

**Metrics to Track**:
- HTTP request duration (histogram)
- Request count by endpoint and status code (counter)
- Active connections (gauge)
- Error rate by type (counter)
- Database query duration (histogram)

**Logging Middleware Example**:
```python
import time
import logging

@app.before_request()
async def log_request(request):
    request.start_time = time.time()
    return request

@app.after_request()
async def log_response(response):
    duration = time.time() - response.request.start_time
    logging.info(f"{response.request.method} {response.request.path} {response.status_code} {duration:.3f}s")
    return response
```

**Dependencies for Telemetry**:
```
prometheus-client  # Metrics
opentelemetry-api  # Tracing
opentelemetry-sdk
structlog          # Structured logging
```

