# Node.js Angular Rules

## Extends

- Follow all rules from `nodejs-common-rules.md`

## Angular Version Requirements

- Use recent versions of Angular (16+)
- Do not use AngularJS (1.x) for new projects
- Keep Angular CLI updated to latest stable version
- Use Angular LTS versions for production applications

## Project Structure

- Follow Angular style guide conventions
- Use feature modules for organization
- Implement lazy loading for route modules
- Separate shared components into modules

## TypeScript Configuration

- Use strict mode in Angular projects
- Enable Angular strict template checks
- Use Angular ESLint rules
- Configure path mapping for clean imports

## Component Best Practices

- Use OnPush change detection strategy
- Implement OnDestroy for cleanup
- Use reactive forms over template-driven forms
- Follow single responsibility principle

## State Management

- Use Angular services for simple state
- Implement NgRx for complex state management
- Use RxJS operators effectively
- Avoid memory leaks with proper subscriptions

## Testing

- Use Jasmine and Karma for unit tests
- Write component tests with TestBed
- Use Angular Testing Library for better tests
- Mock HTTP calls with HttpClientTestingModule

## Build and Deployment

- Use Angular CLI for builds
- Configure environment-specific builds
- Implement proper bundling and tree-shaking
- Use Angular Universal for SSR when needed

## Performance

- Implement lazy loading
- Use OnPush change detection
- Optimize bundle sizes
- Use trackBy functions in \*ngFor
