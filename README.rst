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
Verified on Centos 7.

