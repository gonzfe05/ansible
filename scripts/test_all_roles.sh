#!/usr/bin/env bash

set -euo pipefail

ROLES_DIR="playbooks/roles"
SCENARIO_NAME="default"  # or any other scenario name if needed

# Set roles path so Molecule can find sibling roles (for role dependencies)
export ANSIBLE_ROLES_PATH="$(pwd)/$ROLES_DIR"

# Set vault password file if it exists
if [ -f "$HOME/.vault_pass.txt" ]; then
    export ANSIBLE_VAULT_PASSWORD_FILE="$HOME/.vault_pass.txt"
else
    echo "⚠️  WARNING: Vault password file not found at $HOME/.vault_pass.txt"
    echo "   SSH-related tests (and other tests requiring vault) will fail!"
fi

echo "🔍 Searching for Molecule scenarios in $ROLES_DIR..."

find "$ROLES_DIR" -type d -name molecule | while read -r molecule_dir; do
    role_dir=$(dirname "$molecule_dir")
    echo "🔧 Testing role: $role_dir"

    (
        cd "$role_dir"
        if molecule test --scenario-name "$SCENARIO_NAME"; then
            echo "✅ $role_dir passed"
        else
            echo "❌ $role_dir failed"
            exit 1
        fi
    )
done

echo "🎉 All Molecule tests completed!"
