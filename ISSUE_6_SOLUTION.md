# Solution for Issue #6: Auto Load Environment Variables from Folders

## Problem Statement

Environment variables from `.env` files were not automatically loaded when entering directories in zsh, requiring manual `source .env` commands each time.

## Solution Implemented

The solution implements the `zsh-autoenv` plugin as suggested in the original issue. This plugin automatically sources `.env` files when you navigate into directories containing them.

## Changes Made

### 1. Updated Ansible Roles

Modified both `shell` and `env_setup` roles to include zsh-autoenv setup:

**Files Modified:**
- `/home/fer/ansible/playbooks/roles/shell/tasks/main.yml`
- `/home/fer/ansible/playbooks/roles/env_setup/tasks/main.yml`

**Changes:**
- Added task to check if zsh-autoenv is installed
- Added task to clone zsh-autoenv from GitHub repository
- Added task to configure zsh-autoenv in `.zshrc`
- Configuration includes:
  - Sourcing the autoenv.zsh script
  - Setting `AUTOENV_FILE_ENTER=.env`
  - Setting `AUTOENV_FILE_LEAVE=.env.leave`
  - Setting `AUTOENV_LOOK_UPWARDS=1` to search parent directories

### 2. Updated Documentation

**Files Modified:**
- `/home/fer/ansible/playbooks/roles/shell/README.md`
- `/home/fer/ansible/playbooks/roles/env_setup/README.md`

Added comprehensive features section describing:
- zsh setup
- oh-my-zsh installation
- zsh-autosuggestions plugin
- **zsh-autoenv plugin** (NEW)

### 3. Enhanced Testing

**Files Modified:**
- `/home/fer/ansible/playbooks/roles/shell/molecule/default/verify.yml`
- `/home/fer/ansible/playbooks/roles/env_setup/molecule/default/verify.yml`

Added verification tests for:
- zsh-autoenv plugin directory existence
- zsh-autoenv configuration in `.zshrc`

### 4. Created User Guide

**Files Created:**
- `/home/fer/ansible/ZSH_AUTOENV_GUIDE.md`

Comprehensive guide covering:
- Plugin overview
- Configuration details
- Usage examples
- Security considerations
- Troubleshooting tips

## How It Works

1. When the Ansible playbook runs, it:
   - Clones zsh-autoenv into `~/.oh-my-zsh/custom/plugins/zsh-autoenv`
   - Adds configuration to `~/.zshrc` using an Ansible managed block

2. When you enter a directory with a `.env` file:
   - zsh-autoenv detects the file
   - On first encounter, prompts for authorization (security feature)
   - After authorization, automatically sources the file
   - Variables become available in your shell

3. When you leave the directory:
   - If a `.env.leave` file exists, it's automatically sourced
   - Useful for unsetting variables

## Testing the Solution

### Automated Testing (Molecule)

Run molecule tests for the roles:

```bash
# Test shell role
cd playbooks/roles/shell
molecule test

# Test env_setup role
cd playbooks/roles/env_setup
molecule test
```

### Manual Testing

1. **Run the playbook:**
   ```bash
   ansible-playbook playbooks/after_format.yaml --tags core
   ```

2. **Test the functionality:**
   ```bash
   # Create test directory
   mkdir ~/test_env && cd ~/test_env
   
   # Create .env file
   echo 'export API_URL=http://example.com' > .env
   
   # Exit and re-enter directory
   cd ..
   cd test_env  # zsh-autoenv will prompt for authorization
   
   # Verify variable is loaded
   echo $API_URL  # Should output: http://example.com
   ```

3. **Test cleanup on directory exit:**
   ```bash
   # Create .env.leave file
   echo 'unset API_URL' > .env.leave
   
   # Exit directory
   cd ..
   
   # Verify variable is unset
   echo $API_URL  # Should be empty
   ```

## Verification Steps

After running the playbook, verify the installation:

```bash
# 1. Check plugin is installed
ls -la ~/.oh-my-zsh/custom/plugins/zsh-autoenv

# 2. Check configuration in .zshrc
grep -A 5 "ANSIBLE MANAGED BLOCK - ZSH AUTOENV" ~/.zshrc

# 3. Check zsh-autoenv is sourced
grep "autoenv.zsh" ~/.zshrc

# 4. Restart shell or source .zshrc
source ~/.zshrc
```

## Playbooks Affected

The following playbooks will automatically include this fix:

1. **`playbooks/after_format.yaml`** - Main setup playbook
2. **`playbooks/container.yaml`** - Container setup playbook

Both use the `env_setup` role which now includes zsh-autoenv.

## Security Features

zsh-autoenv includes important security features:

1. **Authorization Required**: First time encountering a `.env` file, user must explicitly authorize it
2. **Content Preview**: Shows file contents before authorization
3. **Change Detection**: If a `.env` file changes, re-authorization is required
4. **Authorized Files List**: Maintains list at `~/.autoenv_authorized`

## Additional Configuration Options

Users can customize zsh-autoenv by modifying these variables in their `.zshrc`:

```bash
# Change the filename to look for
export AUTOENV_FILE_ENTER=.autoenv

# Disable looking in parent directories
export AUTOENV_LOOK_UPWARDS=0

# Change leave file name
export AUTOENV_FILE_LEAVE=.autoenv_leave
```

## References

- Original Issue: [Issue #6](https://github.com/gonzfe05/ansible/issues/6)
- zsh-autoenv GitHub: [Tarrasch/zsh-autoenv](https://github.com/Tarrasch/zsh-autoenv)
- User Guide: `ZSH_AUTOENV_GUIDE.md`

## Benefits

✅ No more manually running `source .env` when entering project directories
✅ Automatic environment isolation per project
✅ Security-first approach with authorization prompts
✅ Seamless integration with existing zsh setup
✅ Support for cleanup on directory exit
✅ Parent directory lookup for shared configs

## Rollout Plan

1. ✅ Implement solution in `shell` and `env_setup` roles
2. ✅ Add comprehensive testing
3. ✅ Update documentation
4. ✅ Create user guide
5. ⏳ Test with molecule
6. ⏳ Deploy to test environment
7. ⏳ Get user feedback
8. ⏳ Merge to main branch
9. ⏳ Close Issue #6

## Future Enhancements

Potential improvements for future iterations:

- Add role variable to enable/disable zsh-autoenv
- Add support for custom file names via role variables
- Create example `.env` templates
- Add integration with vault for secure credential management
- Create helper script to quickly authorize all `.env` files in a directory tree

