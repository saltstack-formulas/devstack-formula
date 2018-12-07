# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "devstack/map.jinja" import devstack with context %}

# user sls creates required user/group/destdir first
include:
  - .user

openstack-devstack ensure package dependencies:
  file.directory:
    - name: {{ devstack.dir.tmp }}/devstack
    - makedirs: True
    - force: True
    - user: {{ devstack.local.username or 'stack' }}
    - dir_mode: '0755'
    - recurse:
      - user
      - mode
  pkg.installed:
    - names:
      {%- for pkg in devstack.pkgs %}
      - {{ pkg }}
      {%- endfor %}

openstack-devstack git cloned:
  git.latest:
    - name: {{ devstack.local.git_url }}
    - rev: {{ devstack.local.git_branch }}
    - target: {{ devstack.dir.dest }}
    - user: {{ devstack.local.username }}
    - force_clone: True
    - require:
      - user: openstack-devstack ensure user and group exist
      - pkg: openstack-devstack ensure package dependencies

openstack-devstack configure stackrc:
  file.managed:
    - name: {{ devstack.dir.dest }}/stackrc
    - source: salt://devstack/files/stackrc.j2
    - user: {{ devstack.local.username }}
    - group: {{ devstack.local.username }}
    - makedirs: True
    - mode: {{ devstack.mode }}
    - template: jinja
    - context:
        data: {{ devstack.local|json }}
        dir:  {{ devstack.dir|json }}

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
      - chown -R {{devstack.local.username}}:{{devstack.local.username}} {{devstack.dir.dest}} {{devstack.dir.tmp}}/devstack

openstack-devstack run stack:
  cmd.run:
    - name: {{ devstack.dir.dest }}/stack.sh
    - hide_output: {{ devstack.hide_output }}
    - env:
      - HOST_IP: {{grains.ipv4[-1] if not devstack.local.host_ip else devstack.local.host_ip}}
      - HOST_IPV6: {{grains.ipv6[-1] if not devstack.local.host_ipv6 else devstack.local.host_ipv6}}
    - runas: {{ devstack.local.username }}
    - require:
      - file: openstack-devstack configure local_conf
      - cmd: openstack-devstack configure local_conf
