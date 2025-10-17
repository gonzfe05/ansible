#!/bin/bash

# Test script for SSH agent setup
# This script verifies that the SSH agent is properly configured for git operations

set -e

echo "=== SSH Agent Test Script ==="

# Check if SSH agent environment file exists
SSH_AGENT_ENV="$HOME/.ssh/ssh-agent-env"
if [ ! -f "$SSH_AGENT_ENV" ]; then
    echo "❌ SSH agent environment file not found at $SSH_AGENT_ENV"
    exit 1
fi
echo "✅ SSH agent environment file found"

# Source the SSH agent environment
source "$SSH_AGENT_ENV"

# Check if SSH agent is running
if [ -z "$SSH_AGENT_PID" ]; then
    echo "❌ SSH_AGENT_PID not set"
    exit 1
fi

if ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
    echo "❌ SSH agent process (PID: $SSH_AGENT_PID) is not running"
    exit 1
fi
echo "✅ SSH agent is running (PID: $SSH_AGENT_PID)"

# Check if SSH_AUTH_SOCK is set and valid
if [ -z "$SSH_AUTH_SOCK" ]; then
    echo "❌ SSH_AUTH_SOCK not set"
    exit 1
fi

if [ ! -S "$SSH_AUTH_SOCK" ]; then
    echo "❌ SSH_AUTH_SOCK ($SSH_AUTH_SOCK) is not a valid socket"
    exit 1
fi
echo "✅ SSH_AUTH_SOCK is valid: $SSH_AUTH_SOCK"

# Check if SSH keys are loaded
ssh-add -L > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ No SSH keys loaded in the agent"
    exit 1
fi
echo "✅ SSH keys are loaded in the agent:"
ssh-add -L | while read -r key; do
    echo "  - $(echo "$key" | awk '{print $3}')"
done

# Check SSH config for GitHub
SSH_CONFIG="$HOME/.ssh/config"
if [ ! -f "$SSH_CONFIG" ]; then
    echo "❌ SSH config file not found at $SSH_CONFIG"
    exit 1
fi

if ! grep -q "Host github.com" "$SSH_CONFIG"; then
    echo "❌ GitHub configuration not found in SSH config"
    exit 1
fi
echo "✅ SSH config for GitHub found"

# Check git configuration
if ! git config --global --get url."git@github.com:".insteadOf > /dev/null 2>&1; then
    echo "❌ Git not configured to use SSH for GitHub"
    exit 1
fi
echo "✅ Git configured to use SSH for GitHub"

# Test SSH connection to GitHub (this will show authentication status)
echo "🔗 Testing SSH connection to GitHub..."
ssh_output=$(ssh -T git@github.com 2>&1 || true)
if echo "$ssh_output" | grep -q "successfully authenticated"; then
    echo "✅ SSH authentication to GitHub successful"
    echo "   $(echo "$ssh_output" | grep "successfully authenticated")"
else
    echo "⚠️  SSH authentication to GitHub failed or key not added to GitHub account"
    echo "   Output: $ssh_output"
    echo "   Note: Make sure your SSH public key is added to your GitHub account"
fi

echo ""
echo "=== SSH Agent Test Complete ==="
echo "✅ SSH agent is properly configured for git operations"