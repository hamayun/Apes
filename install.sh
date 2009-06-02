#!/bin/sh

export APES_ROOT=$PWD
export RUBYLIB=$RUBYLIB:$APES_ROOT/Tools/Ruby/lib
export PATH=$PATH:$APES_ROOT/Tools/Ruby/bin

echo 'APES_ROOT = '$APES_ROOT
echo 'RUBY_LIB += '$APES_ROOT/Tools/Ruby/lib
echo 'PATH += '$APES_ROOT/Tools/Ruby/bin
