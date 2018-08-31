# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "devstack/map.jinja" import devstack with context %}

openstack-devstack ensure user and group absent:
  user.absent:
    - name: {{ devstack.local.username }}
    - force: True
    - purge: True
  cmd.run:
    - name: userdel -f {{ devstack.local.username }}
    - onlyif: getent passwd {{ devstack.local.username }}
    - onfail:
      - user: openstack-devstack cleandown
  group.absent:
    - name: {{ devstack.local.username }}
    - require:
      - cmd: openstack-devstack ensure user and group absent
