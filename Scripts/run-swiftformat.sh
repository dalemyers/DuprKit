#!/bin/bash

# SwiftFormat Runner Script
# This script runs SwiftFormat on the entire project

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Check if swiftformat is installed
if ! command -v swiftformat &> /dev/null; then
    echo "Error: swiftformat not found"
    echo "Install with: brew install swiftformat"
    exit 1
fi

# Run SwiftFormat
echo "Running SwiftFormat..."
swiftformat .

echo "✓ SwiftFormat complete"
