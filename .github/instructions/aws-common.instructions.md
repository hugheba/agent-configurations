# AWS Common Rules

## Credential Management

- NEVER hardcode AWS credentials in code, configuration files, or environment variables
- Use AWS profiles for local development: `aws configure --profile <profile-name>`
- Use OIDC roles for CI/CD and production environments
- Reference profiles in AWS CLI commands: `aws s3 ls --profile <profile-name>`
- Use IAM roles for EC2 instances and Lambda functions
- Store sensitive configuration in AWS Systems Manager Parameter Store or AWS Secrets Manager

## Security Best Practices

- Follow principle of least privilege for IAM policies
- Enable MFA for AWS console access
- Use resource-based policies when appropriate
- Implement proper VPC security groups and NACLs
- Enable CloudTrail for audit logging
- Use AWS Config for compliance monitoring

## Resource Naming

- Use consistent naming conventions with environment prefixes
- Include project/application identifiers in resource names
- Use tags for resource organization and cost allocation
- Follow AWS tagging best practices

## Cost Optimization

- Use appropriate instance types and sizes
- Implement auto-scaling where applicable
- Use Reserved Instances or Savings Plans for predictable workloads
- Monitor costs with AWS Cost Explorer and budgets
- Clean up unused resources regularly

## Monitoring and Logging

- Use CloudWatch for metrics and alarms
- Implement structured logging
- Set up appropriate log retention policies
- Use X-Ray for distributed tracing when needed
