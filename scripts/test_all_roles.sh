#!/usr/bin/env bash

set -euo pipefail

ROLES_DIR="playbooks/roles"
SCENARIO_NAME="default"  # or any other scenario name if needed

# Get absolute path to the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Cache file for tracking test results
CACHE_FILE="${PROJECT_ROOT}/.molecule_test_cache"

# Set default Ubuntu version (use environment variables if set)
export UBUNTU_MAJOR="${UBUNTU_MAJOR:-24}"
export UBUNTU_MINOR="${UBUNTU_MINOR:-04}"

# Set Ansible roles path so molecule can find role dependencies
export ANSIBLE_ROLES_PATH="${PROJECT_ROOT}/${ROLES_DIR}"

# Set Ansible vault password file (if exists and not already set)
if [ -z "${ANSIBLE_VAULT_PASSWORD_FILE:-}" ] && [ -f "$HOME/.vault_pass.txt" ]; then
    export ANSIBLE_VAULT_PASSWORD_FILE="$HOME/.vault_pass.txt"
fi

# Load cache if exists
declare -A test_cache
if [ -f "$CACHE_FILE" ]; then
    while IFS='=' read -r role status; do
        test_cache["$role"]="$status"
    done < "$CACHE_FILE"
    echo "📋 Loaded test cache with $(wc -l < "$CACHE_FILE") entries"
fi

echo "🔍 Searching for Molecule scenarios in $ROLES_DIR..."
echo "📦 Using Ubuntu version: ${UBUNTU_MAJOR}.${UBUNTU_MINOR}"
echo "📁 Roles path: $ANSIBLE_ROLES_PATH"
if [ -n "${ANSIBLE_VAULT_PASSWORD_FILE:-}" ]; then
    echo "🔐 Vault password file: $ANSIBLE_VAULT_PASSWORD_FILE"
fi

# Find all roles and sort them for consistent ordering
mapfile -t role_dirs < <(find "$ROLES_DIR" -type d -name molecule | while read -r molecule_dir; do dirname "$molecule_dir"; done | sort)

total_roles=${#role_dirs[@]}
tested_count=0
passed_count=0
skipped_count=0
failed_count=0

for role_dir in "${role_dirs[@]}"; do
    role_name=$(basename "$role_dir")
    
    # Check if this role already passed in cache
    if [ "${test_cache[$role_dir]:-}" = "passed" ]; then
        echo "⏭️  Skipping $role_dir (already passed)"
        skipped_count=$((skipped_count + 1))
        continue
    fi
    
    echo "🔧 Testing role: $role_dir"
    tested_count=$((tested_count + 1))
    
    if (cd "$role_dir" && molecule test --scenario-name "$SCENARIO_NAME"); then
        echo "✅ $role_dir passed"
        # Update cache with success
        echo "$role_dir=passed" >> "$CACHE_FILE"
        passed_count=$((passed_count + 1))
    else
        echo "❌ $role_dir failed"
        # Update cache with failure
        echo "$role_dir=failed" >> "$CACHE_FILE"
        failed_count=$((failed_count + 1))
        echo ""
        echo "💥 Test failed at role: $role_dir"
        echo "📊 Summary: $tested_count tested, $passed_count passed, $skipped_count skipped, $failed_count failed (out of $total_roles total)"
        echo "🔄 Run 'make test' again to resume from this point"
        echo "🧹 Run 'make clean-test-cache' to start fresh"
        exit 1
    fi
done

echo ""
echo "🎉 All Molecule tests completed!"
echo "📊 Summary: $tested_count tested, $passed_count passed, $skipped_count skipped, $failed_count failed (out of $total_roles total)"

# Clean up cache on complete success
if [ -f "$CACHE_FILE" ]; then
    rm "$CACHE_FILE"
    echo "🧹 Cache cleared (all tests passed)"
fi
