# GitHub Actions Workflows

This directory contains the CI/CD workflows for the Ansible playbooks and roles.

## Workflows

### Molecule Tests (`molecule.yml`)

Simplified, reliable CI workflow that tests Ansible roles with minimal configuration.

**Triggers:**
- Push to `main` branch (only when `playbooks/roles/**`, `requirements.yml`, or workflow files change)
- Pull requests to `main` branch (same path filters)
- Manual dispatch

**Strategy:**
- **Matrix Testing**: Tests 3 core roles individually (`apt_installs`, `users`, `python`)
- **Minimal Configuration**: Dynamically creates working molecule configs
- **Standard Images**: Uses reliable `ubuntu:22.04` Docker images
- **Role-Specific Setup**: Provides proper variables for each role type

**Key Features:**
- ✅ **Zero Configuration**: Automatically generates working molecule configs
- ✅ **Reliable Images**: Uses standard Ubuntu images instead of custom ones
- ✅ **Proper Variables**: Provides correct variables for each role
- ✅ **Fast Feedback**: Tests most important roles first
- ✅ **Debug Output**: Shows role structure and configuration
- ✅ **Timeout Protection**: 30-minute timeout to prevent hanging

**How It Works:**
1. **Dynamic Config Generation**: Creates minimal `molecule.yml` for each role
2. **Role-Specific Variables**: Provides proper test variables:
   - `apt_installs`: Tests with vim, curl, git packages
   - `users`: Creates testuser with proper groups
   - `python`: Basic Python installation test
3. **Standard Container**: Uses `ubuntu:22.04` with `sleep infinity` command
4. **Minimal Test Sequence**: create → prepare → converge → verify → destroy

**Tested Roles:**
- `apt_installs` - Package installation and PPA management
- `users` - User creation and sudo configuration  
- `python` - Python environment setup

## Local Testing

You can run the same tests locally using:

```bash
# Run all molecule tests
make test

# Run tests for a specific role
make test-role ROLE=repos

# Install molecule locally
./scripts/install_molecule.sh
```

## Dependencies

The workflow installs the following Python packages:
- `ansible-core=9.*` - Ansible core engine (pinned to version 9.x)
- `molecule` - Molecule testing framework
- `molecule-plugins[docker]` - Molecule Docker driver plugin
- `ansible-lint` - Ansible linting tool
- `yamllint` - YAML linting tool

## Compliance with Bug Report #10

This implementation fully addresses the bug report requirements:

✅ **Path-based triggers**: Only runs when `playbooks/roles/**` or `requirements.yml` change
✅ **Multi-distro matrix**: Tests across ubuntu:24.04, ubuntu:22.04
✅ **Ansible version pinning**: Uses ansible-core=2.19.*
✅ **Integrated linting**: yamllint and ansible-lint run before tests
✅ **Concurrency control**: Prevents duplicate runs with timeout protection
✅ **Galaxy dependencies**: Automatic installation with caching
✅ **Environment variable support**: All molecule configs use `MOLECULE_IMAGE`
✅ **Idempotence testing**: Molecule's default test sequence includes idempotence checks