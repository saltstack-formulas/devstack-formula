# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_config_file = tplroot ~ '.config.file' %}
{%- set sls_config_user = tplroot ~ '.config.user' %}
{%- from tplroot ~ "/map.jinja" import devstack with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}

include:
  - {{ sls_config_file }}
  - {{ sls_config_user }}

    {%- if 'pkgs_purge' in devstack and devstack.pkgs_purge %}
devstack-software-install-pkgs-purged:
  pkg.purged:
    - names:
           {%- for pkg in devstack.pkgs_purge %}
      - {{ pkg }}
           {%- endfor %}
    - require_in:
      - cmd: devstack-software-install
    {%- endif %}

devstack-software-install-prepare:
    {%- if 'pkgs_add' in devstack and devstack.pkgs_add %}
  pkg.installed:
    - names:
           {%- for pkg in devstack.pkgs_add %}
      - {{ pkg }}
           {%- endfor %}
    - require_in:
      - file: devstack-software-install-prepare
      - cmd: devstack-software-install
    {%- endif %}
  file.directory:
    - names:
      - {{ devstack.dir.tmp }}
      - {{ devstack.dir.dest }}
      - {{ devstack.dir.dest }}/.cache   # workaround
    - makedirs: True
    - force: True
    - user: {{ devstack.local.stack_user }}
    - dir_mode: '0755'
    - recurse:
      - user
      - mode
    - require:
      - sls: {{ sls_config_user }}
    - require_in:
      - cmd: devstack-software-install
  git.latest:
    - name: {{ devstack.local.git_url }}
    - rev: {{ devstack.local.git_branch }}
    - target: {{ devstack.dir.dest }}
    - user: {{ devstack.local.stack_user }}
    - force_clone: True
    - force_fetch: True
    - force_reset: True
    - force_checkout: True
    - retry:
        attempts: 3
        until: True
        interval: 60
        splay: 10
    - require:
      - file: devstack-software-install-prepare
    - require_in:
      - cmd: devstack-software-install

devstack-software-install-stackrc:
  file.managed:
    - name: {{ devstack.dir.dest }}/stackrc
    - source: {{ files_switch(['stackrc.j2'],
                              lookup='devstack-software-install-stackrc'
                 )
              }}
    - mode: 644
    - user: root
    - user: {{ devstack.local.stack_user }}
    - group: {{ devstack.local.stack_user }}
    - makedirs: True
    - template: jinja
    - context:
        devstack: {{ devstack | json }}
    - require:
      - git: devstack-software-install-prepare
    - require_in:
      - cmd: devstack-software-install

devstack-software-install-localconf:
  file.managed:
    - name: {{ devstack.dir.dest }}/local.conf
    - source: {{ files_switch(['local.conf.j2'],
                              lookup='devstack-software-install-localconf'
                 )
              }}
    - mode: 644
    - user: root
    - user: {{ devstack.local.stack_user }}
    - group: {{ devstack.local.stack_user }}
    - makedirs: True
    - template: jinja
    - context:
        devstack: {{ devstack | json }}
    - require:
      - git: devstack-software-install-prepare
    - require_in:
      - cmd: devstack-software-install

devstack-software-replace-policyrc:
  file.replace:
    # https://people.debian.org/~hmh/invokerc.d-policyrc.d-specification.txt
    - name: /usr/sbin/policy-rc.d
    - pattern: '101'
    - repl: '0'
    - backup: false
    - onlyif: test -f /usr/sbin/policy-rc.d
    - require:
      - git: devstack-software-install-prepare
    - require_in:
      - cmd: devstack-software-install

devstack-software-install-workarounds:
    {%- if not salt['cmd.run']('test -f {0}/requirements/global-requirements.txt'.format(devstack.dir.dest)) %}
  git.latest:
    ## workaround /opt/stack/../global-requirements.txt: No such file or directory ##
    - name: {{ devstack.local.git_req_url }}
    - rev: {{ devstack.local.git_branch }}
    - target: {{ devstack.dir.dest }}/requirements
    - user: {{ devstack.local.stack_user }}
    - force_clone: True
    - force_fetch: True
    - force_reset: True
    - force_checkout: True
    - retry:
        attempts: 3
        until: True
        interval: 60
        splay: 10
    - require:
      - git: devstack-software-install-prepare
    - require_in:
      - cmd: devstack-software-install
      {%- endif %}
      {%- if grains.os_family == 'RedHat' %}
  file.replace:
    - name: {{ devstack.dir.dest }}/lib/apache
    - pattern: 'python3-mod_wsgi'
    - repl: 'mod_proxy_uwsgi'
    - backup: false
    - onlyif: test -f {{ devstack.dir.dest }}/lib/apache
    - require:
      - git: devstack-software-install-prepare
    - require_in:
      - cmd: devstack-software-install
  cmd.run:
    - names:
        ### workaround: bugzilla 1464570
      - {{ devstack.dir.tmp }}/bugzilla-1464570.sh || true
        ### workaround: env: /opt/stack/requirements/.venv/bin/pip: No such file or directory
      - python3 -m venv requirements/.venv
      - chown -R {{ devstack.local.stack_user }}:{{ devstack.local.stack_user }} requirements/
        ### ensure nginx stopped
      - systemctl stop nginx || service stop nginx || true
    - cwd: {{ devstack.dir.dest }}
      {%- else %}
  cmd.run:
    - name: systemctl stop nginx || service stop nginx || true
      {%- endif %}
    - require:
      - git: devstack-software-install-prepare
      - file: devstack-software-install-prepare
    - require_in:
      - cmd: devstack-software-install

devstack-software-install-bugzilla-1464570:
  file.managed:
    - name: {{ devstack.dir.tmp }}/bugzilla-1464570.sh
    - source: {{ files_switch(['bugzilla-1464570.sh'],
                              lookup='devstack-software-install-bugzilla-1464570'
                 )
              }}
    - mode: 775
    - user: root
    - user: {{ devstack.local.stack_user }}
    - group: {{ devstack.local.stack_user }}
    - makedirs: True
    - require:
      - git: devstack-software-install-prepare
    - require_in:
      - cmd: devstack-software-install

devstack-software-install:
  cmd.run:
    - names:
        ### Centos: workround Cannot uninstall 'PyYAML', distutils installed project
      - (test -f /etc/redhat-release && rpm -e --nodeps python36-PyYAML && /usr/local/bin/pip3 install PyYAML)|| true
      - git config --global url."https://".insteadOf git://   ##proxy workaround
      - FORCE=yes {{ devstack.dir.dest }}/stack.sh
    - cwd: {{ devstack.dir.dest }}
    - hide_output: {{ devstack.hide_output }}
    - runas: {{ devstack.local.stack_user }}
    - env:
      - LC_ALL: C
      - USE_PYTHON3: True
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
    - require:
      - sls: {{ sls_config_user }}
      - git: devstack-software-install-prepare
      - cmd: devstack-software-install-workarounds
    - require_in:
      - file: devstack-config-file-install-openrc
      - cmd: devstack-software-postinstall

devstack-software-postinstall:
  pkg.installed:
    - name: {{ devstack.pip_pkg }}      ##stack.sh removed the package
    - onlyif: {{ devstack.pip_pkg }}
    - require:
      - cmd: devstack-software-install
  cmd.run:
    - name: systemctl start nginx || service start nginx || true
    - require:
      - cmd: devstack-software-install
