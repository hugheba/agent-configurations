# Prisma ORM Instructions

## Database Operations

- All SQL operations MUST be performed through the Prisma schema and Prisma Client
- Never write raw SQL queries directly - use Prisma's type-safe query API
- Database schema changes MUST be made through Prisma migrations

## Schema Management

- Define all models in `prisma/schema.prisma`
- Use `npx prisma migrate dev` for development migrations
- Use `npx prisma migrate deploy` for production deployments
- Run `npx prisma generate` after schema changes to update Prisma Client

## Query Patterns

- Use Prisma Client methods: `findMany`, `findUnique`, `create`, `update`, `delete`, `upsert`
- Leverage Prisma's relation queries instead of manual joins
- Use transactions with `prisma.$transaction()` for atomic operations

## Best Practices

- Always regenerate Prisma Client after schema modifications
- Use Prisma Studio (`npx prisma studio`) for database inspection
- Validate schema with `npx prisma validate`
- Format schema with `npx prisma format`
