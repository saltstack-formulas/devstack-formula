# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "devstack/map.jinja" import devstack with context %}
{% from "devstack/files/macros.jinja" import getcmd, getargs, getlist with context %}

    {%- for feature, task in devstack.cli.items() %}
      {%- if "create" in devstack.cli[feature] and devstack.cli[feature]['create'] is mapping %}
         {%- if feature in ['user', 'group', 'role', 'service',] %} 
             {%- for item, itemdata in devstack.cli[feature]['create'].items() %}

devstack_{{ feature }}_create_prerequisite_{{ item }}:
  cmd.run:
    - name: source ~/openrc admin admin && openstack {{ feature }} create {{- getcmd(itemdata) -}} {{ item }}
    - unless: source ~/openrc admin admin && openstack {{ feature }} show {{ item }} 2>/dev/null
    - runas: {{ devstack.local.username }}

              {%- endfor %}
          {%- endif %}
      {%- endif %}
    {%- endfor %}

    {%- for feature, task in devstack.cli.items() %}
      {%- if "create" in devstack.cli[feature] and devstack.cli[feature]['create'] is mapping %}
         {%- if feature not in ['user', 'group', 'role', 'service',] %} 
            {%- for item, itemdata in devstack.cli[feature]['create'].items() %}

devstack_{{ feature }}_create_remaining_{{ item }}:
  cmd.run:
    - name: source ~/openrc admin admin && openstack {{ feature }} create {{- getcmd(itemdata) -}} {{ item }}
    - unless: source ~/openrc admin admin && openstack {{ feature }} show {{ item }} 2>/dev/null
    - runas: {{ devstack.local.username }}
    - output_loglevel: quiet
    - env:
      - DEST: {{ devstack.dir.dest }}

            {%- endfor %}
         {%- endif %}
      {%- endif %}
    {%- endfor %}
