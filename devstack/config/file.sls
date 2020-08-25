# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import devstack with context %}
{%- set sls_config_user = tplroot ~ '.config.user' %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}

include:
  - {{ sls_config_user }}

devstack-config-file-install-openrc:
  file.managed:
    - name: {{ devstack.dir.dest }}/openrc
    - source: {{ files_switch(['openrc.j2'],
                              lookup='devstack-config-file-install-openrc'
                 )
              }}
    - mode: 644
    - user: root
    - user: {{ devstack.local.stack_user }}
    - group: {{ devstack.local.stack_user }}
    - makedirs: True
    - template: jinja
    - context:
      devstack: {{ devstack | json }}
    - require:
      - sls: {{ sls_config_user }}
