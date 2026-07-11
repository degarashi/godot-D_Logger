#!/bin/bash

# Configuration
GODOT_BIN=${GODOT_BIN:-godot}

# Check if Godot binary exists
if ! command -v "$GODOT_BIN" &> /dev/null; then
    echo "Error: Godot binary not found at $GODOT_BIN"
    echo "Please set the GODOT_BIN environment variable or edit this script."
    exit 1
fi

echo "--------------------------------------------------"
echo "Running D-Logger Test Suite"
echo "Godot: $GODOT_BIN"
echo "--------------------------------------------------"

$GODOT_BIN --headless --path . -s tests/test.gd

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "--------------------------------------------------"
    echo "✅ All tests passed!"
else
    echo "--------------------------------------------------"
    echo "❌ Some tests failed with exit code $EXIT_CODE"
fi

exit $EXIT_CODE
