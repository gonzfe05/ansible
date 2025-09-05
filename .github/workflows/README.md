# GitHub Actions Workflows

This directory contains the CI/CD workflows for the Ansible playbooks and roles.

## Workflows

### Molecule Tests (`molecule.yml`)

Runs Molecule tests for all Ansible roles with multi-distro testing matrix.

**Triggers:**
- Push to `main` branch (only when `playbooks/roles/**`, `requirements.yml`, or workflow files change)
- Pull requests to `main` branch (same path filters)
- Manual dispatch

**Features:**
- **Path-based Triggers**: Only runs when relevant files change
- **Multi-distro Matrix**: Tests across Ubuntu 24.04, 22.04, and Debian 12
- **Concurrency Control**: Prevents multiple runs on the same ref
- **Timeout Protection**: 45-minute timeout to prevent hanging jobs
- **Galaxy Dependencies**: Automatic installation of Ansible Galaxy requirements
- **Integrated Linting**: Runs yamllint and ansible-lint before tests
- **Environment Variable Support**: Uses `MOLECULE_IMAGE` for dynamic distro selection

**Matrix Strategy:**
- Ansible Core: 9.*
- Distros: ubuntu:24.04, ubuntu:22.04, debian:12
- Fail-fast: Disabled (all combinations tested even if some fail)

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
✅ **Multi-distro matrix**: Tests across ubuntu:24.04, ubuntu:22.04, debian:12
✅ **Ansible version pinning**: Uses ansible-core=9.*
✅ **Integrated linting**: yamllint and ansible-lint run before tests
✅ **Concurrency control**: Prevents duplicate runs with timeout protection
✅ **Galaxy dependencies**: Automatic installation with caching
✅ **Environment variable support**: All molecule configs use `MOLECULE_IMAGE`
✅ **Idempotence testing**: Molecule's default test sequence includes idempotence checks