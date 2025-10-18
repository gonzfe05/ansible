SSH Role
========

Sets up SSH keys and SSH agent for secure git operations with GitHub.

Features
--------

- Installs SSH private and public keys
- Configures SSH agent for automatic key management
- Sets up persistent SSH agent across shell sessions
- Configures SSH client for GitHub operations
- Automatically adds SSH keys to the agent
- Creates SSH config for GitHub with proper settings

Requirements
------------

- ansible
- molecule[docker] (for testing)
- ansible-lint (for linting)
- openssh-client
- SSH key files (id_rsa and id_rsa.pub) in the role's files directory

Role Variables
--------------

- `source_key`: Name of the private key file (default: "id_rsa")
- `source_key_pub`: Name of the public key file (default: "id_rsa.pub")  
- `dest_key_private`: Destination path for private key (default: "{{ ansible_env.HOME }}/.ssh/id_rsa")
- `dest_key_pub`: Destination path for public key (default: "{{ ansible_env.HOME }}/.ssh/authorized_keys")

What This Role Does
------------------

1. **SSH Key Management:**
   - Creates ~/.ssh directory with proper permissions (700)
   - Copies SSH private key with secure permissions (600)
   - Copies SSH public key and adds to authorized_keys
   - Adds public key to user's authorized keys

2. **SSH Agent Setup:**
   - Kills any existing SSH agents to avoid conflicts
   - Starts a new SSH agent and saves environment to ~/.ssh/ssh-agent-env
   - Automatically adds SSH private key to the agent
   - Verifies SSH keys are properly loaded

3. **Persistent Agent Configuration:**
   - Adds SSH agent auto-start script to ~/.bashrc
   - Adds SSH agent auto-start script to ~/.zshrc (if exists)
   - Ensures agent survives shell restarts and reconnections
   - Automatically loads keys when starting new shells

4. **GitHub Integration:**
   - Creates SSH config file with GitHub-specific settings
   - Configures proper identity file and connection options
   - Adds github.com to known hosts automatically
   - Enables AddKeysToAgent for automatic key loading

5. **Git Configuration:**
   - The role works with git-setup tasks to configure git for SSH
   - Ensures git uses SSH instead of HTTPS for GitHub operations

Dependencies
------------

This role requires SSH key files to be present in the `files/` directory:
- `files/id_rsa` (private key)
- `files/id_rsa.pub` (public key)

Example Playbook
----------------

```yaml
- name: Converge
  hosts: instance
  become: yes
  become_user: root
  roles:
    - role: apt_installs
      vars:
        apt_installs_custom:
          - openssh-client
    - role: users
      vars:
        users:
          - name: aleph
            uid: 1001
            shell: /bin/bash
            comment: "Aleph User"
            groups: "admin,sudo,docker"
            password: ""
    - role: ssh
      become: yes
      become_user: aleph
```

Testing
-------

The role includes comprehensive molecule tests that verify:
- SSH client installation and availability
- SSH directory and key file creation
- SSH agent environment file creation
- SSH config file for GitHub
- Shell integration (bashrc/zshrc)
- SSH agent functionality
- GitHub SSH connection (requires valid key in GitHub account)

Use the included test script to verify SSH agent setup:
```bash
./scripts/test-ssh-agent.sh
```

Troubleshooting
--------------

**SSH Agent Not Starting:**
- Check if ~/.ssh/ssh-agent-env file exists and has proper permissions
- Verify SSH private key exists and has correct permissions (600)
- Check shell startup files (.bashrc/.zshrc) for SSH agent configuration

**GitHub Authentication Fails:**
- Ensure your SSH public key is added to your GitHub account
- Verify SSH config file exists at ~/.ssh/config
- Test connection manually: `ssh -T git@github.com`

**Git Operations Still Use HTTPS:**
- Check git configuration: `git config --global --get url."git@github.com:".insteadOf`
- Should return: `https://github.com/`
- Re-run git-setup tasks if needed