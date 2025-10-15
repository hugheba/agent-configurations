# GitLab Common Rules

## Repository Security

- Enable branch protection for main/master branches
- Require merge request approvals before merging
- Enable push rules to prevent force pushes to protected branches
- Use signed commits where possible
- Enable vulnerability scanning and dependency scanning
- Configure secret detection to prevent credential leaks

## SAST and Security Scanning

- Enable GitLab SAST (Static Application Security Testing) in CI/CD pipelines
- Configure dependency scanning for known vulnerabilities
- Use container scanning for Docker images
- Enable license compliance scanning
- Set up security dashboard monitoring
- Configure security policies and approval rules

## CI/CD Pipeline Configuration

- Use `.gitlab-ci.yml` in repository root
- Implement multi-stage pipelines (build, test, security, deploy)
- Use GitLab CI/CD variables for sensitive configuration
- Enable pipeline caching for faster builds
- Use job artifacts for build outputs
- Implement proper error handling and notifications

## Access Control and Permissions

- Use least privilege principle for project access
- Configure group-level permissions appropriately
- Use deploy keys for automated deployments
- Implement proper role-based access control
- Enable two-factor authentication for all users
- Regular access reviews and cleanup

## Merge Request Guidelines

- Use descriptive merge request titles and descriptions
- Link merge requests to issues where applicable
- Require code review before merging
- Use merge request templates for consistency
- Enable merge request approvals
- Configure automatic merge after approval

## Issue and Project Management

- Use issue templates for bug reports and feature requests
- Label issues consistently for better organization
- Link commits to issues using keywords
- Use milestones for release planning
- Configure issue boards for workflow management
- Enable time tracking for project metrics

## Repository Configuration

- Use meaningful repository descriptions
- Configure repository topics/tags for discoverability
- Set up repository mirroring if needed
- Configure webhooks for external integrations
- Use repository templates for consistent project setup
- Enable container registry for Docker images

## Compliance and Auditing

- Enable audit logging for security events
- Configure compliance frameworks where required
- Use push rules for commit message standards
- Implement automated compliance checks
- Regular security and access audits
- Document security procedures and incident response
