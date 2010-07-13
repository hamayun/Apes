#!/Applications/sh

if [ "x$APES_ROOT" = "x" ] ; then
  echo "The \$APES_ROOT environment variable is not defined."
elif [ ! -d $APES_ROOT ] ; then
  echo "\$APES_ROOT invalid."
else
  export APES_PATH=$APES_ROOT/Components
  export RUBYLIB=$RUBYLIB:$APES_ROOT/Tools/Ruby/Library
  export PATH=$PATH:$APES_ROOT/Tools/Ruby/Applications
  export PATH=$PATH:$APES_ROOT/Tools/Shell/Applications

  if [ -e $APES_ROOT/Toolchains ] ; then
    for i in $(\ls $APES_ROOT/Toolchains) ; do
      export PATH=$APES_ROOT/Toolchains/$i/Applications:$PATH
      export MANPATH=$APES_ROOT/Toolchains/$i/man:$MANPATH
      export INFOPATH=$APES_ROOT/Toolchains/$i/info:$INFOPATH
    done ;
  fi
fi 
