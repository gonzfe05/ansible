# GitHub Actions Workflows

This directory contains the CI/CD workflows for the Ansible playbooks and roles.

## Workflows

### 1. Molecule Tests (`molecule.yml`)

Runs Molecule tests for all Ansible roles that have molecule configurations.

**Triggers:**
- Push to `main`/`master` branches
- Pull requests to `main`/`master` branches
- Manual dispatch

**Jobs:**
- **discover**: Automatically discovers all roles with molecule tests
- **molecule**: Runs molecule tests for each role in parallel using a matrix strategy
- **test-all**: Runs the existing `scripts/test_all_roles.sh` script as validation
- **summary**: Provides a summary of all test results

**Features:**
- Parallel execution of tests for better performance
- Automatic role discovery (no need to manually maintain a list)
- Docker-based testing using the same configuration as local development
- Caching of pip dependencies for faster builds

### 2. Lint (`lint.yml`)

Runs linting checks on YAML files and Ansible code.

**Triggers:**
- Push to `main`/`master` branches
- Pull requests to `main`/`master` branches
- Manual dispatch

**Jobs:**
- **yaml-lint**: Validates YAML syntax across the repository
- **ansible-lint**: Runs ansible-lint on playbooks and roles

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

The workflows install the following Python packages:
- `molecule[docker]` - Molecule testing framework with Docker driver
- `ansible-lint` - Ansible linting tool
- `yamllint` - YAML linting tool
- `docker` - Docker Python client

See `requirements.txt` for specific versions.