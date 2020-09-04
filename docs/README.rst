.. _readme:

devstack-formula
================

|img_travis| |img_sr| |img_pc|

.. |img_travis| image:: https://travis-ci.com/saltstack-formulas/devstack-formula.svg?branch=master
   :alt: Travis CI Build Status
   :scale: 100%
   :target: https://travis-ci.com/saltstack-formulas/devstack-formula
.. |img_sr| image:: https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg
   :alt: Semantic Release
   :scale: 100%
   :target: https://github.com/semantic-release/semantic-release
.. |img_pc| image:: https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white
   :alt: pre-commit
   :scale: 100%
   :target: https://github.com/pre-commit/pre-commit

A Salt formula to deploy local OpenStack cloud (aka Devstack) on GNU/Linux.

.. contents:: **Table of Contents**
   :depth: 1

General notes
-------------

See the full `SaltStack Formulas installation and usage instructions
<https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

If you are interested in writing or contributing to formulas, please pay attention to the `Writing Formula Section
<https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html#writing-formulas>`_.

If you want to use this formula, please pay attention to the ``FORMULA`` file and/or ``git tag``,
which contains the currently released version. This formula is versioned according to `Semantic Versioning <http://semver.org/>`_.

See `Formula Versioning Section <https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html#versioning>`_ for more details.

If you need (non-default) configuration, please pay attention to the ``pillar.example`` file and/or `Special notes`_ section.

Contributing to this repo
-------------------------

Commit messages
^^^^^^^^^^^^^^^

**Commit message formatting is significant!!**

Please see `How to contribute <https://github.com/saltstack-formulas/.github/blob/master/CONTRIBUTING.rst>`_ for more details.

pre-commit
^^^^^^^^^^

`pre-commit <https://pre-commit.com/>`_ is configured for this formula, which you may optionally use to ease the steps involved in submitting your changes.
First install  the ``pre-commit`` package manager using the appropriate `method <https://pre-commit.com/#installation>`_, then run ``bin/install-hooks`` and
now ``pre-commit`` will run automatically on each ``git commit``. ::

  $ bin/install-hooks
  pre-commit installed at .git/hooks/pre-commit
  pre-commit installed at .git/hooks/commit-msg

Special notes
-------------

The formula targets Debian and RedHat families. For OpenStack CLI (OSC) suppport, study the ``pillar.example`` carefully and raise an issue to track failed OSC commands.

Salt states (top.sls) for UBUNTU/CENTOS::

        base:
          '*':
            - devstack

Salt states (top.sls) for CLI::

        base:
          '*':
            - devstack.cli      #See https://docs.openstack.org/python-openstackclient/queens/cli/


Site/Release-specific Pillar Data::

        See `pillar.example`

The Devstack installer makes drastic and dramatic changes to your Linux environment. Use a fresh Linux OS installation and avoid making assumptions - Devstack only supports MYSQL on 127.0.0.1:

* https://bugs.launchpad.net/devstack/+bug/1735097
* https://bugs.launchpad.net/devstack/+bug/1892531



Available states
----------------

.. contents::
   :local:

``devstack``
^^^^^^^^^^^^

*Meta-state (This is a state that includes other states)*.

This installs the devstack package,
manages the devstack configuration file and then
starts the associated devstack service.

``devstack.user``
-----------------

Ensure `stack` user and group exists; included by ``devstack.install`` state.

``devstack.install``
--------------------

Deploy devstack using `stack.sh` and custom `localrc` generated from pillar data.

``devstack.clean``
------------------

Remove devstack - run unstack, clean, remove users and directories.

``devstack.user.clean``
-----------------------

Ensure `stack` user and group is absent; included by ``devstack.clean`` state.

``devstack.cli.create``
-----------------------

Support for OSC create use cases. See https://docs.openstack.org/python-openstackclient/rocky/cli/command-list.html#command-list.

``devstack.cli.delete``
-----------------------

Support for OSC delete use cases. See https://docs.openstack.org/python-openstackclient/rocky/cli/command-list.html#command-list.

``devstack.cli.set``
--------------------

Support for OSC set use cases. See https://docs.openstack.org/python-openstackclient/rocky/cli/command-list.html#command-list.

``devstack.cli.add``
--------------------

Support for OSC add use cases. See https://docs.openstack.org/python-openstackclient/rocky/cli/command-list.html#command-list.

Testing
-------

Linux testing is done with ``kitchen-salt``.

Requirements
^^^^^^^^^^^^

* Ruby
* Docker

.. code-block:: bash

   $ gem install bundler
   $ bundle install
   $ bin/kitchen test [platform]

Where ``[platform]`` is the platform name defined in ``kitchen.yml``,
e.g. ``debian-9-2019-2-py3``.

``bin/kitchen converge``
^^^^^^^^^^^^^^^^^^^^^^^^

Creates the docker instance and runs the ``devstack`` main state, ready for testing.

``bin/kitchen verify``
^^^^^^^^^^^^^^^^^^^^^^

Runs the ``inspec`` tests on the actual instance.

``bin/kitchen destroy``
^^^^^^^^^^^^^^^^^^^^^^^

Removes the docker instance.

``bin/kitchen test``
^^^^^^^^^^^^^^^^^^^^

Runs all of the stages above in one go: i.e. ``destroy`` + ``converge`` + ``verify`` + ``destroy``.

``bin/kitchen login``
^^^^^^^^^^^^^^^^^^^^^

Gives you SSH access to the instance for manual testing.
