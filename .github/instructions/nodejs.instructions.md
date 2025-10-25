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
- Immutable Docker images: multi-stage build, user non-root, minimal base (e.g. distroless/node or alpine with care).

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
- Use Next.js 15+ with App Router (no legacy Pages Router)
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

