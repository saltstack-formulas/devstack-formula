# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import devstack with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}

devstack-user-install:
  group.present:
    - name: {{ devstack.local.stack_user }}
  user.present:
    - name: {{ devstack.local.stack_user }}
    - fullname: DevStack User
    - shell: /bin/bash
    - home: {{ devstack.dir.dest }}
    - createhome: True
    - groups:
      - {{ devstack.local.stack_user }}
    - require:
      - group: devstack-user-install
  file.directory:
    - names:
      - {{ devstack.dir.dest }}
      - {{ devstack.dir.tmp }}
    - user: {{ devstack.local.stack_user }}
    - group: {{ devstack.local.stack_user }}
    - dir_mode: {{ devstack.dir_mode }}
    - recurse:
      - user
      - group
      - mode

devstack-user-sudoers-install:
  file.managed:
    - name: {{ devstack.local.sudoers_file }}
    - source: {{ files_switch(['devstack.sudoers'],
                              lookup='devstack-user-sudoers-install'
                 )
              }}
    - mode: 440
    - user: root
    - makedirs: True
    - template: jinja
    - context:
      stack_user: {{ devstack.local.stack_user }}
    - require:
      - user: devstack-user-install
