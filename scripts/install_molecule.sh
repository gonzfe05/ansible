#!/usr/bin/env bash

set -euo pipefail

echo "🔧 Installing Molecule and Docker dependencies..."

# Ensure pip is available
if ! command -v pip &> /dev/null; then
    echo "⚠️  pip not found. Installing pip for Python 3..."
    sudo apt update
    sudo apt install -y python3-pip python3-dev python3-venv build-essential
    echo "✅ pip installed successfully"
fi

# Install molecule and docker driver (quoting avoids zsh/bash globbing issues)
# Using --break-system-packages is safe here because we're installing to --user
pip install --user --break-system-packages molecule 'molecule-plugins[docker]' ansible-lint docker

# Detect shell rc file
SHELL_NAME=$(basename "$SHELL")
RC_FILE="$HOME/.bashrc"
if [[ "$SHELL_NAME" == "zsh" ]]; then
    RC_FILE="$HOME/.zshrc"
fi

# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "🔧 Adding ~/.local/bin to PATH in $RC_FILE"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC_FILE"
    export PATH="$HOME/.local/bin:$PATH"
else
    echo "✅ ~/.local/bin already in PATH"
fi

# Validate installation
echo "✅ Molecule version: $(molecule --version)"
echo "✅ Ansible version: $(ansible --version | head -n1)"
echo "✅ Docker version: $(docker --version)"

echo "🎉 Molecule setup complete. Restart your shell or run:"
echo "    source $RC_FILE"
