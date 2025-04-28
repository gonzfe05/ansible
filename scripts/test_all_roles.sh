#!/usr/bin/env bash

set -euo pipefail

ROLES_DIR="playbooks/roles"
SCENARIO_NAME="default"  # or any other scenario name if needed

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
