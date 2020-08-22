================
devstack-formula
================

A Salt formula to deploy local OpenStack cloud (aka Devstack) on GNU/Linux.

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

``devstack.cli.add``
-----------------------

Support for OSC add use cases. See https://docs.openstack.org/python-openstackclient/rocky/cli/command-list.html#command-list.

Testing
=========
Verified on Fedora 27, Ubuntu 18.04, and Centos7.

Reference Solution
========================

The formula targets Debian and RedHat families. For OpenStack CLI (OSC) suppport, study the ``pillar.example`` carefully and raise an issue to track failed OSC commands.

Salt states (top.sls) for UBUNTU::

        base:
          '*':
            - devstack

Salt states (top.sls) for REDHAT::

        base:
          '*':
            - packages.pkg
            - packages.archives
            - devstack

Salt states (top.sls) for CLI::

        base:
          '*':
            - devstack.cli      #See https://docs.openstack.org/python-openstackclient/queens/cli/


Site/Release-specific Pillar Data::

        See `pillar.example`

The Devstack installer makes drastic and dramatic changes to your Linux environment. Use a fresh Linux OS installation and avoid making assumptions - Devstack only supports MYSQL on 127.0.0.1:
  - https://bugs.launchpad.net/devstack/+bug/1735097
  - https://bugs.launchpad.net/devstack/+bug/1892531
