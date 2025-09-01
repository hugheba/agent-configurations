# CI/CD Common Rules

## GitLab CI/CD Requirements

- All projects must have a `.gitlab-ci.yml` file in the root directory
- Configure pipeline for testing and deployment
- Use appropriate stages: build, test, deploy
- Implement proper artifact management
- Use environment-specific deployments

## Pipeline Structure

- **Build Stage**: Compile/package application
- **Test Stage**: Run unit and integration tests
- **Coverage Stage**: Generate and publish test coverage reports
- **Deploy Stage**: Deploy to target environments

## Test and Coverage Requirements

- Generate JUnit XML test reports
- Publish test results to GitLab project files
- Generate code coverage reports (JaCoCo, Istanbul, etc.)
- Upload coverage artifacts to GitLab
- Configure coverage thresholds and quality gates
- Display coverage badges in project README

## Best Practices

- Use Docker images for consistent environments
- Cache dependencies between pipeline runs
- Implement proper secret management
- Use GitLab environments for deployment tracking
- Configure manual approval for production deployments
- Implement rollback strategies

## AWS Authentication

- Use OIDC (OpenID Connect) for AWS authentication in GitLab CI/CD
- Do not use AWS access keys or environment variables
- Configure AWS IAM roles with GitLab OIDC provider
- Use assume role with web identity for secure authentication

## Security

- Never commit secrets to repository
- Use GitLab CI/CD variables for sensitive data
- Implement least privilege access
- Scan for vulnerabilities in dependencies

## Sample GitLab CI/CD Template

```yaml
stages:
  - build
  - test
  - coverage
  - deploy

test:
  stage: test
  script:
    - run-tests
  artifacts:
    reports:
      junit: test-results.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
    paths:
      - coverage/
    expire_in: 1 week
  coverage: '/Coverage: \d+\.\d+%/'
```

## Required Variables

- Set project-specific variables in GitLab CI/CD settings
- Use environment variables for configuration
- Implement proper variable scoping (project/group/instance)

## Monitoring

- Configure pipeline notifications
- Track deployment metrics
- Implement health checks post-deployment
- Set up alerting for failed deployments
