# -*- coding: utf-8 -*-
# vim: ft=yaml
---
mysql:
  server:
    root_password: devstack   # sync with devstack
    mysqld:
      bind_address: 127.0.0.1   # sync with devstack

devstack:
  lookup:
    master: template-master
    # Just for testing purposes
    winner: lookup
    added_in_lookup: lookup_value

  pkgs_purge:
    - python3-simplejson
  hide_output: true
  local:
    stack_user: stack
    os_password: devstack
    os_project_name: admin
    admin_password: devstack
    git_branch: 'stable/ussuri'
    enabled_services: 'mysql,key'
    host_ipv4: 127.0.0.1
    host_ipv6: ::1
    service_host: 127.0.0.1
    db_host: 127.0.0.1
  managed:
    openrc: false

  dir:
    tmp: /tmp/devstack  # not sure why centos wants this?

  # openstack cli
  cli:

    # User
    user:
      create:
        'keystone':
          options:
            domain: default
            password: devstack
            project: admin
            enable: true
      delete:
        demo:
          options:
            domain: default
        alt_demo:
          options:
            domain: default

    group:
      create:
        service:
          options:
            domain: default
      add user:
        service:
          target:
            - 'keystone'
        admins:
          options:
            domain: default
          target:
            - admin

    role:
      add:
        admin:
          options:
            project: admin
          user:
            - 'keystone'
        service:
          options:
            project: admin
          group:
            - service

    service:
      create:
        keystonev0.2.0:
          options:
            name: 'keystone'
            description: keystone Service
            enable: true

    endpoint:
      create:
        keystonev0.2.0 public https://127.0.0.1/50040//v0.2.0/%\(tenant_id\)s:
          options:
            region: RegionOne
            enable: true
        keystonev0.2.0 internal https://127.0.0.1/50040/v0.2.0/%\(tenant_id\)s:
          options:
            region: RegionOne
            enable: true
        keystonev0.2.0 admin https://127.0.0.1/50040/v0.2.0/%\(tenant_id\)s:
          options:
            region: RegionOne
            enable: true

    project:
      delete:
        demo:
          options:
            domain: default
        alt_demo:
          options:
            domain: default
        invisible_to_admin:
          options:
            domain: default

  tofs:
    # The files_switch key serves as a selector for alternative
    # directories under the formula files directory. See TOFS pattern
    # doc for more info.
    # Note: Any value not evaluated by `config.get` will be used literally.
    # This can be used to set custom paths, as many levels deep as required.
    files_switch:
      - any/path/can/be/used/here
      - id
      - roles
      - osfinger
      - os
      - os_family
    # All aspects of path/file resolution are customisable using the options below.
    # This is unnecessary in most cases; there are sensible defaults.
    # Default path: salt://< path_prefix >/< dirs.files >/< dirs.default >
    #         I.e.: salt://devstack/files/default
    # path_prefix: template_alt
    # dirs:
    #   files: files_alt
    #   default: default_alt
    # The entries under `source_files` are prepended to the default source files
    # given for the state
    # source_files:
    #   devstack-config-file-file-managed:
    #     - 'example_alt.tmpl'
    #     - 'example_alt.tmpl.jinja'

    # For testing purposes
    source_files:
      devstack-config-file-file-managed:
        - 'example.tmpl.jinja'
      devstack-subcomponent-config-file-file-managed:
        - 'subcomponent-example.tmpl.jinja'

  # Just for testing purposes
  winner: pillar
