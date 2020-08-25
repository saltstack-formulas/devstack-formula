#!/usr/bin/env bash

PWD="$( pwd )"
DIR=/usr/lib64/python3.6/ensurepip
RC=0

## Keywords: Error -m venv Command ensurepip returned non-zero exit default-pip
## Bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1464570
## Workaround: https://www.squncle.com/article/2020/4/22/13980.html

if [[ -d "${DIR}" ]]
then 
    cd ${DIR}
    mkdir _bundled 2>/dev/null
    cd _bundled
    wget https://files.pythonhosted.org/packages/e7/16/da8cb8046149d50940c6110310983abb359bbb8cbc3539e6bef95c29428a/setuptools-40.6.2-py2.py3-none-any.whl || RC=1
    wget https://files.pythonhosted.org/packages/ac/95/a05b56bb975efa78d3557efa36acaf9cf5d2fd0ee0062060493687432e03/pip-9.0.3-py2.py3-none-any.whl || RC=1
    cd ${PWD}
fi
(( RC > 0 )) && echo "Error: Customize this script for your Centos/Pyton version [$0]"
exit ${RC}
