# Add /opt/nixadmutils/bin to the path for sh compatible users

if ! echo $PATH | grep -q /opt/nixadmutils/bin ; then
  PATH=$PATH:/opt/nixadmutils/bin
fi

# Add /opt/nixadmutils/bin to the path for sh compatible users

if ! echo $PATH | grep -q /opt/nixadmutils/sbin ; then
  PATH=$PATH:/opt/nixadmutils/sbin
fi

export PATH
