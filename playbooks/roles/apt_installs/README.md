Role Name
=========

Installs packages using apt

Requirements
------------

ansible
molecule[docker]
ansible-lint

Role Variables
--------------

apt_installs_custom: List of packages to install

Dependencies
------------

-

Example Playbook
----------------

- hosts: servers
  vars:
    apt_installs_custom:
      - vim
      - curl
      - git
  roles:
    - role: apt_installs


