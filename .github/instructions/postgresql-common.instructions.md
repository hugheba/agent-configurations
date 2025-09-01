---
applyTo: '**'
---
# PostgreSQL Instructions

## Version & Hosting
- Target PostgreSQL 18+ (enable new planner, performance, SQL features).
- Preferred managed providers: Neon (branching, autoscaling) > Supabase (auth, storage, edge functions) when integrated platform desired.
- Enforce minimum server_version in migration bootstrap.
- Leverage modern PostgreSQL features (JSONB, CTEs, window functions)
- Keep PostgreSQL updated to latest stable version

## Core Usage Modes
1. Traditional RDBMS (normalized OLTP).
2. Semi‑structured NoSQL via JSONB (selective schema flexibility).
3. Vector similarity (pgvector) for embeddings / hybrid search.
4. Geospatial (PostGIS) for location, distance, routing enrichment.
5. Durable lightweight message queue (pgmq) replacing RabbitMQ for moderate throughput.
6. Time‑series (TimescaleDB for compression + continuous aggs; cstore_fdw for columnar analytical append-only).
7. Consolidated persistence to reduce operational sprawl (avoid polyglot unless justified).

## Essential Extensions (enable explicitly per DB)
- pgvector
- postgis, postgis_topology
- pgmq
- timescaledb
- cstore_fdw (analytical cold data)
- hstore (legacy key/value; prefer JSONB unless index density requires)
- citext (case-insensitive text)
- ltree (hierarchical paths)
- pg_trgm (trigram similarity / fast ILIKE)
- btree_gin / btree_gist (composite index flexibility)
- uuid-ossp or gen_random_uuid() (pgcrypto) for UUIDs
- pg_stat_statements (query insights)
- pg_cron (scheduled maintenance / TTL cleanup)
Only load what is used (lean shared_preload_libraries).

## Database Design

- Use proper normalization (3NF minimum); denormalize only for measured read hot paths
- Implement foreign key constraints (FK, CHECK, UNIQUE) — never rely solely on application logic
- Use appropriate data types (UUID, JSONB, arrays)
- Follow consistent naming conventions (snake_case)
- Use BIGINT / UUID primary keys (avoid SERIAL for portability)
- Store immutable events (append-only) separately from mutable aggregates
- Partition large fact/time-series tables (native RANGE by time, hash for hotspots)
- Prefer narrow tables; isolate large JSONB/text blobs to side tables if sparse

## JSONB (Flexible Documents)
- Use when attribute set is:
  - Sparse / user-defined
  - Evolving faster than schema
- Still index frequently queried keys (GIN jsonb_path_ops or expression indexes).
- Promote stable keys to typed columns when:
  - Frequently filtered / joined
  - Require constraints or statistics for planner
- Avoid deeply nested polymorphic shapes; maintain a version field.

## Vector Search (pgvector)
- Use for semantic similarity (embeddings: text, images).
- Schema:
  - dimension INT CHECK
  - embedding vector(n)
  - metadata JSONB (optional)
- Index types:
  - ivfflat for large kNN; requires ANALYZE after load
  - hnsw (if available in installed pgvector build) for higher recall
- Maintain separate table for embeddings; reference parent entity via FK.
- Rebuild / refresh embeddings asynchronously; store model version.
- Use hybrid search: lexical (tsvector / trigram) + vector score (rerank).

## Geospatial (PostGIS)
- Geometry type unless geography required (global distance accuracy).
- Create GiST / SP-GiST indexes on geometry/geography.
- Normalize SRID (e.g., 4326) and enforce via CHECK ST_SRID(col)=4326.
- For bounding box + distance: combine && operator + ST_DWithin.
- Precompute centroids / simplified geometries for map display (ST_Simplify).

## Messaging (pgmq)
- Use for:
  - Low/medium throughput task dispatch
  - Exactly-once or at-least-once semantics with visibility timeouts
- Avoid for extremely high fan-out or streaming (then switch to Kafka).
- Tune:
  - Visibility timeout < typical worker SLA
  - Dead-letter queue for retries exhaustion
- Monitor queue depth & latency via pgmq introspection tables.

## Time-Series
- TimescaleDB:
  - Hypertables (time, optional space dimension)
  - Compression for historical chunks; policy jobs
  - Continuous aggregates for rollups; refresh policies
- cstore_fdw:
  - Cold analytical append-only segments; ETL from OLTP tables
  - Avoid high-churn writes; batch load
- Partition retention policies to drop aged data safely (pg_cron scheduled).

## Caching / Redis Replacement Strategy
- Short-lived computed views: MATERIALIZED VIEW + refresh policy (when staleness tolerated).
- Key/value ephemeral:
  - hstore or JSONB + GIN index + TTL column + scheduled DELETE (pg_cron)
- Case-insensitive lookups: citext eliminates LOWER() index duplication.
- Hierarchical tagging / feature flags: ltree for path traversal & subtree queries.
- Avoid abusing DB for extremely high-frequency ephemeral counters; if contention appears, reconsider dedicated cache.

## Indexing Strategy

- Always justify each index (read vs write cost)
- Create indexes based on actual query patterns
- Use composite indexes for multi-column queries; order by selectivity + usage
- Implement partial indexes for filtered queries (WHERE active = true) to shrink hot sets
- Use expression indexes for computed values
- For JSONB: expression indexes ( (data->>'status') ) or GIN (jsonb_path_ops)
- Prefer covering multicolumn indexes over numerous single-column ones

## Index Types and Usage

```sql
-- B-tree (default) - equality and range queries
CREATE INDEX idx_users_email ON users(email);

-- Composite index - multi-column queries
CREATE INDEX idx_orders_user_date ON orders(user_id, created_at);

-- Partial index - filtered queries
CREATE INDEX idx_active_users ON users(email) WHERE active = true;

-- GIN index - JSONB and full-text search
CREATE INDEX idx_user_metadata ON users USING GIN(metadata);

-- Hash index - equality only (PostgreSQL 10+)
CREATE INDEX idx_user_status ON users USING HASH(status);
```

## Query Optimization

- Use EXPLAIN ANALYZE for query performance analysis
- Avoid SELECT \* in production queries
- Use appropriate JOIN types (INNER, LEFT, etc.)
- Implement proper WHERE clause ordering
- Use LIMIT for pagination queries

## Performance Best Practices

- Set appropriate work_mem and shared_buffers
- Use connection pooling (PgBouncer, built-in pooling)
- Implement query result caching
- Monitor slow query logs
- Use prepared statements to prevent SQL injection
- VACUUM (auto) tuning:
  - autovacuum_vacuum_scale_factor low for bloat-prone tables
  - Monitor pg_stat_all_tables.dead_tuples
- Analyze after bulk loads; keep default_statistics_target higher (e.g., 200) for skewed columns
- Use prepared statements / query parameterization (reduces plan churn)
- Benchmark with EXPLAIN (ANALYZE, BUFFERS), track plan regressions in CI (optional)

## Transactions & Concurrency
- Default isolation: READ COMMITTED; escalate to SERIALIZABLE only when anomaly proven.
- Short transactions; avoid open idle in transaction sessions.
- Use optimistic concurrency with version / xmin if update contention detected.
- For queue consumers: ack via UPDATE / DELETE inside single transaction per message.

## Migrations
- Tooling: declarative versioned migrations (Flyway or Prisma migrate for Node stack).
- One migration per logical change, immutable post-merge.
- Zero-downtime patterns:
  - Add columns NULLable -> backfill -> set NOT NULL
  - Create new index CONCURRENTLY
  - Avoid long exclusive locks (ALTER TYPE ADD VALUE vs recreating)
- Store migration checksum audit table; block startup if drift.

## Data Types

- Use UUID for primary keys when needed
- Use JSONB over JSON for better performance
- Use appropriate numeric types (INTEGER, BIGINT, DECIMAL)
- Use TEXT over VARCHAR unless length constraint needed

## Connection Management
- Use pooled connections (e.g., PgBouncer in transaction pooling) especially with serverless clients.
- Keep max_connections low; rely on pool sizing (rule of thumb: 2–4 * CPU cores backend).
- Avoid long-lived idle sessions to reduce memory footprint.

## Example Optimized Queries

```sql
-- Good: Specific columns with proper indexing
SELECT id, name, email
FROM users
WHERE active = true
  AND created_at >= '2024-01-01'
ORDER BY created_at DESC
LIMIT 20;

-- Good: Using JSONB operators with GIN index
SELECT * FROM products
WHERE metadata @> '{"category": "electronics"}';

-- Good: Efficient pagination
SELECT * FROM orders
WHERE created_at > $1
ORDER BY created_at
LIMIT 20;
```

## Monitoring and Maintenance

- Monitor query performance with pg_stat_statements
- Run VACUUM and ANALYZE regularly
- Monitor database size and growth
- Set up alerts for connection limits and slow queries
- Enable pg_stat_statements; sample slow queries > threshold.
- Capture:
  - Throughput (tx/s)
  - Cache hit ratio
  - Active vs waiting connections
  - Replication lag
  - Bloat metrics (pgstattuple)
  - Autovacuum activity
- Log settings:
  - log_min_duration_statement = value (e.g., 250ms) in production
  - log_line_prefix includes %m %p %u %d %r %a
- Use logical replication slots sparingly; monitor slot confirmed_lsn to avoid WAL bloat.

## Security

- Use least privilege principle for database users
- Implement row-level security when needed
- Use SSL/TLS for connections
- Regularly update PostgreSQL for security patches
- Principle of least privilege: separate role for app writer, reader, migrator.
- Enforce TLS, SCRAM auth; no trust/MD5.
- Row-level security (RLS) for multi-tenant tables; policy audited in tests.
- Restrict extension creation to superuser; pre-enable only needed set.
- Periodic dependency / CVE scan for managed provider (verify vendor patches).
- Use pgcrypto or external KMS for sensitive column encryption (application-layer envelope preferred).

## Backup and Recovery

- Implement automated backups with pg_dump or pg_basebackup
- Test backup restoration procedures
- Use point-in-time recovery for critical systems
- Store backups in separate locations
- Point-in-time recovery (PITR) with WAL archiving (validate restore regularly).
- Verify backups with checksum + periodic test restore pipeline.
- For multi-region: async physical replica; tolerate small lag; promote with documented runbook.

## Data Lifecycle
- Classify tables (hot, warm, cold); apply:
  - Compression (Timescale)
  - Archival to object storage (COPY) for very cold partitions
- TTL cleanup jobs for ephemeral tables (pg_cron scheduling).

## Testing & CI
- Spin ephemeral Neon branches for integration tests or use Testcontainers with official Postgres 18 image + required extensions.
- Seed minimal deterministic data; no production dumps.
- Validate migrations forward + rollback (where safe) in CI.

## Governance
- Document every enabled extension (purpose, owner).
- ADR for adopting / removing external data stores vs PostgreSQL consolidation.
- Periodic review of unused indexes & extensions.

## When NOT to Extend PostgreSQL
- Ultra high throughput ephemeral caching (sub-millisecond, massive key churn)
- Large-scale event streaming (Kafka/Kinesis class)
- Specialized vector workloads requiring GPU acceleration (then external vector DB)

## Query Review Checklist
- Parameterized?
- Uses correct index?
- Avoids sequential scan on large table (unless justified)?
- Bounded result set (LIMIT / pagination)?
- No N+1 (prefer set-based operators / JOIN / LATERAL)?
