#!/bin/bash

# SwiftLint Runner Script
# This script runs SwiftLint on the entire project

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Check if swiftlint is installed
if ! command -v swiftlint &> /dev/null; then
    echo "Error: swiftlint not found"
    echo "Install with: brew install swiftlint"
    exit 1
fi

# Run SwiftLint
echo "Running SwiftLint..."
swiftlint

echo "✓ SwiftLint complete"
