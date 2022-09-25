#!/bin/bash

if [[ $# -eq 1 ]]; then
  asl $1.asm -A -a -L -u -E !1 -x
  RET=$?
elif [[ $# -eq 2 ]]; then
  asl $1.asm -A -a -L -u -E !1 -x -D target_platform=$2
  RET=$?
else
  echo "Wrong number of parameter!"
  exit 2
fi

if [ $RET -ne 0 ]; then
  exit $RET
fi

p2bin $1.p $1.prg -r '$-$' -l 0 -k
