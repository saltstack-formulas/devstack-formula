# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "devstack/map.jinja" import devstack with context %}
{% from "devstack/files/macros.jinja" import getcmd, getargs, getlist with context %}

    {% for feature, task in devstack.cli.items() %}
      {%- if "set" in devstack.cli[feature] and devstack.cli[feature]['set'] is mapping %}
        {% for item, itemdata in devstack.cli[feature]['set'].items() %}

openstack devstack {{ feature }} set {{ item }}:
  cmd.run:
    - name: source ~/openrc admin admin && openstack {{ feature }} set {{- getcmd(itemdata) -}} {{ item }}
    - onlyif: source ~/openrc admin admin && openstack {{ feature }} show {{ item }} 2>/dev/null
    - runas: {{ devstack.local.username }}

        {% endfor %}
      {%- endif %}
    {% endfor %}
