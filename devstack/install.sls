# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "devstack/map.jinja" import devstack with context %}

# user/group are created before this state runs
include:
  - .user

openstack-devstack ensure package dependencies:
  pkg.installed:
    - names:
      {%- for pkg in devstack.pkgs %}
      - {{ pkg }}
      {%- endfor %}
  file.directory:
    - name: {{ devstack.dir.dest }}
    - dir_mode: '0755'
    - force: True

openstack-devstack git cloned and sudo access:
  git.latest:
    - name: {{ devstack.local.git_url }}
    - rev: {{ devstack.local.git_branch }}
    - target: {{ devstack.dir.dest }}
    - user: {{ devstack.local.username }}
    - force_clone: True
    - require:
      - user: openstack-devstack ensure user and group exist
      - pkg: openstack-devstack ensure package dependencies
  file.managed:
    - name: {{ devstack.local.sudoers_file }}
    - source: salt://devstack/files/devstack.sudoers
    - mode: 440
    - runas: root
    - user: root
    - makedirs: True
    - template: jinja
    - context:
      devusername: {{ devstack.local.username or 'stack' }}
    - require:
      - git: openstack-devstack git cloned and sudo access
    - require_in:
      - file: openstack-devstack configure local_conf

openstack-devstack configure local_conf:
  file.managed:
    - name: {{ devstack.dir.dest }}/local.conf
    - source: salt://devstack/files/local.conf.j2
    - user: {{ devstack.local.username }}
    - group: {{ devstack.local.username }}
    - makedirs: True
    - mode: {{ devstack.mode }}
    - template: jinja
    - context:
        data: {{ devstack.local|json }}
        dir:  {{ devstack.dir|json }}
  cmd.run:
    - names:
      - chown -R {{ devstack.local.username }}:{{ devstack.local.username }} {{ devstack.dir.dest }}

openstack-devstack run stack:
  cmd.run:
    - names:
      - {{ devstack.dir.dest }}/stack.sh
    - hide_output: {{ devstack.hide_output }}
    - env:
      - HOST_IP: {{ grains.ipv4[-1] if not devstack.local.host_ip else devstack.local.host_ip }}
      - HOST_IPV6: {{ grains.ipv6[-1] if not devstack.local.host_ipv6 else devstack.local.host_ipv6 }}
    - runas: {{ devstack.local.username }}
    - require:
      - file: openstack-devstack configure local_conf
      - cmd: openstack-devstack configure local_conf
