# Authentication Instructions

## Supabase Authentication Integration
- Use Supabase Auth for user authentication
- Implement proper session management with Supabase
- Follow OAuth best practices for social logins

## CRITICAL: Schema Management
- **NEVER modify built-in Supabase schemas** (auth, storage, realtime, etc.) via external SQL or ORMs
- **DO NOT** alter tables, indexes, or constraints in auth.* schemas
- Built-in schemas are managed by Supabase and modifications will break functionality
- Only interact with auth.users through Supabase Auth APIs, never direct SQL modifications
- Create custom tables in the public schema or custom schemas for application data

## Auth Patterns
- Protect routes using middleware with Supabase auth checks
- Implement role-based access control using custom permissions
- Store user data in the auth.users table (managed by Supabase)
- Store custom user metadata in raw_user_meta_data JSONB field
- Handle authentication errors gracefully

## Example auth setup:
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
