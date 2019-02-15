# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "devstack/map.jinja" import devstack with context %}

openstack devstack ensure user and group exist:
  group.present:
    - name: {{ devstack.local.stack_user }}
  user.present:
    - name: {{ devstack.local.stack_user }}
    - fullname: DevStack User
    - shell: /bin/bash
    - home: {{ devstack.dir.dest }}
    - createhome: True
    - groups:
      - {{ devstack.local.stack_user }}
    - require:
      - group: openstack devstack ensure user and group exist
  file.directory:
    - names:
      - {{ devstack.dir.dest }}
      - {{ devstack.dir.tmp }}
    - user: {{ devstack.local.stack_user }}
    - group: {{ devstack.local.stack_user }}
    - dir_mode: {{ devstack.dir_mode }}
    - recurse:
      - user
      - group
      - mode

openstack devstack ensure sudo rights:
  file.managed:
    - name: {{ devstack.local.sudoers_file }}
    - source: salt://devstack/files/devstack.sudoers
    - mode: 440
    - runas: root
    - user: root
    - makedirs: True
    - template: jinja
    - context:
      stack_user: {{ devstack.local.stack_user }}
    - require:
      - user: openstack devstack ensure user and group exist
