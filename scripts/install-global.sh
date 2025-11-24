#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Check if repo is in home directory
if [[ "${REPO_ROOT}" != "${HOME}/agent-configurations" ]]; then
    echo "Error: Repository must be at ~/agent-configurations"
    echo "Current location: ${REPO_ROOT}"
    exit 1
fi

# Build Gemini configuration
"${SCRIPT_DIR}/build-gemini.sh"

# Create global directories
mkdir -p ~/.gemini

# Symlink Gemini configuration
ln -sf ~/agent-configurations/.gemini/GEMINI.md ~/.gemini/GEMINI.md

echo "✓ Installed global agent configurations"
echo "  ~/.gemini/GEMINI.md -> ~/agent-configurations/.gemini/GEMINI.md"
