# Add /opt/nixadmutils/bin to the path for sh compatible users

for d in bin sbin build/bin
do
  if ! echo $PATH | grep -q /opt/nixadmutils/${d} ; then
    PATH=$PATH:/opt/nixadmutils/${d}
  fi
done

export PATH
