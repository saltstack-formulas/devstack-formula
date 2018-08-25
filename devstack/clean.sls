# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "devstack/map.jinja" import devstack with context %}

openstack-devstack unstack:
  cmd.run:
    - name: {{ devstack.dir.base }}/unstack.sh | true
    - runas: {{ devstack.user }}
    - onlyif: test -f {{ devstack.dir.base }}/unstack.sh && getent passwd {{ devstack.user }}
    - require_in:
      - user: openstack-devstack cleandown

openstack-devstack unstack and clean:
  cmd.run:
    - name: 'sudo bash {{ devstack.dir.base }}/clean.sh'
    - runas: {{ devstack.user }}
    - onlyif: test -f {{ devstack.dir.base }}/unstack.sh && getent passwd {{ devstack.user }}
    - require_in:
      - user: openstack-devstack cleandown

openstack-devstack cleandown:
  user.absent:
    - name: {{ devstack.user }}
    - purge: True
    - onlyif: getent passwd {{ devstack.user }}
  cmd.run:
    - name: userdel -f {{ devstack.user }}
    - onlyif: getent passwd {{ devstack.user }}
    - onfail:
      - user: openstack-devstack cleandown
  group.absent:
    - name: {{ devstack.user }}
    - onlyif: getent group {{ devstack.user }}
  file.absent:
    - names:
      - {{ devstack.dir.base }}
      - {{ devstack.dir.log }}/logs
    - require:
      - cmd: openstack-devstack cleandown
      - group: openstack-devstack cleandown
