# .NET Common Rules

## .NET Version

- Use .NET 8+ (LTS) or .NET 9+ for new projects
- Target modern .NET (not .NET Framework)
- Use latest C# language version (C# 12+)
- Enable nullable reference types

## Project Structure

```
src/
├── MyApp.Api/          # Web API project
├── MyApp.Core/         # Business logic
├── MyApp.Infrastructure/ # Data access
└── MyApp.Tests/        # Test projects
```

## Language Features

- Use modern C# features (records, pattern matching, init-only properties)
- Prefer async/await over synchronous operations
- Use nullable reference types with proper annotations
- Leverage minimal APIs for simple endpoints

## Code Quality

- Use EditorConfig for consistent formatting
- Enable code analysis with .editorconfig
- Use StyleCop or similar for style enforcement
- Configure warnings as errors for critical issues

## Dependency Injection

- Use built-in DI container
- Register services with appropriate lifetimes
- Use IOptions pattern for configuration
- Implement proper service abstractions

## Configuration

- Use appsettings.json with environment overrides
- Implement strongly-typed configuration with IOptions
- Use user secrets for development
- Use environment variables for production secrets

## Example Configuration

```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.Services.Configure<DatabaseOptions>(
    builder.Configuration.GetSection("Database"));

builder.Services.AddScoped<IUserService, UserService>();

var app = builder.Build();
```

## Error Handling

- Use global exception handling middleware
- Implement proper logging with ILogger
- Use Result patterns for business logic errors
- Return appropriate HTTP status codes

## Testing

- Use xUnit for unit testing
- Use NSubstitute or Moq for mocking
- Write integration tests with WebApplicationFactory
- Use Testcontainers for database testing

## Performance

- Use async/await throughout the application
- Implement proper caching strategies
- Use memory-efficient collections
- Profile with dotMemory or PerfView

## Documentation

- Use XML documentation comments
- Generate API documentation with Swagger/OpenAPI
- Document public APIs comprehensively
- Include code examples in documentation

## Example XML Documentation

```csharp
/// <summary>
/// Retrieves user information by identifier
/// </summary>
/// <param name="userId">The unique user identifier</param>
/// <param name="cancellationToken">Cancellation token</param>
/// <returns>User information if found</returns>
/// <exception cref="UserNotFoundException">When user doesn't exist</exception>
public async Task<User?> GetUserAsync(Guid userId, CancellationToken cancellationToken = default)
{
    // Implementation
}
```

## Security

- Use HTTPS everywhere
- Implement proper authentication (JWT, Identity)
- Validate all input data
- Use parameterized queries to prevent SQL injection
- Enable security headers
