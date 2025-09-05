# Ansible Role Testing

This document describes the testing setup for Ansible roles in this repository.

## Overview

This repository uses [Molecule](https://molecule.readthedocs.io/) for testing Ansible roles. Each role that requires testing should have a `molecule/` directory with test scenarios.

## Test Script

The main test script is located at `scripts/test_all_roles.sh`. This script:

- ✅ Automatically discovers all roles with Molecule tests
- ✅ Activates virtual environment if available
- ✅ Provides colored output and progress tracking
- ✅ Tests each role individually
- ✅ Provides comprehensive summary with pass/fail counts
- ✅ Returns appropriate exit codes for CI/CD

### Usage

```bash
# Run all tests
./scripts/test_all_roles.sh

# Validate structure only (dry run)
./scripts/test_all_roles.sh --dry-run

# Show help
./scripts/test_all_roles.sh --help
```

## Prerequisites

### Local Development

1. **Python Virtual Environment** (recommended):
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

2. **Install Dependencies**:
   ```bash
   pip install 'molecule[docker]' molecule-plugins[docker] ansible-lint
   ```

3. **Install Ansible Collections**:
   ```bash
   ansible-galaxy collection install community.docker community.general ansible.posix
   ```

4. **Docker** (for running tests):
   ```bash
   # Ubuntu/Debian
   sudo apt-get install docker.io
   sudo systemctl start docker
   sudo usermod -aG docker $USER
   ```

### GitHub Actions CI

The repository includes two GitHub Actions workflows:

#### 1. `test-roles.yml` - Full Testing Workflow
- Runs on pull requests and pushes
- Sets up complete testing environment with Docker
- Runs all Molecule tests
- Uploads test artifacts

#### 2. `test-roles-simple.yml` - Lightweight Validation
- Runs linting and validation on every PR
- Only runs full tests when manually triggered or commit message contains `[test-roles]`
- More reliable in various CI environments

## Role Structure

Each testable role should have the following structure:

```
playbooks/roles/my-role/
├── tasks/
│   └── main.yml
├── molecule/
│   └── default/
│       ├── molecule.yml      # Molecule configuration
│       ├── converge.yml      # Test playbook
│       └── verify.yml        # Verification tests
├── meta/
│   └── main.yml
└── README.md
```

## Current Test Coverage

The repository currently has **13 roles** with Molecule tests:

- apt_installs
- astro_cli  
- aws
- cuda_toolkit
- dotfiles
- env_setup
- obsidian
- python
- R
- repos
- shell
- ssh
- users

## Running Individual Role Tests

To test a specific role:

```bash
cd playbooks/roles/my-role
molecule test
```

## Troubleshooting

### Common Issues

1. **Docker not found**: Ensure Docker is installed and running
2. **Permission denied**: Add your user to the docker group
3. **Collection not found**: Install required Ansible collections
4. **Network issues**: Some tests may fail due to network connectivity (e.g., downloading from Ansible Galaxy)

### Environment Variables

Useful environment variables for debugging:

```bash
export MOLECULE_VERBOSITY=2        # Increase verbosity
export ANSIBLE_FORCE_COLOR=1       # Force colored output
export MOLECULE_NO_LOG=false       # Show detailed logs
```

## Contributing

When adding new roles:

1. Include a `molecule/` directory with tests
2. Ensure tests pass locally before submitting PR
3. Update this documentation if needed

When modifying existing roles:

1. Run tests locally: `./scripts/test_all_roles.sh`
2. Fix any failing tests
3. Consider adding new tests for new functionality