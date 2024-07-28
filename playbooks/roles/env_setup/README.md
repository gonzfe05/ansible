Role Name
=========

Custom environment configs, mainly zsh as default shell

Requirements
------------

ansible
molecule[docker]
ansible-lint
zsh

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
            groups: "admin,sudo"
            password: ""
    - role: ssh
      become: yes
      become_user: aleph
      become_password: ""
    - role: env_setup
      become: yes
      become_user: aleph


