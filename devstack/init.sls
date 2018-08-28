# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "devstack/map.jinja" import devstack with context %}

openstack-devstack ensure package dependencies:
  pkg.installed:
    - names:
      {%- for pkg in devstack.pkgs %}
      - {{ pkg }}
      {%- endfor %}

openstack-devstack ensure user and group exist:
  group.present:
    - name: {{ devstack.local.username }}
  user.present:
    - name: {{ devstack.local.username }}
    - fullname: DevStack User
    - shell: /bin/bash
    - home: {{ devstack.dir.dest }}
    - createhome: True
    - groups:
      - {{ devstack.local.username }}
    - require:
      - group: openstack-devstack ensure user and group exist
    - require_in:
      - file: openstack-devstack ensure user and group exist
      - file: openstack-devstack configure local_conf and run stack
      - git: openstack-devstack git cloned and sudo access
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
      - file: openstack-devstack configure local_conf and run stack

openstack-devstack configure local_conf and run stack:
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
      - {{ devstack.dir.dest }}/stack.sh
    - env:
      - HOST_IP: {{ grains.ipv4[-1] if not devstack.local.host_ip else devstack.local.host_ip }}
      - HOST_IPV6: {{ grains.ipv6[-1] if not devstack.local.host_ipv6 else devstack.local.host_ipv6 }}
    - runas: {{ devstack.local.username }}
    - require:
      - file: openstack-devstack configure local_conf and run stack
