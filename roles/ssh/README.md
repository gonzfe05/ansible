Role Name
=========

Sets up ssh

Requirements
------------

ansible
molecule[docker]
ansible-lint
openssh-client

Role Variables
--------------

apt_installs

Dependencies
------------

-

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