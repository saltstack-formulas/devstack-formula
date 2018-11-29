# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "devstack/map.jinja" import devstack with context %}

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
  file.directory:
    - name: {{ devstack.dir.dest }}
    - user: {{ devstack.local.username }}
    - dir_mode: {{ devstack.dir_mode }}
    - group: {{ devstack.local.username }}
    - recurse:
      - user
      - group
      - mode

openstack-devstack ensure sudo rights:
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
      - user: openstack-devstack ensure user and group exist
