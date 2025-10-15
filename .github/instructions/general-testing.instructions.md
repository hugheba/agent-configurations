# General Testing Rules

## Testing Requirements

- All projects must have comprehensive test coverage
- Implement unit, integration, and end-to-end tests
- Use Katalon for automated UI/API testing where applicable
- Strive for above 80% code coverage
- Write tests alongside feature development

## Test Types

- **Unit Tests**: Test individual components in isolation
- **Integration Tests**: Test component interactions
- **End-to-End Tests**: Test complete user workflows
- **Katalon Tests**: Automated UI and API testing

## Approved Testing Tools by Language

### Java/Kotlin

- **Unit Testing**: JUnit 5, TestNG
- **Mocking**: Mockito, MockK (Kotlin)
- **Integration**: Testcontainers
- **Coverage**: JaCoCo

### JavaScript/TypeScript/Node.js

- **Unit Testing**: Jest, Vitest
- **Mocking**: Jest mocks, Sinon.js
- **Integration**: Supertest, Testcontainers
- **Coverage**: Istanbul, c8

### Python

- **Unit Testing**: pytest, unittest
- **Mocking**: unittest.mock, pytest-mock
- **Integration**: Testcontainers-python
- **Coverage**: coverage.py, pytest-cov

### .NET/C#

- **Unit Testing**: xUnit, NUnit, MSTest
- **Mocking**: Moq, NSubstitute
- **Integration**: Testcontainers.DotNet
- **Coverage**: Coverlet, dotCover

## CI/CD Integration

- Run unit tests before build stage in CI/CD pipeline
- Configure pre-commit hooks to run unit tests before commits
- Fail builds on test failures or coverage drops
- Generate and publish test reports

## External Dependencies

- Mock external services for unit tests
- Use test doubles (mocks, stubs, fakes) appropriately
- Implement testcontainers for integration tests
- Ensure tests run consistently in local and CI/CD environments

## Test Environment Setup

- Use testcontainers for database and service dependencies
- Configure isolated test environments
- Implement proper test data management
- Clean up test resources after execution

## Coverage Requirements

- Maintain minimum 80% code coverage
- Focus coverage on business logic and critical paths
- Exclude configuration and boilerplate code from coverage
- Monitor coverage trends and prevent regression

## Best Practices

- Write descriptive test names that explain behavior
- Follow AAA pattern (Arrange, Act, Assert)
- Keep tests independent and deterministic
- Use parameterized tests for multiple scenarios
- Implement proper test categorization and tagging

## Pre-commit Hooks

- Configure git hooks to run unit tests before commits
- Prevent commits that break existing tests
- Run linting and formatting checks
- Validate code coverage thresholds

## Test Data Management

- Use factories or builders for test data creation
- Implement database seeding for integration tests
- Clean test data between test runs
- Use realistic but anonymized test data
