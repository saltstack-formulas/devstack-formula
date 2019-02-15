# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "devstack/map.jinja" import devstack with context %}
{% from "devstack/files/macros.jinja" import getcmd, getargs, getlist with context %}

    {%- for feature, task in devstack.cli.items() %}
      {%- if "add" in devstack.cli[feature] and devstack.cli[feature]['add'] is mapping %}
         {%- if feature in ['role',] %}
             {%- for item, itemdata in devstack.cli[feature]['add'].items() %}

                {%- if "user" in itemdata and itemdata['user'] is iterable %}
                  {%- for user in itemdata['user'] %}

openstack devstack {{ feature }} add prerequisite {{ item }} {{ user }}:
  cmd.run:
    - name: source ~/openrc admin admin && openstack {{ feature }} add {{- getcmd(itemdata['options']) -}} --user {{ user }} {{ item }}
    - runas: {{ devstack.local.stack_user }}
    - onlyif: source ~/openrc admin admin && openstack {{ feature }} list --user {{ user }}
    # output_loglevel: quiet

                  {%- endfor %}
                {%- endif %}

                {%- if "group" in itemdata and itemdata['group'] is iterable %}
                  {%- for group in itemdata['group'] %}

openstack devstack {{ feature }} add prerequisite {{ item }} {{ group }}:
  cmd.run:
    - name: source ~/openrc admin admin && openstack {{ feature }} add {{- getcmd(itemdata['options']) -}} --group {{ group }} {{ item }}
    - runas: {{ devstack.local.stack_user }}
    - onlyif: source ~/openrc admin admin && openstack {{ feature }} list --group {{ group }}
    # output_loglevel: quiet

                  {%- endfor %}
                {%- endif %}

              {%- endfor %}
          {%- endif %}
      {%- endif %}
    {%- endfor %}
