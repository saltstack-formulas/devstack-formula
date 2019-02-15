# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "devstack/map.jinja" import devstack with context %}
{% from "devstack/files/macros.jinja" import getcmd, getargs, getlist with context %}

    {% for feature, task in devstack.cli.items() %}
      {%- if "delete" in devstack.cli[feature] and devstack.cli[feature]['delete'] is mapping %}
        {% for item, itemdata in devstack.cli[feature]['delete'].items() %}

openstack devstack {{ feature }} delete {{ item }}:
  cmd.run:
    - name: source ~/openrc admin admin && openstack {{ feature }} delete {{- getcmd(itemdata) -}} {{ item }}
    - onlyif: source ~/openrc admin admin && openstack {{ feature }} show {{ item }} 2>/dev/null
    - runas: {{ devstack.local.username }}

        {% endfor %}
      {%- endif %}
    {% endfor %}
