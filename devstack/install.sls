# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "devstack/map.jinja" import devstack with context %}

# user sls creates required user/group/destdir first
include:
  - .user

openstack devstack install ensure package dependencies:
  file.directory:
    - names:
      - {{ devstack.dir.tmp }}
      - {{ devstack.dir.dest }}
      - {{ devstack.dir.dest }}/.cache   # workaround
    - makedirs: True
    - force: True
    - user: {{ devstack.local.stack_user }}
    - group: {{ devstack.local.stack_user }}
    - dir_mode: '0755'
    - recurse:
      - user
      - mode
      {%- if 'pkgs_add' in devstack and devstack.pkgs_add %}
  pkg.installed:
    - names:
          {%- for pkg in devstack.pkgs_add %}
      - {{ pkg }}
          {%- endfor %}
      {%- endif %}

openstack devstack install git cloned:
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
      - user: openstack devstack user ensure user and group exist
      - pkg: openstack devstack install ensure package dependencies

openstack devstack install configure stackrc:
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
      - cmd: openstack devstack install run stack

openstack devstack install configure local_conf:
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

openstack devstack install before stack.sh:
  cmd.run:
    - names:
      - systemctl stop nginx
      - touch {{ devstack.dir.tmp }}/nginx_paused
    - onlyif: which nc && nc -z localhost 80 && systemctl status nginx 2>/dev/null

openstack devstack install run stack:
      {%- if 'pkgs_purge' in devstack and devstack.pkgs_purge %}
  pkg.purged:
    - names:
          {%- for pkg in devstack.pkgs_purge %}
      - {{ pkg }}
          {%- endfor %}
      {%- endif %}
  cmd.run:
    - names:
      - mkdir -p {{ devstack.dir.dest }}/.cache
      - chown {{ devstack.local.stack_user }}:{{ devstack.local.stack_user }} {{ devstack.dir.dest }}/.cache
      - chmod +t {{ devstack.dir.dest }}/.cache
      - git config --global url."https://".insteadOf git://   ##proxy workaround
      - {{ devstack.dir.dest }}/stack.sh
    - hide_output: {{ devstack.hide_output }}
    - runas: {{ devstack.local.stack_user }}
    - env:
      - LOGFILE: ${LOGDIR:-{{ devstack.dir.tmp }}}/salt_stack.sh.log
      - HOST_IP: ${HOST_IP:-{{ devstack.local.host_ipv4 }}}
      - HOST_IPV6: ${HOST_IPV6:-{{ devstack.local.host_ipv6 }}}
      - HOST_NAME: ${HOST_NAME:-{{ devstack.local.host_name }}}
      - DATABASE_HOST: ${DATABASE_HOST:-{{ devstack.local.db_host or '127.0.0.1' }}}
      - OS_USERNAME: ${OS_USERNAME:-{{ devstack.local.os_username }}}
      - OS_PROJECT_NAME: ${OS_PROJECT_NAME:-{{ devstack.local.os_project_name }}}
      - OS_PASSWORD: ${OS_PASSWORD:-{{ devstack.local.os_password }}}
      - ADMIN_PASSWORD: ${ADMIN_PASSWORD:-{{ devstack.local.os_password }}}
      - SERVICE_PASSWORD: ${ADMIN_PASSWORD:-{{ devstack.local.admin_password }}}
      - DATABASE_PASSWORD: ${DATABASE_PASSWORD:-{{ devstack.local.database_password }}}
      - RABBIT_PASSWORD: ${RABBIT_PASSWORD:-{{ devstack.local.rabbit_password }}}
      - SERVICE_TOKEN: ${SERVICE_TOKEN:-{{ devstack.local.service_token }}}
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

openstack devstack install after stack.sh:
  cmd.run:
    - names:
      - systemctl start nginx
      - rm {{ devstack.dir.tmp }}/nginx_paused
    - onlyif: test -f {{ devstack.dir.tmp }}/nginx_paused
  pkg.installed:
    - name: {{ devstack.pip_pkg }}      ##stack.sh removed the package
    - onlyif: {{ devstack.pip_pkg }}

