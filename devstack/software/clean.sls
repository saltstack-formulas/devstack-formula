# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_config_clean = tplroot ~ '.config.clean' %}
{%- from tplroot ~ "/map.jinja" import devstack with context %}

include:
  - {{ sls_config_clean }}

    {%- if salt['cmd.run']('getent passwd ' ~ devstack.local.stack_user, output_loglevel='quiet') %}

devstack-software-clean-unstack:
  cmd.run:
    - names:
      - {{ devstack.dir.dest }}/unstack.sh | true
      - {{ devstack.dir.dest }}/clean.sh | true
    - runas: {{ devstack.local.stack_user }}
    - onlyif: test -x {{ devstack.dir.dest }}/unstack.sh
    - env:
      - HOST_IP: {{ '127.0.0.1' if not devstack.local.host_ipv4 else devstack.local.host_ipv4 }}
      - HOST_IPV6: {{ devstack.local.host_ipv6 }}
    - require_in:
      - file: devstack-software-clean-absent

    {%- endif %}

devstack-software-clean:
  file.absent:
    - names:
      - {{ devstack.dir.dest }}
