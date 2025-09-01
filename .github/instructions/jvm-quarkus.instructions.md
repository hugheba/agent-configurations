# JVM Quarkus Rules

## Extends

- Follow all rules from `jvm-common-rules.md`

## Language & Build

- **Kotlin** preferred over Java
- **Gradle** with Kotlin DSL over Maven
- Target native image compilation
- Configure for containerization (Docker/Podman)

## Configuration

- Use YAML configuration files (`application.yml`) over `application.properties`
- Separate configs by profile (dev, test, prod)
- Use environment variables for sensitive data

## Approved Quarkus Extensions

- **quarkus-resteasy-reactive** - REST endpoints
- **quarkus-hibernate-orm-panache** - Database ORM
- **quarkus-jdbc-postgresql** - PostgreSQL driver
- **quarkus-config-yaml** - YAML configuration
- **quarkus-smallrye-health** - Health checks
- **quarkus-micrometer-registry-prometheus** - Metrics
- **quarkus-smallrye-openapi** - API documentation
- **quarkus-test-h2** - Testing database

## Testing Requirements

- Write unit tests for all business logic
- Create integration tests for REST endpoints
- Use `@QuarkusTest` for integration tests
- Test database operations with test containers

## REST API Example

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

## Best Practices

- Use Panache repositories for database operations
- Implement proper error handling with exception mappers
- Add health checks for external dependencies
- Configure native image hints for reflection
- Use CDI for dependency injection
- Keep REST resources thin, delegate to services

## Documentation

- Maintain OpenAPI specifications
- Update README with setup instructions
- Document configuration properties
- Include Docker/native build instructions
