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
