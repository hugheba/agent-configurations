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
- **quarkus-kotlinx-serialization** - JSON serialization (required for Kotlin)
- **quarkus-hibernate-orm-panache** - Database ORM
- **quarkus-jdbc-postgresql** - PostgreSQL driver
- **quarkus-config-yaml** - YAML configuration
- **quarkus-smallrye-health** - Health checks
- **quarkus-micrometer-registry-prometheus** - Metrics
- **quarkus-smallrye-openapi** - API documentation
- **quarkus-test-h2** - Testing database

## Prohibited Extensions

- **quarkus-resteasy-jackson** - Use kotlinx-serialization instead
- **quarkus-jackson** - Use kotlinx-serialization instead
- Any Jackson-based extensions - Incompatible with optimal native image compilation

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
- Always add default values to data class properties for JSON deserialization when used as REST or GraphQL requests and responses

## Data Classes

- Always provide default values for all properties in data classes used for JSON serialization/deserialization
- This prevents "No default constructor found" errors with JSON-B

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

## Serialization Strategy

### Use kotlinx.serialization (Not Jackson)

- **Always use kotlinx.serialization for all JSON serialization/deserialization**
- **Never use Jackson, GSON, or other reflection-based serializers**
- kotlinx.serialization is compile-time and highly optimized for GraalVM native image
- Jackson requires extensive reflection configuration and increases native image size and build time
- Add `quarkus-kotlinx-serialization` extension to your project

```kotlin
// Required dependency
implementation("io.quarkus:quarkus-kotlinx-serialization")
```

### Serializable Class File Structure

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

## Documentation

- Maintain OpenAPI specifications
- Update README with setup instructions
- Document configuration properties
- Include Docker/native build instructions
