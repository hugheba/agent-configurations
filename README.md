# Agent Configurations

This repository contains configuration files and instructions for various AI agents and development tools.

## File Organization

All instruction files are stored in `.github/instructions/` as the source of truth and symlinked to agent-specific directories:

- **Source**: `.github/instructions/*.instructions.md` - Master files containing all instructions
- **Symlinks**: `.amazonq/rules/*-rules.md` - Symlinks pointing to the source files

### Adding New Instructions

1. Create new instruction files in `.github/instructions/` with `.instructions.md` extension
2. Create symlinks in agent-specific directories with appropriate naming conventions
3. Update this documentation when adding new agent directories

### Example Structure

```
.github/instructions/
├── general.instructions.md
├── nodejs-common.instructions.md
└── python-fastapi.instructions.md

.amazonq/rules/
├── general-rules.md -> ../../.github/instructions/general.instructions.md
├── nodejs-common-rules.md -> ../../.github/instructions/nodejs-common.instructions.md
└── python-fastapi-rules.md -> ../../.github/instructions/python-fastapi.instructions.md
```

This approach ensures:
- Single source of truth for all instructions
- Agent-specific naming conventions maintained
- Easy maintenance and updates
- Version control of instruction changes
