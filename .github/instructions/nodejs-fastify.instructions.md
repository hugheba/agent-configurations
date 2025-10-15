# Node.js Fastify Rules

## Extends

- Follow all rules from `nodejs-common-rules.md`

## Project Structure

```
src/
├── app.ts              # Main Fastify app configuration
├── server.ts           # Local/container server entry point
├── handler.ts          # AWS Lambda handler
├── routes/             # Route definitions
│   ├── index.ts        # Route registration
│   ├── users.ts        # User routes
│   └── health.ts       # Health check routes
├── plugins/            # Custom Fastify plugins
├── schemas/            # JSON schemas for validation
├── services/           # Business logic services
└── types/              # TypeScript type definitions
```

## Application Architecture

- **app.ts**: Export configured Fastify instance
- **server.ts**: Start server for local/container deployment
- **handler.ts**: AWS Lambda handler using @fastify/aws-lambda

## Example Implementation

### app.ts

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

### server.ts

```typescript
import { buildApp } from './app';

const start = async () => {
  const app = buildApp();
  await app.listen({ port: 3000, host: '0.0.0.0' });
};

start();
```

### handler.ts

```typescript
import awsLambdaFastify from '@fastify/aws-lambda';
import { buildApp } from './app';

const app = buildApp();
export const handler = awsLambdaFastify(app);
```

## Best Practices

- Use Fastify plugins for modular architecture
- Implement JSON schema validation for all routes
- Use async/await for all async operations
- Register routes using autoload or manual registration
- Implement proper error handling with error schemas

## Naming Conventions

- Use kebab-case for route paths (`/user-profile`)
- Use camelCase for TypeScript variables and functions
- Use PascalCase for types and interfaces
- Prefix interfaces with 'I' (IUserRequest)

## Validation and Serialization

- Use Zod for request/response validation
- Convert Zod schemas to JSON schemas for Fastify
- Use Fastify's built-in serialization
- Implement custom error responses
- Validate environment variables on startup

## Zod Validation Example

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

## Performance

- Enable Fastify's built-in compression
- Use connection pooling for databases
- Implement proper caching strategies
- Configure appropriate timeouts
