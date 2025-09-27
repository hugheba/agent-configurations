# Quarkus Kotlin REST and GraphQL Endpoints Guide

## Overview

This guide covers creating REST and GraphQL endpoints in Quarkus with Kotlin, including when to combine them and when to separate them.

## Dependencies

Add to `build.gradle.kts`:

```kotlin
implementation("io.quarkus:quarkus-smallrye-graphql")
implementation("io.quarkus:quarkus-rest-kotlin-serialization")
```

Also ensure Kotlin serialization plugin is enabled:

```kotlin
plugins {
    kotlin("plugin.serialization") version "2.2.10"
}
```

## Data Models

### Service Layer Models (Shared)
Use Kotlin data classes with immutable properties for internal business logic:

```kotlin
import kotlinx.serialization.Serializable

@Serializable
data class User(
    val id: String,
    val name: String,
    val email: String
)

@Serializable
data class CreateUserRequest(
    val name: String,
    val email: String
)
```

### GraphQL Input Types (Separate)
**CRITICAL**: GraphQL input types must use regular classes with mutable properties:

```kotlin
@Input
class CreateUserInput {
    var name: String = ""
    var email: String = ""
}
```

**Why separate GraphQL inputs are required:**
- SmallRye GraphQL requires mutable properties (`var`) for field detection
- Kotlin data classes with `val` properties are not properly introspected
- Complex annotations (`@field:Name`, `@SerialName`) interfere with GraphQL schema generation
- GraphQL validation fails with "must define one or more fields" if properties aren't detected

## Approach 1: Combined REST and GraphQL (Recommended for Simple Cases)

Use when operations are identical and input/output types are simple.

```kotlin
@Path("/users")
@GraphQLApi
class UserResource {

    @Inject
    lateinit var userService: UserService

    // Combined REST and GraphQL query
    @GET
    @Query("users")
    fun getUsers(): List<User> = userService.getAllUsers()

    // Separate endpoints due to different input requirements
    @POST
    fun createUserRest(request: CreateUserRequest): User {
        return userService.createUser(request.name, request.email)
    }

    @Mutation("createUser")
    fun createUserGraphQL(@Name("input") input: CreateUserInput): User {
        return userService.createUser(input.name, input.email)
    }
}
```

## Approach 2: Separate REST and GraphQL (Recommended for Complex Cases)

Use when:
- Different validation requirements
- Complex input transformations needed
- Different error handling
- Different security requirements

### REST Resource
```kotlin
@Path("/users")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
class UserRestResource {

    @Inject
    lateinit var userService: UserService

    @GET
    fun getUsers(): List<User> = userService.getAllUsers()

    @POST
    fun createUser(request: CreateUserRequest): User {
        return userService.createUser(request.name, request.email)
    }
}
```

### GraphQL Resource
```kotlin
@GraphQLApi
class UserGraphQLResource {

    @Inject
    lateinit var userService: UserService

    @Query("users")
    fun getUsers(): List<User> = userService.getAllUsers()

    @Mutation("createUser")
    fun createUser(@Name("input") input: CreateUserInput): User {
        return userService.createUser(input.name, input.email)
    }
}
```

## Decision Matrix

| Scenario | Approach | Reason |
|----------|----------|---------|
| Simple CRUD operations | Combined | Less code duplication |
| Different input validation | Separate | Different validation logic |
| Complex transformations | Separate | Cleaner separation of concerns |
| Different security models | Separate | Different auth requirements |
| Different error handling | Separate | Protocol-specific error responses |
| Native image compilation | Separate | Better reflection optimization |

## GraphQL Input Type Requirements

### ✅ Correct GraphQL Input
```kotlin
@Input
class UserInput {
    var name: String = ""
    var email: String = ""
    var age: Int = 0
}
```

### ❌ Incorrect GraphQL Input
```kotlin
// Will cause "must define one or more fields" error
@Input
data class UserInput(
    val name: String = "",
    val email: String = ""
)

// Will cause field detection issues
@Input
data class UserInput(
    @field:Name("userName") val name: String = "",
    @SerialName("userEmail") val email: String = ""
)
```

## Best Practices

### 1. Service Layer Pattern
Keep business logic in services, use resources only for protocol handling:

```kotlin
@ApplicationScoped
class UserService {
    fun createUser(name: String, email: String): User {
        // Business logic here
        return User(UUID.randomUUID().toString(), name, email)
    }
}
```

### 2. Input Conversion
Convert GraphQL inputs to service models:

```kotlin
@Mutation("createUser")
fun createUser(@Name("input") input: CreateUserInput): User {
    val request = CreateUserRequest(
        name = input.name,
        email = input.email
    )
    return userService.createUser(request)
}
```

### 3. Error Handling
Use different error handling for each protocol:

```kotlin
// REST - HTTP status codes
@POST
fun createUser(request: CreateUserRequest): Response {
    return try {
        val user = userService.createUser(request)
        Response.ok(user).build()
    } catch (e: ValidationException) {
        Response.status(400).entity(e.message).build()
    }
}

// GraphQL - GraphQL errors
@Mutation("createUser")
fun createUser(@Name("input") input: CreateUserInput): User {
    // GraphQL automatically handles exceptions as GraphQL errors
    return userService.createUser(input.name, input.email)
}
```

## Native Image Considerations

For GraalVM native image compilation:
- Prefer separate resources for better reflection optimization
- Avoid complex annotations on GraphQL input types
- Use simple class structures for GraphQL inputs

## Testing

### REST Testing
```kotlin
@QuarkusTest
class UserRestResourceTest {
    @Test
    fun testCreateUser() {
        given()
            .contentType(ContentType.JSON)
            .body("""{"name":"John","email":"john@example.com"}""")
        .`when`()
            .post("/users")
        .then()
            .statusCode(200)
    }
}
```

### GraphQL Testing
```kotlin
@QuarkusTest
class UserGraphQLResourceTest {
    @Test
    fun testCreateUser() {
        val query = """
            mutation {
                createUser(input: {name: "John", email: "john@example.com"}) {
                    id
                    name
                    email
                }
            }
        """
        
        given()
            .contentType(ContentType.JSON)
            .body("""{"query":"$query"}""")
        .`when`()
            .post("/graphql")
        .then()
            .statusCode(200)
    }
}
```

## Summary

- **Use combined approach** for simple, identical operations
- **Use separate approach** for complex scenarios or different requirements
- **Always use regular classes with `var` properties** for GraphQL inputs
- **Keep business logic in services**, not in resource classes
- **Test both protocols** independently
