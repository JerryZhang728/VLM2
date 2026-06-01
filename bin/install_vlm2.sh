#!/bin/bash
# Install the vlm2 CLI wrapper into ~/.local/bin.
# Run once on Thor after the project files are in place.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.local/bin/vlm2"

mkdir -p "$HOME/.local/bin"
cp "$SCRIPT_DIR/vlm2" "$TARGET"
chmod +x "$TARGET"
echo "Installed: $TARGET"

# Ensure ~/.local/bin is in PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$HOME/.local/bin"; then
    echo ""
    echo "Note: \$HOME/.local/bin is not in your PATH yet."
    echo "Adding to ~/.bashrc so 'vlm2' works from any shell..."
    if ! grep -q '.local/bin' "$HOME/.bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        echo "Added. Run 'source ~/.bashrc' or open a new shell."
    fi
fi

echo ""
echo "Try it:  vlm2 status"
