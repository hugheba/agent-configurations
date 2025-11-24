#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

mkdir -p .gemini

# Concatenate all instruction files
cat .github/instructions/*.instructions.md > .gemini/GEMINI.md

echo "✓ Built .gemini/GEMINI.md"
