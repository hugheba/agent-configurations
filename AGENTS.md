# Agent Configuration Management

This file should follow the pattern established in https://agb1gb

## File Organization Pattern

All agent instruction files follow a centralized pattern:

1. **Source Files**: Create in `.github/instructions/` with `.instructions.md` extension
2. **Agent Symlinks**: Link to agent-specific directories with appropriate naming

## Current Agent Directories

### Amazon Q (.amazonq/rules/)
- Naming: `*-rules.md`
- Links to: `../../.github/instructions/*.instructions.md`

## Adding New Agent Support

1. Create agent directory (e.g., `.cursor/`, `.copilot/`)
2. Create symlinks from source files with agent-specific naming
3. Document the new agent pattern here

## Creating New Instructions

```bash
# 1. Create source file
touch .github/instructions/new-feature.instructions.md

# 2. Create symlinks for each agent
ln -s ../../.github/instructions/new-feature.instructions.md .amazonq/rules/new-feature-rules.md

# 3. Add other agents as needed
```

This ensures single source of truth while maintaining agent-specific naming conventions.
