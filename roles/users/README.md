Role Name
=========

Creates users with the defined privilages

Requirements
------------

ansible
molecule[docker]
ansible-lint

Role Variables
--------------

users
required_groups

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
    - role: users