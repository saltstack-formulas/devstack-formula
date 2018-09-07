================
devstack-formula
================

A SaltStack formula to deploy local OpenStack cloud (aka Devstack) on GNU/Linux from git source trees.

**NOTE**

See the full `Salt Formulas installation and usage instructions
<https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

Available states
================

.. contents::
    :local:

``devstack``
------------

Deploy devstack using `stack.sh` and custom `localrc` generated from pillar data.

``devstack.user``
------------------

Ensure `stack` user and group exists. Included by ``devstack`` state.

``devstack.user.remove``
------------------

Ensure `stack` user and group is absent. Included by ``devstack.clean`` state.

``devstack.remove``
------------------

Remove devstack - run unstack, clean, remove users and directories.

``devstack.cli``
------------------

Support for the OpenStack CLI (OSC) documentaed at https://docs.openstack.org/python-openstackclient/queens/cli/. Meta state including ``cli.create``, ``cli.delete``, and ``cli.set`` states.

``devstack.cli.create``
-----------------------

Support for the OpenStack CLI (OSC) create use cases.

``devstack.cli.delete``
-----------------------

Support for the OpenStack CLI (OSC) delete use cases.

``devstack.cli.set``
-----------------------

Support for the OpenStack CLI (OSC) set use cases.


Testing
=========
Verified on Fedora 27, Ubuntu 16.04, and Centos 7.

Reference Solution
========================
The following configuration seems to work fine on RedHat family and Ubuntu. For OpenStack CLI (OSC) suppport, study the ``pillar.example`` carefully and raise an issue to track failed OSC commands.

Salt states top file (top.sls)::

        base:
          '*':
            - packages          #See we are missing mysql.removed state, needed on Fedora27
            - mysql             #install mysql server
            - devstack.clean
            - devstack
            - devstack.cli      #See https://docs.openstack.org/python-openstackclient/queens/cli/

Devstack Pillar Data (see pillar.example)::

        devstack:
            {% set servicename = 'serviceX' %}
            {% set service_version = 'v0.2.0' %}
            {% set host_ip = '127.0.0.1' %}
            {% set svc_tcpport = '50040' %}
            {% set password = 'devstack' %}
            {% set servicetype = servicename %}
            {% set endpointname = servicename ~ service_version %}

          local:
            username: stack
            password: {{ password }}
            enabled_services: 'mysql,key'
            os_password: {{ password }}
            host_ip: {{ host_ip }}
            host_ipv6: {{ grains.ipv6[-1] }}
            service_host: {{ host_ip }}

          cli:
            user:
              create:
                {{ servicename }}:
                  options:
                    domain: default
                    password: {{ password }}
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
                    - {{ servicename }}
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
                    user: {{ servicename }}
                service:
                  options:
                    project: service
                    group: service
            service:
              create:
                {{ servicetype }}:
                  options:
                    name: {{ servicename }}
                    type: identity
                    description: OpenSDS Block Storage
                    enable: True
            endpoint:
              create:
                '{{ endpointname }} public https://{{ host_ip }}/{{ svc_tcpport }}/{{ service_version }}/%\(tenant_id\)s':
                  options:
                    region: RegionOne
                    enable: True
                '{{ endpointname }} internal https://{{ host_ip }}/{{ svc_tcpport }}/{{ service_version }}/%\(tenant_id\)s':
                  options:
                    region: RegionOne
                    enable: True
                '{{ endpointname }} admin https://{{ host_ip }}/{{ svc_tcpport }}/{{ service_version }}/%\(tenant_id\)s':
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


Supporting Stack Pillar Data::

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

