# Python FastAPI Rules

## Extends

- Follow all rules from `python-common-rules.md`

## Project Structure

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

## Application Architecture

- **main.py**: Export configured FastAPI instance
- **server.py**: Uvicorn server for local/container deployment
- **handler.py**: AWS Lambda handler using Mangum

## Example Implementation

### main.py

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

### server.py

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

### handler.py

```python
from mangum import Mangum
from app.main import app

handler = Mangum(app, lifespan="off")
```

## Pydantic Models

- Use Pydantic v2 for request/response models
- Implement proper validation with Field
- Use BaseModel for all data structures
- Separate request and response models

## Example Models

```python
from pydantic import BaseModel, Field, EmailStr
from typing import Optional

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

## Best Practices

- Use dependency injection for database connections
- Implement proper error handling with HTTPException
- Use async/await for all route handlers
- Implement request/response validation
- Use background tasks for non-blocking operations

## Database Integration

- Use SQLAlchemy with async support
- Implement proper connection pooling
- Use Alembic for database migrations
- Create database dependencies for injection

## Testing

- Use pytest with pytest-asyncio
- Use TestClient for API testing
- Mock external dependencies
- Test both success and error scenarios

## Security

- Implement proper authentication (JWT, OAuth2)
- Use HTTPS in production
- Validate all input data
- Implement rate limiting
- Use CORS middleware appropriately

## Performance

- Use async database drivers
- Implement proper caching strategies
- Use connection pooling
- Enable compression middleware
- Profile and optimize slow endpoints
