# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import devstack with context %}

devstack-config-clean:
  file.absent:
    - names:
      - {{ devstack.dir.dest }}/openrc
      - {{ devstack.local.sudoers_file }}
    - require_in:
      - group: devstack-config-clean
  user.absent:
    - name: {{ devstack.local.stack_user }}
    - force: True
    - purge: True
    - require_in:
      - group: devstack-config-clean
  cmd.run:
    - name: userdel -f {{ devstack.local.stack_user }}
    - onlyif: getent passwd {{ devstack.local.stack_user }}
    - onfail:
      - user: devstack-config-clean
    - require_in:
      - group: devstack-config-clean
  group.absent:
    - name: {{ devstack.local.stack_user }}
