---
applyTo: '**'
---

# Node.js Common Instructions
## General Guidelines
- Always use TypeScript (no new JavaScript source files).
- Target current LTS Node.js; prefer ESM (`"type": "module"` in package.json).
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
- HTTP server: fastify (preferred) or express (legacy only).
- HTTP client (if richer than fetch needed): undici.
- Task scheduling / queues: bullmq (Redis-backed) when required.
- Database (if using PostgreSQL): pg + drizzle-orm or prisma (choose one).
- Caching: ioredis.
- UUIDs: uuid (v7 when available).
Unapproved: moment, request, deprecated or unmaintained packages.

## TypeScript Conventions
- Use path aliases via tsconfig `paths` instead of deep relative imports.
- Export types separately when helpful (`export type { Foo }`).
- Narrow unknown/any at boundaries only; forbid implicit any.
- Prefer readonly for immutable shapes; use `as const` intentionally.
- Avoid enums; use union string literals + type guards.

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
- Immutable Docker images: multi-stage build, user non-root, minimal base (e.g. distroless/node or alpine with care).

## Code Review Checklist (abbreviated)
- Clear responsibility? Test coverage adequate?
- No TODO without linked issue.
- No secret values / credentials in code.
- Proper error handling and logging added?
- Types strict, no any leaks?
