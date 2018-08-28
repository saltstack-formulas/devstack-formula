# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "devstack/map.jinja" import devstack with context %}

  {%- if salt['cmd.run']('getent passwd ' ~ devstack.local.username, output_loglevel='quiet') %}

openstack-devstack unstack:
  cmd.run:
    - name: sudo {{ devstack.dir.dest }}/unstack.sh | true
    - env:
      - HOST_IP: {{ grains.ipv4[-1] if not devstack.local.host_ip else devstack.local.host_ip }}
      - HOST_IPV6: {{ grains.ipv6[-1] if not devstack.local.host_ipv6 else devstack.local.host_ipv6 }}
    - runas: {{ devstack.local.username }}
    - onlyif: test -f {{ devstack.local.sudoers_file }} && getent passwd {{ devstack.local.username }}
    - require_in:
      - user: openstack-devstack cleandown

openstack-devstack clean:
  cmd.run:
    - name: sudo {{ devstack.dir.dest }}/clean.sh
    - env:
      - HOST_IP: {{ grains.ipv4[-1] if not devstack.local.host_ip else devstack.local.host_ip }}}
      - HOST_IPV6: {{ grains.ipv6[-1] if not devstack.local.host_ipv6 else devstack.local.host_ipv6 }}}
    - runas: {{ devstack.local.username }}
    - onlyif: test -f {{ devstack.local.sudoers_file }} && getent passwd {{ devstack.local.username }}
    - require_in:
      - user: openstack-devstack cleandown

  {%- endif %}

openstack-devstack cleandown:
  user.absent:
    - name: {{ devstack.local.username }}
    - purge: True
  cmd.run:
    - name: userdel -f {{ devstack.local.username }}
    - onlyif: getent passwd {{ devstack.local.username }}
    - onfail:
      - user: openstack-devstack cleandown
  group.absent:
    - name: {{ devstack.local.username }}
  file.absent:
    - names:
      - {{ devstack.dir.dest }}
      - {{ devstack.dir.log }}/logs
      - {{ devstack.local.sudoers_file }}
    - require:
      - cmd: openstack-devstack cleandown
