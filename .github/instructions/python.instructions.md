# Python Common Rules

## Python Version

- Use Python 3.9+ (prefer 3.11 or 3.12)
- Avoid Python 2.x for all new development
- Use pyenv for Python version management

## Package and Environment Management

- Prefer uv for fast package management and virtual environments
- Fall back to venv if uv is not available
- Never install packages globally
- Use pyproject.toml for modern dependency management

## Environment Setup with uv

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create project and virtual environment
uv init my-project
cd my-project
uv add package-name
uv run python script.py
```

## Fallback Environment Setup (venv)

```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows
pip install -r requirements.txt
```

## Dependency Management

- Use uv for fast dependency resolution and installation
- Use pip-tools as fallback for dependency pinning
- Separate dev and production dependencies
- Pin exact versions in requirements.txt or use uv.lock

## Code Quality

- Use Black for code formatting
- Use isort for import sorting
- Use flake8 or ruff for linting
- Use mypy for type checking
- Configure pre-commit hooks

## Type Hints

- Use type hints for all functions and methods
- Import types from typing module
- Use Union, Optional, List, Dict appropriately
- Enable strict mypy checking

## Project Structure

```
project/
├── src/
│   └── package/
├── tests/
├── requirements.txt
├── requirements-dev.txt
├── pyproject.toml
├── .gitignore
└── README.md
```

## Documentation

- Use docstrings for all modules, classes, and functions
- Follow Google or NumPy docstring style
- Use Sphinx for documentation generation
- Include type information in docstrings

## Testing

- Use pytest for testing framework
- Write unit tests with descriptive names
- Use fixtures for test data setup
- Implement proper test isolation

## Example Code Style

```python
from typing import List, Optional

def process_users(users: List[dict], active_only: bool = True) -> Optional[List[str]]:
    """
    Process user data and return active user names.

    Args:
        users: List of user dictionaries
        active_only: Filter for active users only

    Returns:
        List of user names or None if no users found
    """
    if not users:
        return None

    filtered_users = [u for u in users if not active_only or u.get('active', False)]
    return [user['name'] for user in filtered_users]
```

## Performance

- Use list comprehensions over loops when appropriate
- Use generators for memory efficiency
- Profile code with cProfile when needed
- Use appropriate data structures (set, dict, list)

---

## Framework-Specific Guidelines

### FastAPI

#### Project Structure

```
src/
├── app/
│   ├── main.py         # FastAPI app configuration
│   ├── server.py       # Local/container server entry point
│   ├── handler.py      # AWS Lambda handler
│   ├── routers/        # API route modules
│   ├── models/         # Pydantic models
│   ├── services/       # Business logic
│   └── dependencies/   # Dependency injection
├── tests/
└── requirements.txt
```

#### Application Architecture

- **main.py**: Export configured FastAPI instance
- **server.py**: Uvicorn server for local/container deployment
- **handler.py**: AWS Lambda handler using Mangum

#### Example Implementation

**main.py**:
```python
from fastapi import FastAPI
from app.routers import users, health

def create_app() -> FastAPI:
    app = FastAPI(
        title="My API",
        version="1.0.0",
        docs_url="/docs"
    )

    app.include_router(health.router)
    app.include_router(users.router, prefix="/api/v1")

    return app

app = create_app()
```

**server.py**:
```python
import uvicorn
from app.main import app

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
```

**handler.py**:
```python
from mangum import Mangum
from app.main import app

handler = Mangum(app, lifespan="off")
```

#### Pydantic Models

- Use Pydantic v2 for request/response models
- Implement proper validation with Field
- Use BaseModel for all data structures
- Separate request and response models

**Example Models**:
```python
from pydantic import BaseModel, Field, EmailStr
from typing import Optional
from datetime import datetime

class UserCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr
    age: int = Field(..., ge=18, le=120)

class UserResponse(BaseModel):
    id: str
    name: str
    email: str
    created_at: datetime
```

#### Best Practices

- Use dependency injection for database connections
- Implement proper error handling with HTTPException
- Use async/await for all route handlers
- Implement request/response validation
- Use background tasks for non-blocking operations

#### Database Integration

- Use SQLAlchemy with async support
- Implement proper connection pooling
- Use Alembic for database migrations
- Create database dependencies for injection

#### Testing

- Use pytest with pytest-asyncio
- Use TestClient for API testing
- Mock external dependencies
- Test both success and error scenarios

#### Security

- Implement proper authentication (JWT, OAuth2)
- Use HTTPS in production
- Validate all input data
- Implement rate limiting
- Use CORS middleware appropriately

#### Performance

- Use async database drivers
- Implement proper caching strategies
- Use connection pooling
- Enable compression middleware
- Profile and optimize slow endpoints

---

### Robyn Framework

#### Framework Overview
- Robyn is a high-performance Python web framework built with Rust
- Async-first design with support for both sync and async handlers
- Built-in WebSocket support and middleware system

#### Project Structure
```
project/
├── main.py              # Application entry point
├── routes/              # Route handlers
├── middleware/          # Custom middleware
├── models/              # Data models
└── requirements.txt     # Dependencies
```

#### Application Setup
- Initialize app with `Robyn(__file__)`
- Use `app.start(host="0.0.0.0", port=8080)` for production
- Enable hot reload in development: `app.start(dev=True)`

#### Route Handlers
- Use decorators: `@app.get()`, `@app.post()`, `@app.put()`, `@app.delete()`
- Prefer async handlers for I/O operations: `async def handler(request)`
- Return Response objects: `Response(status_code=200, headers={}, body="")`
- Access request data: `request.body`, `request.headers`, `request.query_params`

#### Request/Response
- Parse JSON: `request.json()`
- Set response headers: `Response(headers={"Content-Type": "application/json"})`
- Return JSON: serialize with `json.dumps()` or use dict with proper headers
- Handle path parameters: `@app.get("/users/:id")` then `request.path_params["id"]`

#### Middleware
- Define with `@app.before_request()` for pre-processing
- Use `@app.after_request()` for post-processing
- Middleware receives request object and must return it
- Order matters: middleware executes in definition order

#### Error Handling
- Use try-except blocks in handlers
- Return appropriate status codes: 400, 404, 500
- Create custom error responses with Response object
- Log errors for debugging

#### Performance
- Use async handlers for database/API calls
- Leverage Robyn's Rust-based performance
- Minimize blocking operations in handlers
- Use connection pooling for databases

#### WebSockets
- Define with `@app.websocket(route)`
- Handle events: `connect`, `message`, `disconnect`
- Send messages: `websocket.send(message)`
- Broadcast to all: maintain client list and iterate

#### Static Files
- Serve with `app.serve_directory(route="/static", directory_path="./static")`
- Place assets in dedicated directory
- Use absolute paths for directory_path

#### Configuration
- Use environment variables for secrets and config
- Load with `os.getenv()` or python-dotenv
- Separate dev/prod configurations
- Never commit secrets to version control

#### Dependencies
```
robyn
python-dotenv  # For environment variables
```

#### Testing
- Test handlers as regular async functions
- Mock request objects for unit tests
- Use pytest with pytest-asyncio
- Test middleware independently

#### Common Patterns
- Group related routes in separate modules
- Use dependency injection for database connections
- Implement health check endpoint: `@app.get("/health")`
- Version APIs: `/api/v1/resource`

#### Security
- Validate all input data
- Sanitize user-provided content
- Use HTTPS in production
- Implement rate limiting via middleware
- Set security headers (CORS, CSP, etc.)

#### Telemetry & Monitoring
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

**Metrics to Track**:
- HTTP request duration (histogram)
- Request count by endpoint and status code (counter)
- Active connections (gauge)
- Error rate by type (counter)
- Database query duration (histogram)

**Logging Middleware Example**:
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

**Dependencies for Telemetry**:
```
prometheus-client  # Metrics
opentelemetry-api  # Tracing
opentelemetry-sdk
structlog          # Structured logging
```

