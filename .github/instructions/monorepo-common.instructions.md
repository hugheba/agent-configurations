# Monorepo Common Rules

## Repository Structure

- Use consistent directory structure across all projects
- Place shared code in `/shared` or `/common` directories
- Keep project-specific code in dedicated folders (e.g., `/apps`, `/services`)
- Maintain infrastructure code in `/infrastructure` at root level
- Use `/tools` for build scripts and utilities

## Dependency Management

- Use workspace features of package managers (npm workspaces, yarn workspaces, poetry workspaces)
- Define shared dependencies at root level
- Pin dependency versions consistently across projects
- Use lockfiles and commit them to version control
- Implement dependency vulnerability scanning

## Build and CI/CD

- Implement selective builds based on changed files
- Use build caching to optimize CI/CD performance
- Create separate deployment pipelines for each service/app
- Use path-based triggers for GitLab CI/CD jobs
- Implement parallel builds where possible

## Code Organization

- Enforce consistent coding standards across all projects
- Use shared linting and formatting configurations
- Implement pre-commit hooks for code quality
- Use consistent naming conventions for projects and modules
- Maintain separate README files for each project

## Testing Strategy

- Run tests only for changed code and dependencies
- Use shared test utilities and fixtures
- Implement integration tests at the monorepo level
- Maintain separate test databases/environments per service
- Use test result caching to speed up CI/CD

## Documentation

- Maintain root-level README with project overview
- Document inter-service dependencies and communication
- Keep API documentation up to date
- Use consistent documentation format across projects
- Document deployment and development setup procedures

## Version Control

- Use conventional commit messages
- Implement semantic versioning for releases
- Tag releases at monorepo level with project-specific tags
- Use branch protection rules
- Implement automated changelog generation
