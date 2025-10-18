# Configuration Guide

## Ubuntu Version Configuration

This project uses parameterized Ubuntu versions for consistency across all molecule tests and container runs.

### Default Configuration

- **Default Ubuntu Version**: 24.04
- Defined as: `UBUNTU_MAJOR=24` and `UBUNTU_MINOR=04`
- All molecule tests use this version unless overridden
- The `make run` command also uses this version

### Available Versions

The following Ubuntu versions are supported with geerlingguy images:

- **24.04** (Noble Numbat) - `UBUNTU_MAJOR=24 UBUNTU_MINOR=04`
- **22.04** (Jammy Jellyfish) - `UBUNTU_MAJOR=22 UBUNTU_MINOR=04`
- **20.04** (Focal Fossa) - `UBUNTU_MAJOR=20 UBUNTU_MINOR=04`

### How to Change Versions

#### Method 1: Environment Variables (Recommended for Testing)

```bash
# Test all roles with Ubuntu 22.04
UBUNTU_MAJOR=22 UBUNTU_MINOR=04 make test

# Test all roles with Ubuntu 20.04
UBUNTU_MAJOR=20 UBUNTU_MINOR=04 make test
```

#### Method 2: Makefile Parameters

```bash
# Test with Ubuntu 22.04
make test ubuntu_major=22 ubuntu_minor=04

# Run container with Ubuntu 22.04
make run ubuntu_major=22 ubuntu_minor=04
```

#### Method 3: Export for Session

```bash
# Set for entire shell session
export UBUNTU_MAJOR=22
export UBUNTU_MINOR=04
make test
```

#### Method 4: Modify Makefile Defaults

Edit the makefile and change the default values:

```makefile
ubuntu_major ?= 22
ubuntu_minor ?= 04
```

### Vault Password Configuration

Some roles (like `ssh`) use Ansible Vault to encrypt sensitive files. The test script automatically looks for a vault password file at `~/.vault_pass.txt`.

#### Setup Vault Password File

```bash
# Create vault password file
echo "your-vault-password" > ~/.vault_pass.txt
chmod 600 ~/.vault_pass.txt
```

#### Using Custom Vault Password File

```bash
# Method 1: Environment variable
ANSIBLE_VAULT_PASSWORD_FILE=/path/to/vault_pass make test

# Method 2: Makefile parameter
make test vault_pass_file=/path/to/vault_pass

# Method 3: Set for entire session
export ANSIBLE_VAULT_PASSWORD_FILE=/path/to/vault_pass
make test
```

### Technical Details

- **Ubuntu version** is defined using two variables:
  - `UBUNTU_MAJOR` - Major version (e.g., `24`, `22`, `20`)
  - `UBUNTU_MINOR` - Minor version (e.g., `04`)
- **Image construction**:
  - Geerlingguy images: `geerlingguy/docker-ubuntu${UBUNTU_MAJOR}${UBUNTU_MINOR}-ansible` → `geerlingguy/docker-ubuntu2404-ansible`
  - Standard Ubuntu (CUDA): `ubuntu:${UBUNTU_MAJOR}.${UBUNTU_MINOR}` → `ubuntu:24.04`
- **No duplication** - Version is defined once and formatted as needed
- **ANSIBLE_ROLES_PATH** is automatically set to `/home/fer/ansible/playbooks/roles` by the test script so molecule can find role dependencies like `apt_installs`
- **ANSIBLE_VAULT_PASSWORD_FILE** is automatically set to `~/.vault_pass.txt` if the file exists and the variable is not already set

### Test Caching

The test script includes intelligent caching to speed up repeated test runs and resume from failures.

#### How It Works

- ✅ **Passed tests are cached** - Already-passed roles are skipped on subsequent runs
- 🔄 **Resume from failure** - When a test fails, run `make test` again to continue from that point
- 🧹 **Auto-cleanup** - Cache is automatically cleared when all tests pass
- 📊 **Progress tracking** - See how many tests were skipped, tested, passed, or failed

#### Cache Management

```bash
# Run tests (uses cache if available)
make test

# Clear the cache and start fresh
make clean-test-cache

# Then run all tests from the beginning
make test
```

#### Example Workflow

```bash
# First run - test fails at role "dotfiles"
make test
# Output: 📊 Summary: 5 tested, 4 passed, 0 skipped, 1 failed (out of 15 total)
# Output: 🔄 Run 'make test' again to resume from this point

# Fix the dotfiles role issue, then resume
make test
# Output: ⏭️  Skipping playbooks/roles/apt_installs (already passed)
# Output: ⏭️  Skipping playbooks/roles/aws (already passed)
# Output: ...continues from dotfiles

# All tests pass - cache auto-clears
# Output: 🧹 Cache cleared (all tests passed)

# Start fresh for next time
make test
```

### Examples

```bash
# Test vscode role with Ubuntu 20.04
cd playbooks/roles/vscode
UBUNTU_MAJOR=20 UBUNTU_MINOR=04 molecule test

# Test all roles with Ubuntu 22.04
UBUNTU_MAJOR=22 UBUNTU_MINOR=04 make test

# Run container with Ubuntu 24.04 (default)
make run

# Run container with Ubuntu 22.04
make run ubuntu_major=22 ubuntu_minor=04
```

### Files Using This Configuration

- All `playbooks/roles/*/molecule/default/molecule.yml` files
- `makefile` - defines default values
- `scripts/test_all_roles.sh` - exports the variable for tests

