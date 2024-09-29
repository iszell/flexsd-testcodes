#!/bin/bash

GLOBINC=_tempsyms_.inc

if [[ $# -eq 1 ]]; then
  asl $1.asm -A -a -L -u -E !1 -x
  RET=$?
elif [[ $# -eq 2 ]]; then
  echo 'prg_name = "'$(echo $1 | tr 'a-z' 'A-Z')'"' > $GLOBINC
  echo 'target_platform = '$2 >> $GLOBINC
  asl $1.asm -A -a -L -u -E !1 -x
  RET=$?
  rm $GLOBINC
else
  echo "Wrong number of parameter!"
  exit 2
fi

if [ $RET -ne 0 ]; then
  exit $RET
fi

p2bin $1.p $1.bin -r '$-$' -l 0 -k
RET=$?

if [ $RET -ne 0 ]; then
  exit $RET
fi
