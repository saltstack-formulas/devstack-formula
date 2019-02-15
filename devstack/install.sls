# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "devstack/map.jinja" import devstack with context %}

# user sls creates required user/group/destdir first
include:
  - .user

openstack devstack ensure package dependencies:
  file.directory:
    - name: {{ devstack.dir.tmp }}/devstack
    - makedirs: True
    - force: True
    - user: {{ devstack.local.stack_user }}
    - dir_mode: '0755'
    - recurse:
      - user
      - mode
  pkg.installed:
    - names:
      {%- for pkg in devstack.pkgs %}
      - {{ pkg }}
      {%- endfor %}

openstack devstack git cloned:
  git.latest:
    - name: {{ devstack.local.git_url }}
    - rev: {{ devstack.local.git_branch }}
    - target: {{ devstack.dir.dest }}
    - user: {{ devstack.local.stack_user }}
    - force_clone: True
    - force_fetch: True
    - force_reset: True
    - force_checkout: True
    {% if grains['saltversioninfo'] >= [2017, 7, 0] %}
    - retry:
        attempts: 3
        until: True
        interval: 60
        splay: 10
    {%- endif %}
    - require:
      - user: openstack devstack ensure user and group exist
      - pkg: openstack devstack ensure package dependencies

openstack devstack configure stackrc:
  file.managed:
    - name: {{ devstack.dir.dest }}/stackrc
    - source: salt://devstack/files/stackrc.j2
    - user: {{ devstack.local.stack_user }}
    - group: {{ devstack.local.stack_user }}
    - makedirs: True
    - mode: {{ devstack.mode }}
    - template: jinja
    - context:
        devstack: {{ devstack|json }}
    - require_in:
      - cmd: openstack devstack run stack

openstack devstack configure local_conf:
  file.managed:
    - name: {{ devstack.dir.dest }}/local.conf
    - source: salt://devstack/files/local.conf.j2
    - user: {{ devstack.local.stack_user }}
    - group: {{ devstack.local.stack_user }}
    - makedirs: True
    - mode: {{ devstack.mode }}
    - template: jinja
    - context:
        devstack: {{ devstack|json }}

openstack devstack configure required directories:
  cmd.run:
    - names:
      - mkdir -p {{ devstack.dir.tmp }}/devstack
      - chown -R {{devstack.local.stack_user}}:{{devstack.local.stack_user}} {{devstack.dir.dest}} {{ devstack.dir.tmp }}/devstack
    - require_in:
      - cmd: openstack devstack run stack

openstack devstack nginx conflict handler before stack.sh:
  cmd.run:
    - names:
      - systemctl stop nginx
      - touch /tmp/devstack_stopped_nginx
    - onlyif: systemctl status ngin-x

openstack devstack run stack:
  cmd.run:
    - name: {{ devstack.dir.dest }}/stack.sh
    - hide_output: {{ devstack.hide_output }}
    - runas: {{ devstack.local.stack_user }}
    - env:
      - HOST_IP: {{ '127.0.0.1' if not devstack.local.host_ipv4 else devstack.local.host_ipv4 }}
      - HOST_IPV6: {{ devstack.local.host_ipv6 }}
  {%- if devstack.pip_pkg %}
  ### stack.sh uninstalls python-pip; we can reinstall
  pkg.installed:
    - name: {{ devstack.pip_pkg }}
  {%- endif %}
  service.running:
    - name: nginx
    - onlyif: systemctl status nginx 2>/dev/null

openstack devstack nginx conflict handler after stack.sh:
  cmd.run:
    - names:
      - systemctl start nginx
      - rm /tmp/devstack_stopped_nginx
    - onlyif: test -f /tmp/devstack_stopped_nginx
