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
