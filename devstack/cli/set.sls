# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "devstack/map.jinja" import devstack with context %}
{% from "devstack/files/macros.jinja" import getcmd, getopts, getlist with context %}

    {% for feature, task in devstack.cli.items() %}
      {%- if "set" in devstack.cli[feature] and devstack.cli[feature]['set'] is mapping %}
        {% for item, itemdata in devstack.cli[feature]['set'].items() %}

devstack_{{ feature }}_set_{{ item }}:
  cmd.run:
    - name: source ${DEV_STACK_DIR}/openrc admin admin && openstack {{ feature }} set {{ getcmd(itemdata) }} {{ item }}
    - onlyif: openstack {{ feature }} show {{ item }} 2>/dev/null
    - runas: {{ devstack.local.username }}
    - env:
      - DEV_STACK_DIR: {{ devstack.dir.dest }}

        {% endfor %}
      {%- endif %}
    {% endfor %}
