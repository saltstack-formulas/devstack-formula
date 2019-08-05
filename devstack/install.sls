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
    - onlyif: systemctl status nginx

openstack devstack hard dependencies:
  ## workaround issues in https://bugs.launchpad.net/devstack/+bug/1806387/
  pkg.removed:
    - names:
      - python-yaml
    - require_in:
      - cmd: openstack devstack run stack
  cmd.run:
    - names:
      - wget https://bootstrap.pypa.io/get-pip.py
      - python2.7 get-pip.py
    - require_in:
      - cmd: openstack devstack run stack

openstack devstack run stack:
  cmd.run:
    - names:
      - git config --global url."https://".insteadOf git://   ##proxy workaround
      - {{ devstack.dir.dest }}/stack.sh
    - hide_output: {{ devstack.hide_output }}
    - runas: {{ devstack.local.stack_user }}
    - env:
      - LOGFILE: /tmp/devstack/salt_stack.sh.log
      - HOST_IP: {{ '127.0.0.1' if not devstack.local.host_ipv4 else devstack.local.host_ipv4 }}
      - HOST_IPV6: {{ devstack.local.host_ipv6 }}
      - HOST_NAME: {{'' if 'host_name' not in devstack.local else devstack.local.host_name}}
      - DATABASE_HOST: {{'127.0.0.1' if 'db_host' not in devstack.local else devstack.local.db_host}}
      - OS_USERNAME: {{'stack' if 'os_username' not in devstack.local else devstack.local.os_username}}
      - OS_PROJECT_NAME: ${OS_PROJECT_NAME:-{{'default' if 'os_project_name' not in devstack.local else devstack.local.os_project_name}}
      - OS_PASSWORD: ${OS_PASSWORD:-{{'devstack' if 'os_password' not in devstack.local else devstack.local.os_password }}}
      - ADMIN_PASSWORD: ${ADMIN_PASSWORD:-{{'nomoresecret' if 'admin_password' not in devstack.local else devstack.local.admin_password }}}
      - DATABASE_PASSWORD: ${DATABASE_PASSWORD:-{{'stackdb' if 'database_password' not in devstack.local else devstack.local.database_password }}}
      - RABBIT_PASSWORD: ${RABBIT_PASSWORD:-{{'stackqueue' if 'rabbit_password' not in devstack else devstack.local.rabbit_password }}}
      - SERVICE_PASSWORD: ${SERVICE_PASSWORD:-{{'nomoresecret' if 'service_password' not in devstack.local else devstack.local.service_password}}
      - SERVICE_TOKEN: ${SERVICE_TOKEN:-{{'nomoresecret' if 'service_token' not in devstack.local else devstack.local.service_token }}}
  file.managed:
    - name: {{ devstack.dir.dest }}/openrc
    - source: salt://devstack/files/openrc.j2
    - user: {{ devstack.local.stack_user }}
    - group: {{ devstack.local.stack_user }}
    - makedirs: True
    - mode: {{ devstack.mode }}
    - template: jinja
    - context:
        devstack: {{ devstack|json }}
    - onlyif: {{ devstack.managed.openrc }}

openstack devstack nginx conflict handler after stack.sh:
  cmd.run:
    - names:
      - systemctl start nginx
      - rm /tmp/devstack_stopped_nginx
    - onlyif: test -f /tmp/devstack_stopped_nginx
  pkg.installed:
    - name: {{ devstack.pip_pkg }}      ##stack.sh removed the package
    - onlyif: {{ devstack.pip_pkg }}
