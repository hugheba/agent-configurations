# Python Robyn Framework Best Practices

## Framework Overview
- Robyn is a high-performance Python web framework built with Rust
- Async-first design with support for both sync and async handlers
- Built-in WebSocket support and middleware system

## Project Structure
```
project/
├── main.py              # Application entry point
├── routes/              # Route handlers
├── middleware/          # Custom middleware
├── models/              # Data models
└── requirements.txt     # Dependencies
```

## Application Setup
- Initialize app with `Robyn(__file__)`
- Use `app.start(host="0.0.0.0", port=8080)` for production
- Enable hot reload in development: `app.start(dev=True)`

## Route Handlers
- Use decorators: `@app.get()`, `@app.post()`, `@app.put()`, `@app.delete()`
- Prefer async handlers for I/O operations: `async def handler(request)`
- Return Response objects: `Response(status_code=200, headers={}, body="")`
- Access request data: `request.body`, `request.headers`, `request.query_params`

## Request/Response
- Parse JSON: `request.json()`
- Set response headers: `Response(headers={"Content-Type": "application/json"})`
- Return JSON: serialize with `json.dumps()` or use dict with proper headers
- Handle path parameters: `@app.get("/users/:id")` then `request.path_params["id"]`

## Middleware
- Define with `@app.before_request()` for pre-processing
- Use `@app.after_request()` for post-processing
- Middleware receives request object and must return it
- Order matters: middleware executes in definition order

## Error Handling
- Use try-except blocks in handlers
- Return appropriate status codes: 400, 404, 500
- Create custom error responses with Response object
- Log errors for debugging

## Performance
- Use async handlers for database/API calls
- Leverage Robyn's Rust-based performance
- Minimize blocking operations in handlers
- Use connection pooling for databases

## WebSockets
- Define with `@app.websocket(route)`
- Handle events: `connect`, `message`, `disconnect`
- Send messages: `websocket.send(message)`
- Broadcast to all: maintain client list and iterate

## Static Files
- Serve with `app.serve_directory(route="/static", directory_path="./static")`
- Place assets in dedicated directory
- Use absolute paths for directory_path

## Configuration
- Use environment variables for secrets and config
- Load with `os.getenv()` or python-dotenv
- Separate dev/prod configurations
- Never commit secrets to version control

## Dependencies
```
robyn
python-dotenv  # For environment variables
```

## Testing
- Test handlers as regular async functions
- Mock request objects for unit tests
- Use pytest with pytest-asyncio
- Test middleware independently

## Common Patterns
- Group related routes in separate modules
- Use dependency injection for database connections
- Implement health check endpoint: `@app.get("/health")`
- Version APIs: `/api/v1/resource`

## Security
- Validate all input data
- Sanitize user-provided content
- Use HTTPS in production
- Implement rate limiting via middleware
- Set security headers (CORS, CSP, etc.)

## Telemetry & Monitoring
- Use structured logging with `logging` module or `structlog`
- Log request/response via middleware: method, path, status, duration
- Track metrics: request count, response time, error rate
- Implement OpenTelemetry for distributed tracing
- Use Prometheus client for metrics export
- Monitor with `/metrics` endpoint for scraping
- Add correlation IDs to requests for tracing
- Log to stdout/stderr for container environments
- Use log levels appropriately: DEBUG, INFO, WARNING, ERROR
- Include context in logs: user_id, request_id, timestamp

### Metrics to Track
- HTTP request duration (histogram)
- Request count by endpoint and status code (counter)
- Active connections (gauge)
- Error rate by type (counter)
- Database query duration (histogram)

### Logging Middleware Example
```python
import time
import logging

@app.before_request()
async def log_request(request):
    request.start_time = time.time()
    return request

@app.after_request()
async def log_response(response):
    duration = time.time() - response.request.start_time
    logging.info(f"{response.request.method} {response.request.path} {response.status_code} {duration:.3f}s")
    return response
```

### Dependencies for Telemetry
```
prometheus-client  # Metrics
opentelemetry-api  # Tracing
opentelemetry-sdk
structlog          # Structured logging
```
