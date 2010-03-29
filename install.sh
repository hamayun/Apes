#!/bin/sh

if [ "x$APES_ROOT" = "x" ] ; then
  echo "The \$APES_ROOT environment variable is not defined."
elif [ ! -d $APES_ROOT ] ; then
  echo "\$APES_ROOT invalid."
else
  export APES_COMPONENT_PATH=$APES_ROOT/Components
  export RUBYLIB=$RUBYLIB:$APES_ROOT/Tools/Ruby/lib
  export GEM_PATH=$GEM_PATH:$APES_ROOT/Tools/Ruby/Gems
  export PATH=$PATH:$APES_ROOT/Tools/Ruby/bin
  export PATH=$PATH:$APES_ROOT/Tools/Shell/bin

  if [ -e $APES_ROOT/Toolchains ] ; then
    for i in $(ls $APES_ROOT/Toolchains) ; do
      export PATH=$TOOLCHAINS/$i/bin:$PATH
      export MANPATH=$TOOLCHAINS/$i/man:$MANPATH
      export INFOPATH=$TOOLCHAINS/$i/info:$INFOPATH
    done ;
  fi
fi 
