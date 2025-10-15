---
applyTo: '**'
---

# Node.js React Rules

## Extends

- Follow all rules from `nodejs-common-rules.md`
- Use the context7 tool with id `/builderio/builder` for latest Builder.io documentation

## Stack Requirements

- Use Next.js 15+ with App Router (no legacy Pages Router)
- Use React 18+ with Server Components by default
- Use TypeScript in strict mode
- Use TailwindCSS as primary styling utility with Shadcn/UI and Radix Themes
- Target modern evergreen browsers
- Use ESM everywhere (`"type": "module"`)

## Project Structure (Next.js App Router)

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

## React Server vs Client Components

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

## Data Fetching & Caching

- Use fetch() in Server Components with proper caching strategies
- Use `cache: 'force-cache'` for static data
- Use `cache: 'no-store'` for dynamic data
- Implement ISR with revalidate tags/time
- Use Route Handlers (app/api) instead of legacy pages/api
- Co-locate server actions near form components
- Use tag-based revalidation for selective cache busting
- Use TanStack Query or SWR only for client-side real-time data
- Prefer incremental static regeneration (ISR) via revalidate or tag invalidation; minimize fully dynamic routes unless required
- Wrap external fetchers in lib/ with consistent error mapping; never leak raw HTTP layer details to components
- Ensure server actions are idempotent where possible
- Do not block rendering with artificial awaits; parallelize fetches

## Component Best Practices

- Use TypeScript for all components with proper interfaces
- Implement single responsibility principle
- Use React hooks appropriately (useState, useEffect, useCallback)
- Use React.memo only when profiling shows benefit
- Follow proper prop typing patterns

## Performance Optimization

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

## Styling with TailwindCSS

- Use design tokens via @layer base and theme config
- Create semantic wrapper components instead of repeating classes
- Use clsx for conditional classes
- Keep globals.css minimal (resets, variables only)
- Configure consistent dark mode strategy
- Ensure proper purge configuration

## State Management

- Use useState/useReducer for local state
- Use Zustand or Jotai for lightweight cross-component state
- Prefer server state hydration over heavy client state libraries
- Avoid Redux unless complex cross-cutting concerns justify it

## Forms & Validation

- Use react-hook-form for complex forms
- Use Zod for schema validation with TypeScript inference
- Validate on both client and server (never trust client only)
- Implement accessible error messages with aria-live

## Accessibility Requirements

- Use semantic HTML elements first (button, nav, header, main)
- Use Radix UI primitives for complex widgets
- Ensure keyboard accessibility for all interactive elements
- Provide proper alt text, aria-labels, and heading hierarchy
- Meet WCAG AA color contrast requirements
- Validate with automated tooling

## Error & Loading States

- Use loading.tsx and error.tsx for route segments
- Implement proper Error Boundaries
- Create fast skeleton UIs, avoid spinner-only states
- Use not-found.tsx for 404 handling
- Surface user-friendly error messages
- Log detailed errors server-side only

## Security Best Practices

- Validate all inputs with Zod in route handlers and server actions
- Sanitize HTML content, avoid dangerouslySetInnerHTML
- Set proper security headers via middleware
- Only expose NEXT_PUBLIC_ prefixed environment variables
- Never leak sensitive data to client logs

## Testing Strategy

- Use Jest/Vitest and React Testing Library for unit tests
- Use Playwright for integration and accessibility tests
- Mock network requests with MSW
- Focus on behavior testing, not implementation details
- Enforce coverage thresholds
- Test custom hooks separately

## Approved Libraries

- Core: next, react, react-dom
- Styling: tailwindcss, postcss, autoprefixer, clsx
- UI: @radix-ui/react-*, lucide-react
- State: zustand or jotai (if needed)
- Forms: react-hook-form, zod
- Data: @tanstack/react-query or swr
- Testing: @testing-library/react, playwright, msw
- Animation: framer-motion (use sparingly)

## Deployment (AWS Amplify)

- Target AWS Amplify Hosting with Next.js support
- Use immutable build artifacts
- Configure environment variables in Amplify console
- Enable dependency caching in amplify.yml
- Set proper security headers
- Monitor bundle size budgets in CI

## Example amplify.yml

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

## Internationalization (if used)
- Use Next.js built-in i18n routing or lightweight library; avoid runtime-only heavy libs.
- Load translation dictionaries server-side, pass minimal subset to client.

## Images / Media
- Always use next/image for dynamic optimization unless exact 1:1 needed from public/.
- Provide width/height to prevent layout shift.
- Use modern formats (AVIF/WebP) via automatic conversion.

## Logging & Observability
- Client: minimal logging (development only); sensitive data never logged.
- Use web-vitals (reportWebVitals) to send metrics (e.g., to an analytics endpoint).
- Server errors mapped; no stack traces surfaced to user.

## Styling Alternatives
- Prefer Tailwind; CSS Modules only for rare complex cascade or third-party overrides.
- No SCSS unless legacy; avoid CSS-in-JS runtime solutions (styled-components) unless critical (adds bundle/runtime cost).

## Naming & Components
- File names: kebab-case or PascalCase for components; consistent choice documented (prefer PascalCase for component files).
- Named exports for components; index.ts barrels sparingly to avoid tree-shaking impediments.
- Avoid default exports except Next.js route segment (layout.tsx, page.tsx) and configuration files.

## Environment & Config
- next.config.mjs: keep minimal; document experimental flags.
- Distinguish runtime vs build-time configuration; avoid dynamic require.
- Feature flags: simple module returning typed config; optionally integrate with remote flags (lazy loaded).

## Migration / Deprecation
- Mark deprecated components with clear JSDoc @deprecated and link to replacement.
- Remove unused feature flags / dead routes promptly.

## Example Component Pattern

```typescript
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
    <div className="rounded-lg border bg-card p-4 shadow-sm">
      <h3 className="text-lg font-semibold">{user.name}</h3>
      <p className="text-sm text-muted-foreground">{user.email}</p>
      {onEdit && (
        <button
          onClick={handleEdit}
          className="mt-2 rounded bg-primary px-3 py-1 text-primary-foreground hover:bg-primary/90"
        >
          Edit
        </button>
      )}
    </div>
  );
}
```

## Prohibited Patterns

- Large date/time libraries (use native Date or date-fns)
- Client-side rendering entire pages when SSR/SSG suffices
- Global mutable singletons without justification
- Unbounded polling (prefer server-sent events)
- Heavy UI component libraries without ADR justification
- CSS-in-JS runtime solutions (adds bundle cost)
