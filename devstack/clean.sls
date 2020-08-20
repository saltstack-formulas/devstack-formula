# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "devstack/map.jinja" import devstack with context %}

# user/group are not deleted until this state runs!
include:
  - .user.remove

  {%- if salt['cmd.run']('getent passwd ' ~ devstack.local.stack_user, output_loglevel='quiet') %}

openstack devstack clean check permissions:
  file.directory:
    - names:
      - {{ devstack.dir.tmp }}
      - {{ devstack.dir.dest }}
      - {{ devstack.dir.dest }}/.cache   # workaround
    - makedirs: True
    - force: True
    - user: {{ devstack.local.stack_user }}
    - group: {{ devstack.local.stack_user }}
    - dir_mode: '0755'
    - recurse:
      - user
      - mode
    - require_in:
      - cmd: openstack devstack clean unstack

openstack devstack clean unstack:
  cmd.run:
    - name: sudo {{ devstack.dir.dest }}/unstack.sh | true
    - env:
      - HOST_IP: {{ '127.0.0.1' if not devstack.local.host_ipv4 else devstack.local.host_ipv4 }}
      - HOST_IPV6: {{ devstack.local.host_ipv6 }}
    - runas: {{ devstack.local.stack_user }}
    - onlyif: test -f {{devstack.local.sudoers_file}} && getent passwd {{devstack.local.stack_user}}
    - require_in:
      - file: openstack devstack clean cleandown
      - user: openstack devstack clean ensure user and group absent

openstack devstack clean clean:
  cmd.run:
    - name: sudo {{ devstack.dir.dest }}/clean.sh
    - env:
      - HOST_IP: {{ '127.0.0.1' if not devstack.local.host_ipv4 else devstack.local.host_ipv4 }}
      - HOST_IPV6: {{ devstack.local.host_ipv6 }}
    - runas: {{ devstack.local.stack_user }}
    - onlyif: test -f {{devstack.local.sudoers_file}} && getent passwd {{devstack.local.stack_user}}
    - require_in:
      - file: openstack devstack clean cleandown
      - user: openstack devstack clean ensure user and group absent

  {%- endif %}

openstack devstack clean cleandown:
  user.absent:
    - name: {{ devstack.local.stack_user }}
    - purge: True
  cmd.run:
    - name: userdel -f -r {{ devstack.local.stack_user }}
    - onlyif: getent passwd {{ devstack.local.stack_user }}
    - onfail:
      - user: openstack devstack clean cleandown
  group.absent:
    - name: {{ devstack.local.stack_user }}
  file.absent:
    - names:
      - {{ devstack.dir.dest }}
      - {{ devstack.dir.log }}/logs
      - {{ devstack.local.sudoers_file }}
    - require:
      - user: openstack devstack clean ensure user and group absent
