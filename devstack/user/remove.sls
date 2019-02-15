# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "devstack/map.jinja" import devstack with context %}

openstack devstack ensure user and group absent:
  user.absent:
    - name: {{ devstack.local.stack_user }}
    - force: True
    - purge: True
  cmd.run:
    - name: userdel -f {{ devstack.local.stack_user }}
    - onlyif: getent passwd {{ devstack.local.stack_user }}
    - onfail:
      - user: openstack devstack cleandown
  group.absent:
    - name: {{ devstack.local.stack_user }}
    - require:
      - cmd: openstack devstack ensure user and group absent
