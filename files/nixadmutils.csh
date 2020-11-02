# Add /opt/nixadmutils/bin to the path for csh users
set path = ($path /opt/nixadmutils/bin /opt/nixadmutils/sbin /opt/nixadmutils/build/bin)

[ -d /opt/nixadmutils/lib/python ] && setenv PYTHONPATH /opt/nixadmutils/lib/python:${PYTHONPATH}
