# AWS Lambda Rules

## Configuration Management

- Minimize use of environment variables for sensitive data
- Pull configuration from AWS Systems Manager Parameter Store within the application
- Use AWS Secrets Manager for sensitive credentials and API keys
- Cache SSM parameters to reduce API calls and improve performance
- Implement proper error handling for configuration retrieval

## Deployment Best Practices

- Always use Lambda versions for deployments, never deploy to $LATEST
- Always use the latest available runtime version for the programming language
- Use aliases to manage traffic routing between versions
- Implement blue/green deployments using weighted aliases
- Tag versions with deployment metadata (commit hash, build number, timestamp)
- Use Terraform for infrastructure as code deployments

## Observability and Debugging

- Always enable AWS X-Ray tracing for distributed request tracking
- Integrate Dynatrace OneAgent for comprehensive application monitoring
- Configure enhanced monitoring and logging
- Use structured logging with JSON format
- Include correlation IDs in all log entries
- Set appropriate log retention periods in CloudWatch
- Implement custom metrics for business logic monitoring
- Use Dynatrace for performance profiling and error tracking

## Performance Optimization

- Right-size memory allocation based on profiling
- Use provisioned concurrency for latency-sensitive functions
- Implement connection pooling for database connections
- Minimize cold start impact with proper initialization
- Use Lambda layers for shared dependencies

## Security

- Follow principle of least privilege for IAM execution roles
- Enable VPC configuration only when necessary
- Use Lambda authorizers for API Gateway authentication
- Validate all input parameters and sanitize data
- Implement proper error handling without exposing sensitive information

## Code Organization

- Keep handler functions lightweight and focused
- Separate business logic from AWS-specific code
- Use dependency injection for testability
- Implement proper exception handling and logging
- Follow single responsibility principle for function design
