#!/usr/bin/env bash
set -e

echo "=== Installing win11-snip-bar ==="

# Check dependencies
MISSING=""
for cmd in gcc pkg-config grim slurp wl-copy notify-send; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        MISSING="$MISSING $cmd"
    fi
done

if ! pkg-config --exists gtk4 gtk4-layer-shell-0 2>/dev/null; then
    MISSING="$MISSING gtk4/gtk4-layer-shell"
fi

if [ -n "$MISSING" ]; then
    echo "Warning: The following dependencies were not found:$MISSING"
    echo "Please ensure they are installed (e.g. on Arch: sudo pacman -S gtk4 gtk4-layer-shell grim slurp wl-clipboard libnotify)"
fi

PREFIX="${PREFIX:-$HOME/.local}"
echo "Building and installing to $PREFIX..."
make PREFIX="$PREFIX" install

echo ""
echo "=== Installation complete ==="
echo "Binary: $PREFIX/bin/win11-snip-bar"
echo "Helpers: $PREFIX/lib/win11-snip-bar/"
echo ""
echo "Make sure $PREFIX/bin is in your PATH."
echo "Add the keybinding to ~/.config/niri/config.kdl:"
echo ""
echo 'binds {'
echo '    Mod+Shift+S { spawn "win11-snip-bar"; }'
echo '    Print { spawn "win11-snip-bar"; }'
echo '}'
