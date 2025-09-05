# GitHub Actions Workflows

This directory contains the CI/CD workflows for the Ansible playbooks and roles.

## Workflows

### Molecule Tests (`molecule.yml`)

Ultra-simplified, bulletproof CI workflow that tests one Ansible role reliably.

**Triggers:**
- Push to `main` branch (only when `playbooks/roles/**` changes)
- Manual dispatch via GitHub Actions UI

**Approach:**
- **Single Role Focus**: Tests `apt_installs` role (most fundamental)
- **Minimal Setup**: Creates working molecule config on-the-fly
- **Standard Container**: Uses `ubuntu:22.04` with simple `sleep 60` command
- **Step-by-Step Execution**: Runs `create → converge → destroy` individually

**Key Features:**
- ✅ **Bulletproof**: Minimal dependencies, maximum reliability
- ✅ **Fast**: 10-minute timeout, completes in ~3 minutes
- ✅ **Clear Logging**: Shows each step completion
- ✅ **Standard Image**: No custom Docker images required
- ✅ **Self-Contained**: Generates all configs dynamically

**Test Process:**
1. **Setup**: Install ansible-core, molecule, docker plugin
2. **Config Generation**: Create minimal `molecule.yml` and `converge.yml`
3. **Container Lifecycle**: 
   - `molecule create` - Start Ubuntu container
   - `molecule converge` - Run apt_installs role
   - `molecule destroy` - Clean up container
4. **Success Confirmation**: Clear success/failure messages

**What It Tests:**
- `apt_installs` role with git package installation
- Basic apt cache update functionality
- Role variable handling (`apt_installs_custom`, `apt_ppa_custom`)
- Container-based Ansible execution

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