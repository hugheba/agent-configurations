# General Documentation Rules

## Project Documentation Requirements

- Every project must be properly documented
- Keep README.md current and comprehensive
- Document all setup, development, testing, and deployment procedures
- Include troubleshooting and FAQ sections

## README.md Structure

- **Project Overview**: Purpose and key features
- **Prerequisites**: Required tools and versions
- **Checkout**: Git clone and initial setup instructions
- **Development**: Local development environment setup
- **Testing**: How to run unit and integration tests
- **Running**: How to start the application locally
- **Deployment**: Manual deployment and GitLab CI/CD instructions
- **Configuration**: Environment variables and settings
- **Contributing**: Development guidelines and standards

## Approved Documentation Libraries

- **JavaScript/TypeScript**: JSDoc
- **Java**: JavaDoc
- **Kotlin**: KDoc
- **Python**: pydoc, Sphinx
- **C#/.NET**: XML Documentation Comments
- **Go**: godoc
- **Rust**: rustdoc

## Code Documentation Standards

- Document all public APIs (files, classes, methods, functions)
- Include parameter descriptions and return values
- Document exceptions and error conditions
- Provide usage examples for complex functions
- Keep documentation synchronized with code changes

## Documentation Format Examples

### JSDoc (JavaScript/TypeScript)

```javascript
/**
 * Calculates user permissions based on role
 * @param {string} userId - The user identifier
 * @param {string} role - User role type
 * @returns {Promise<Permission[]>} Array of user permissions
 * @throws {AuthorizationError} When user lacks access
 */
```

### JavaDoc/KDoc (Java/Kotlin)

```java
/**
 * Processes payment transaction
 * @param amount Transaction amount in cents
 * @param currency ISO currency code
 * @return Transaction result with status
 * @throws PaymentException When payment fails
 */
```

### XML Documentation (.NET)

```csharp
/// <summary>
/// Validates user input data
/// </summary>
/// <param name="input">User input to validate</param>
/// <returns>True if valid, false otherwise</returns>
/// <exception cref="ValidationException">Thrown when validation fails</exception>
```

## Documentation Generation

- Generate source code documentation using language-specific tools
- Publish generated documentation to GitLab Pages
- Automate documentation generation in CI/CD pipeline
- Keep generated documentation current with each release

## Generation Tools by Language

- **JavaScript/TypeScript**: JSDoc → HTML
- **Java**: JavaDoc → HTML
- **Kotlin**: Dokka → HTML
- **Python**: Sphinx, pydoc → HTML
- **C#/.NET**: DocFX, Sandcastle → HTML
- **Go**: godoc → HTML
- **Rust**: rustdoc → HTML

## Maintenance

- Review and update documentation during code reviews
- Validate documentation accuracy during releases
- Remove outdated documentation promptly
