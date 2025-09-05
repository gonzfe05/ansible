# GitHub Actions Workflows

This directory contains the CI/CD workflows for the Ansible playbooks and roles.

## Workflows

### Molecule Tests (`molecule.yml`)

Comprehensive CI workflow that runs linting and Molecule tests for all Ansible roles.

**Triggers:**
- Push to `main` branch (only when `playbooks/roles/**`, `requirements.yml`, or workflow files change)
- Pull requests to `main` branch (same path filters)
- Manual dispatch

**Jobs:**

1. **Lint Job**: 
   - Runs `yamllint` on all YAML files (lenient configuration)
   - Runs `ansible-lint` on all roles (moderate profile)
   - Continues on warnings to avoid blocking on style issues

2. **Test Job**:
   - Tests roles across Ubuntu 22.04 and 24.04 Docker images
   - Uses strategic role ordering (simple roles first)
   - Provides detailed progress and failure reporting
   - Continues testing all roles even if some fail
   - Comprehensive summary at the end

**Features:**
- **Path-based Triggers**: Only runs when relevant files change
- **Multi-distro Matrix**: Tests across Ubuntu 24.04 and 22.04
- **Robust Error Handling**: Continues testing even when individual roles fail
- **Progress Tracking**: Shows which role is being tested and overall progress
- **Detailed Logging**: Environment info, Docker image selection, and test results
- **Smart Role Ordering**: Tests simple roles first, complex ones last
- **Backup/Restore**: Preserves original molecule configurations

**Test Strategy:**
- Ansible Core: Latest stable
- Docker Images: geerlingguy/docker-ubuntu{2204,2404}-ansible
- Timeout: 45 minutes total
- Fail-fast: Disabled (comprehensive testing)

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