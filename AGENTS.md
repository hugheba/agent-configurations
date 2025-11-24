# Agent Configuration Management

This file should follow the pattern established in https://agb1gb

## File Organization Pattern

All agent instruction files originate in the `.github/instructions` folder and are symlinked to other folders.

All agent instruction files follow a centralized pattern:

1. **Source Files**: Create in `.github/instructions/` with `.instructions.md` extension
2. **Agent Symlinks**: Link to agent-specific directories with appropriate naming (Amazon Q, Cline, etc.)

## Current Agent Directories

### Amazon Q (.amazonq/rules/)
- Naming: `*-rules.md`
- Links to: `../../.github/instructions/*.instructions.md`

### Cline (Cline/Rules/)
- Naming: `*-rules.md`
- Links to: `../../.github/instructions/*.instructions.md`

### Roo (.roo/rules/)
- Naming: `*-rules.md`
- Links to: `../../.github/instructions/*.instructions.md`

### Gemini (~/.gemini/)
- Naming: `GEMINI.md` (single concatenated file)
- Global location: `~/.gemini/GEMINI.md`
- Local staging: `agent-configurations/.gemini/GEMINI.md`
- Source: Concatenated from all `.github/instructions/*.instructions.md` files

## Adding New Agent Support

1. Create agent directory (e.g., `.cursor/`, `.copilot/`, `.roo/`)
2. Create symlinks from source files with agent-specific naming
3. Document the new agent pattern here

## Creating New Instructions

```bash
# 1. Create source file
touch .github/instructions/new-feature.instructions.md

# 2. Create symlinks for each agent
./scripts/link-instruction.sh new-feature

# 3. Rebuild Gemini configuration
./scripts/build-gemini.sh
```

## Installing Global Configurations

For agents that require global configuration (e.g., Gemini at `~/.gemini/`):

```bash
# Repository must be at ~/agent-configurations
./scripts/install-global.sh
```

This ensures single source of truth while maintaining agent-specific naming conventions.
