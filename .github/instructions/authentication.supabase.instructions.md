# Authentication Instructions

## Supabase Authentication Integration
- Use Supabase Auth for user authentication
- Implement proper session management with Supabase
- Follow OAuth best practices for social logins

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
