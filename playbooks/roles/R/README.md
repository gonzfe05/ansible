Role Name
=========

Sets up R programming language

Requirements
------------

ansible
molecule[docker]
ansible-lint

Dependencies
------------

apt_installs

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
          - stow
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
    - role: R
      become: yes
      become_user: aleph

