# Zsh-Autoenv Setup and Usage Guide

## Overview

This repository now includes automatic setup of the `zsh-autoenv` plugin, which automatically loads environment variables from `.env` files when you enter a directory. This solves the issue described in [Issue #6](https://github.com/gonzfe05/ansible/issues/6).

## What is zsh-autoenv?

`zsh-autoenv` is a Zsh plugin that automatically sources `.env` files when you navigate into a directory containing them. This eliminates the need to manually run `source .env` each time you enter a project directory.

## How it Works

The Ansible roles (`shell` and `env_setup`) now automatically:

1. Clone the `zsh-autoenv` plugin from GitHub into `~/.oh-my-zsh/custom/plugins/zsh-autoenv`
2. Configure your `.zshrc` file to source and enable the plugin
3. Set appropriate environment variables for plugin configuration

## Configuration Details

The following configuration is automatically added to your `.zshrc`:

```bash
# Enable zsh-autoenv plugin for automatic .env file loading
source ~/.oh-my-zsh/custom/plugins/zsh-autoenv/autoenv.zsh

# zsh-autoenv settings
export AUTOENV_FILE_ENTER=.env
export AUTOENV_FILE_LEAVE=.env.leave
export AUTOENV_LOOK_UPWARDS=1
```

### Configuration Options

- **AUTOENV_FILE_ENTER**: The filename to look for when entering a directory (default: `.env`)
- **AUTOENV_FILE_LEAVE**: The filename to source when leaving a directory (default: `.env.leave`)
- **AUTOENV_LOOK_UPWARDS**: Look for `.env` files in parent directories (1 = enabled)

## Usage Examples

### Basic Usage

1. Create a directory with a `.env` file:

```bash
mkdir myproject
cd myproject
echo 'export API_URL=http://example.com' > .env
echo 'export API_KEY=your_secret_key' > .env
```

2. The first time you enter the directory, `zsh-autoenv` will ask for confirmation:

```
Attempting to load unauthorized env file!
-rw-r--r-- 1 user user 48 Oct 18 10:00 /home/user/myproject/.env

**********************************************

export API_URL=http://example.com
export API_KEY=your_secret_key

**********************************************

Would you like to authorize it? (type 'yes') yes
```

3. After authorization, the environment variables will be loaded automatically every time you `cd` into that directory:

```bash
cd myproject
echo $API_URL  # outputs: http://example.com
```

### Using .env.leave Files

You can also create a `.env.leave` file to unset variables when leaving a directory:

```bash
# In myproject/.env.leave
unset API_URL
unset API_KEY
```

Now when you leave the directory, these variables will be automatically unset:

```bash
cd myproject
echo $API_URL  # outputs: http://example.com
cd ..
echo $API_URL  # outputs: (empty)
```

### Security Considerations

- `zsh-autoenv` will ask for confirmation the first time it encounters a new `.env` file
- Authorized files are stored in `~/.autoenv_authorized`
- If a `.env` file changes, you'll be prompted to re-authorize it
- Never authorize `.env` files from untrusted sources

## Testing the Setup

After running the Ansible playbook, you can test the setup with these steps:

1. Open a new terminal or source your `.zshrc`:
```bash
source ~/.zshrc
```

2. Verify the plugin is installed:
```bash
ls -la ~/.oh-my-zsh/custom/plugins/zsh-autoenv
```

3. Test with a sample project:
```bash
mkdir ~/test_autoenv
cd ~/test_autoenv
echo 'export TEST_VAR=hello_world' > .env
cd ~/test_autoenv  # zsh-autoenv will prompt for authorization
echo $TEST_VAR     # Should output: hello_world
```

## Running the Playbook

To apply this configuration, run the playbook that includes either the `shell` or `env_setup` role:

```bash
ansible-playbook playbooks/after_format.yaml
```

Or test with molecule:

```bash
cd playbooks/roles/shell
molecule test
```

## Troubleshooting

### Plugin not working

1. Check if the plugin is installed:
```bash
ls ~/.oh-my-zsh/custom/plugins/zsh-autoenv
```

2. Check if it's configured in `.zshrc`:
```bash
grep autoenv ~/.zshrc
```

3. Make sure you're using zsh:
```bash
echo $SHELL
```

### Permission issues

If you see permission errors, ensure the `.env` files have appropriate permissions:
```bash
chmod 644 .env
```

### Variables not loading

1. Check if the `.env` file is authorized:
```bash
cat ~/.autoenv_authorized
```

2. Try re-authorizing by removing the entry and re-entering the directory:
```bash
# Edit ~/.autoenv_authorized and remove the line for your .env file
cd /path/to/your/project
```

## Additional Resources

- [zsh-autoenv GitHub Repository](https://github.com/Tarrasch/zsh-autoenv)
- [Original Issue #6](https://github.com/gonzfe05/ansible/issues/6)

## Related Roles

- `shell` - Sets up zsh with oh-my-zsh and plugins including zsh-autoenv
- `env_setup` - Alternative role with the same functionality
- `dotfiles` - Manages dotfiles using GNU Stow

