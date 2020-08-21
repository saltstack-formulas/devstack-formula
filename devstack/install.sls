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
  file.replace:
    # https://people.debian.org/~hmh/invokerc.d-policyrc.d-specification.txt
    - name: /usr/sbin/policy-rc.d
    - pattern: '101'
    - repl: '0'
    - backup: false
    - onlyif: test -f /usr/sbin/policy-rc.d
    - require_in:
      - cmd: openstack devstack install run stack

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
      - LOGFILE: {{ devstack.dir.tmp }}/salt_stack.sh.log
      - HOST_IP: {{ devstack.local.host_ipv4 or '127.0.0.1' }}
      - HOST_IPV6: {{ devstack.local.host_ipv6 or '::1' }}
      - HOST_NAME: {{ devstack.local.host_name or devstack.local.host_ipv4 or '127.0.0.1' }}
      - DATABASE_HOST: {{ devstack.local.db_host or '127.0.0.1' }}
      - OS_USERNAME: {{ devstack.local.os_username or 'admin' }}
      - OS_PROJECT_NAME: {{ devstack.local.os_project_name or 'admin' }}
      - OS_PASSWORD: {{ devstack.local.os_password or 'devstack' }}
      - ADMIN_PASSWORD: {{ devstack.local.admin_password or 'devstack' }}
      - DATABASE_PASSWORD: {{ devstack.local.database_password or 'devstack' }}
      - RABBIT_PASSWORD: {{ devstack.local.rabbit_password or 'stackqueue' }}
      - SERVICE_PASSWORD: {{ devstack.local.service_password or 'devstack' }}
      - SERVICE_TOKEN: {{ devstack.local.service_token or 'devstack' }}
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

