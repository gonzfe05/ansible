Role Name
=========

Custom environment configs, mainly zsh as default shell with automatic .env file loading

Features
--------

- Sets zsh as the default shell
- Installs and configures Oh-My-Zsh
- Installs zsh-autosuggestions plugin
- Installs and configures zsh-autoenv plugin for automatic loading of .env files

The zsh-autoenv plugin automatically sources `.env` files when you enter a directory and can optionally source `.env.leave` files when you exit. This eliminates the need to manually run `source .env` each time you enter a project directory.

Requirements
------------

ansible
molecule[docker]
ansible-lint
zsh
git

Dependencies
------------

dotfiles

Example Playbook
----------------

- name: Converge
  hosts: instance
  become: yes
  become_user: root
  roles:
    - role: apt_installs
      vars:
        apt_installs_custom:
          - openssh-client
          - git
          - zsh
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
      become_password: ""
    - role: env_setup
      become: yes
      become_user: aleph


