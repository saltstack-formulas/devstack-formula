# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "devstack/map.jinja" import devstack with context %}

openstack-devstack ensure package dependencies:
  pkg.installed:
    - name: git

openstack-devstack ensure user and group exist:
  group.present:
    - name: {{ devstack.user }}
    - unless: getent group {{ devstack.user }}
  user.present:
    - name: {{ devstack.user }}
    - fullname: DevStack User
    - shell: /bin/bash
    - home: {{ devstack.dir.base }}
    - createhome: True
    - groups:
      - {{ devstack.user }}
    - require:
      - group: openstack-devstack ensure user and group exist
    - require_in:
      - file: openstack-devstack deploy
      - git: openstack-devstack git cloned
    - unless: getent passwd {{ devstack.user }}

openstack-devstack git cloned:
  git.latest:
    - name: https://github.com/openstack-dev/devstack.git
    - rev: {{ devstack.repo.branch }}
    - target: {{ devstack.dir.base }}
    - user: {{ devstack.user }}
    - force_clone: True
    - require:
      - pkg: openstack-devstack ensure package dependencies
  file.managed:
    - name: /etc/sudoers.d/50_devstack
    - source: salt://devstack/files/devstack.sudoers
    - mode: 440
    - runas: root
    - user: root
    - makedirs: True
    - template: jinja
    - context:
      username: {{ devstack.user }}
    - require:
      - git: openstack-devstack git cloned

openstack-devstack deploy:
  file.managed:
    - name: {{ devstack.dir.base }}/localrc
    - source: salt://devstack/files/localrc.j2
    - user: {{ devstack.user }}
    - group: {{ devstack.user }}
    - makedirs: True
    - mode: {{ devstack.mode }}
    - template: jinja
    - context:
        git_base: {{ devstack.conf.git_base }}
        branch: {{ devstack.repo.branch }}
        host_ip: {{ devstack.conf.host_ip }}
        service_host: {{ devstack.conf.service_host }}
        service_password: {{ devstack.conf.service_password }}
        admin_password: {{ devstack.conf.admin_password }}
        service_token: {{ devstack.conf.service_token }}
        database_password: {{ devstack.conf.database_password }}
        rabbit_password: {{ devstack.conf.rabbit_password }}
        enable_httpd_mod_wsgi_services: {{ devstack.conf.enable_httpd_mod_wsgi_services }}
        keystone_use_mod_wsgi: {{ devstack.conf.keystone_use_mod_wsgi }}
        logfile: {{ devstack.dir.log }}/{{ devstack.conf.logfile }}
        verbose: {{ devstack.conf.verbose }}
        enable_debug_log_level: {{ devstack.conf.enable_debug_log_level }}
        enable_verbose_log_level: {{ devstack.conf.enable_verbose_log_level }}
        reclone: {{ devstack.conf.reclone }}
  cmd.run:
    - name: bash {{ devstack.dir.base }}/stack.sh
    - runas: {{ devstack.user }}
    - require:
      - file: openstack-devstack deploy
