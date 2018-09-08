================
devstack-formula
================

A Salt formula to deploy local OpenStack cloud (aka Devstack) on GNU/Linux from git source trees.

**NOTE**

See the full `Salt Formulas installation and usage instructions
<https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

Available Meta states
======================

.. contents::
    :local:

``devstack``
------------

Meta state for ``devstack.user``, ``devstack.install``, and ``devstack.cli`` states.

``devstack.remove``
--------------------

Meta state to run unstack, clean, remove users and directories.

``devstack.cli``
------------------

Meta state for ``cli.create``, ``cli.delete``, and ``cli.set``. The ``devstack.cli`` state supports the OpenStackClient (aka OSC), a command-line client for OpenStack that brings the command set for Compute, Identity, Image, Object Storage and Block Storage APIs together in a single shell with a uniform command structure.

Available states
================

.. contents::
    :local:

``devstack.user``
------------------

Ensure `stack` user and group exists; included by ``devstack.install`` state.

``devstack.install``
--------------------

Deploy devstack using `stack.sh` and custom `localrc` generated from pillar data.

``devstack.remove``
--------------------

Remove devstack - run unstack, clean, remove users and directories.

``devstack.user.remove``
------------------

Ensure `stack` user and group is absent; included by ``devstack.remove`` state.

``devstack.cli.create``
-----------------------

Support for OSC create use cases. See https://docs.openstack.org/python-openstackclient/rocky/cli/command-list.html#command-list.

``devstack.cli.delete``
-----------------------

Support for OSC delete use cases. See https://docs.openstack.org/python-openstackclient/rocky/cli/command-list.html#command-list.

``devstack.cli.set``
-----------------------

Support for OSC set use cases. See https://docs.openstack.org/python-openstackclient/rocky/cli/command-list.html#command-list.


Testing
=========
Verified on Fedora 27, Ubuntu 16.04, and Centos 7.

Reference Solution
========================
The following configuration works on RedHat family and Ubuntu. For OpenStack CLI (OSC) suppport, study the ``pillar.example`` carefully and raise an issue to track failed OSC commands.

Salt states (top.sls) for install::

        base:
          '*':
            - packages.pkgs        #RedHat only? https://github.com/saltstack-formulas/mysql-formula/issues/195
            - packages.archives    #RedHat only? https://github.com/saltstack-formulas/mysql-formula/issues/195
            - mysql                #install mysql server (after ``packages`` state runs)
            - devstack

Salt states (top.sls) for Openstack CLI::

        base:
          '*':
            - devstack.cli      #See https://docs.openstack.org/python-openstackclient/queens/cli/


Site/Release-specific Pillar Data (see pillar.example)::

            {% set devstack_svc_name = 'KeyService' %}
            {% set devstack_enabled_services = 'mysql,key' %}
            {% set devstack_svc_version = 'v0.2.0' %}
            {% set devstack_svc_port = '50040' %}
            {% set devstack_password = 'devstack' %}
            {% set devstack_svc_type = devstack_svc_name %}
            {% set devstack_svc_endpoint = devstack_svc_name ~ devstack_svc_version %}
            {% set host_ip = grains.ip[-1] or '127.0.0.1' %}
            {% set host_ipv6 = grains.ipv6[-1] %}
        devstack:
          local:
            username: stack
            password: {{ devstack_password }}
            devstack_enabled_services: {{ devstack_enabled_services }}
            os_password: {{ devstack_password }}
            host_ip: {{ host_ip }}
            host_ipv6: {{ host_ipv6 }}
            service_host: {{ host_ip or host_ipv6 }}
          cli:
            user:
              create:
                {{ devstack_svc_name }}:
                  options:
                    domain: default
                    password: {{ devstack_password }}
                    project: service
                    enable: True
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
                    - {{ devstack_svc_name }}
                admins:
                  options:
                    domain: default
                  target:
                    - admin
            role:
              add:
                admin:
                  options:
                    project: service
                    user: {{ devstack_svc_name }}
                service:
                  options:
                    project: service
                    group: service
            service:
              create:
                {{ devstack_svc_type }}:
                  options:
                    name: {{ devstack_svc_name }}
                    type: identity
                    description: {{ devstack_svc_name }} Service
                    enable: True
            endpoint:
              create:
                '{{ devstack_svc_endpoint }} public https://{{ host_ip or host_ip6 }}/{{ devstack_svc_port }}/{{ devstack_svc_version }}/%\(tenant_id\)s':
                  options:
                    region: RegionOne
                    enable: True
                '{{ devstack_svc_endpoint }} internal https://{{ host_ip or host_ip6 }}/{{ devstack_svc_port }}/{{ devstack_svc_version }}/%\(tenant_id\)s':
                  options:
                    region: RegionOne
                    enable: True
                '{{ devstack_svc_endpoint }} admin https://{{ host_ip or host_ip6 }}/{{ devstack_svc_port }}/{{ devstack_svc_version }}/%\(tenant_id\)s':
                  options:
                    region: RegionOne
                    enable: True
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

Other pillar data::

        mysql:
          # mysql password needs to match devstack 'DATABASE_PASSWORD' !!!!!!!!! Important !!!!
          server:
            root_password: 'devstack'
        
        packages:
          pkgs:
            #Needed because of https://github.com/saltstack-formulas/mysql-formula/issues/195
            #Used on RedHat family anyway!
            unwanted:
              - mariadb
              - mariadb-tokudb-engine
              - mariadb-config
              - mariadb-libs
              - mariadb-rocksdb-engine
              - mariadb-common
              - mariadb-cracklib-password-check
              - mariadb-gssapi-server
              - mariadb-devel
              - mariadb-server-utils
              - mariadb-server
              - mariadb-backup
              - mariadb-errmsg
          archives:
            #Needed because of https://github.com/saltstack-formulas/mysql-formula/issues/195
            - unwanted:
                - /var/lib/mysql/

