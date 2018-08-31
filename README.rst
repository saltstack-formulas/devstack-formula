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

Testing
=========
Verified on Fedora 27, Ubuntu 16.04, and Centos 7.

Reference Configuration
========================
The following configuration was needed on Fedora 27. On Ubuntu the `packages` state was unnecesary.

State top file::

        base:
          '*':
            - packages                #we are missing mysql.removed state, needed on Fedora27
            - mysql                   #install mysql server
            - devstack.clean
            - devstack

Pillar Data::
        
        devstack:
          local:
            username: stack
            password: devstack
            enabled_services: 'mysql,key'     #needs quotes
            ### used by devstack openrc
            os_password: devstack
        
        mysql:
          # mysql password needs to match devstack 'DATABASE_PASSWORD'
          server:
            root_password: 'devstack'
        
        packages:
          pkgs:
            #Needed because of https://github.com/saltstack-formulas/mysql-formula/issues/195
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

