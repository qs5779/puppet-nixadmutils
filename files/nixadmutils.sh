# Add /opt/nixadmutils/bin to the path for sh compatible users

for d in bin build/bin
do
  if ! echo $PATH | grep -q /opt/nixadmutils/${d} ; then
    PATH=$PATH:/opt/nixadmutils/${d}
  fi
done

if groups | grep -q -e wheel -e sudo -e vagrant
then
  for d in /opt/nixadmutils/sbin /usr/local/sbin
  do
    if ! echo $PATH | grep -q ${d} ; then
      PATH=$PATH:${d}
    fi
  done
fi

export PATH
