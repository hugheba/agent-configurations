#!/bin/bash

# Script to create symlinks from .github/instructions to agent directories
# Usage: ./scripts/link-instruction.sh <instruction-file-basename>
# Example: ./scripts/link-instruction.sh jvm-quarkus-api

set -e

# Check if parameter is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <instruction-file-basename>"
    echo "Example: $0 jvm-quarkus-api"
    echo ""
    echo "This will link .github/instructions/<basename>.instructions.md to:"
    echo "  - .amazonq/rules/<basename>-rules.md"
    echo "  - Cline/Rules/<basename>-rules.md"
    exit 1
fi

BASENAME="$1"
SOURCE_FILE=".github/instructions/${BASENAME}.instructions.md"
AMAZONQ_LINK=".amazonq/rules/${BASENAME}-rules.md"
CLINE_LINK="Cline/Rules/${BASENAME}-rules.md"

# Get the script directory to ensure we're in the right location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Change to repo root
cd "${REPO_ROOT}"

# Check if source file exists
if [ ! -f "${SOURCE_FILE}" ]; then
    echo "Error: Source file '${SOURCE_FILE}' does not exist"
    echo ""
    echo "Available instruction files:"
    ls -1 .github/instructions/*.instructions.md 2>/dev/null | sed 's|.github/instructions/||g' | sed 's|.instructions.md||g' || echo "  (none found)"
    exit 1
fi

# Create directories if they don't exist
mkdir -p .amazonq/rules
mkdir -p Cline/Rules

# Function to create symlink with confirmation
create_symlink() {
    local target="$1"
    local link="$2"
    local relative_source="../../${SOURCE_FILE}"
    
    if [ -L "${link}" ]; then
        echo "Symlink '${link}' already exists, removing old one..."
        rm "${link}"
    elif [ -f "${link}" ]; then
        echo "Warning: Regular file '${link}' exists. Remove it manually if you want to replace it with a symlink."
        return 1
    fi
    
    ln -s "${relative_source}" "${link}"
    echo "Created symlink: ${link} -> ${relative_source}"
}

# Create symlinks
echo "Creating symlinks for '${BASENAME}'..."
echo "Source: ${SOURCE_FILE}"
echo ""

create_symlink "${SOURCE_FILE}" "${AMAZONQ_LINK}"
create_symlink "${SOURCE_FILE}" "${CLINE_LINK}"

echo ""
echo "Successfully created symlinks for ${BASENAME}"

# Verify the links
echo ""
echo "Verification:"
ls -la "${AMAZONQ_LINK}" 2>/dev/null && echo "✓ Amazon Q link created successfully" || echo "✗ Amazon Q link failed"
ls -la "${CLINE_LINK}" 2>/dev/null && echo "✓ Cline link created successfully" || echo "✗ Cline link failed"