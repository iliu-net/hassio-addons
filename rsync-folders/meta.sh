#!/bin/sh
set -euf -o pipefail
#
# Create meta files containing special file-system metadata
# i.e. file capabilities, permissions, ownership etc.
#
# This is used to be able to backup to media that has limited
# meta data capabilities, i.e. vfat partitions,
# rsync with low priviledge users, idrive backups, etc...
#
v=-v

if [ $# -gt 2 -o $# -eq 0 ] ; then
  cat 1>&2 <<-_EOF_
	Usage:
	  $0 {dir} [meta]
	_EOF_
  exit 1
fi

fstree="$(readlink -f "$1")"
if [ $# -eq 2 ] ; then
  meta="$2"
else
  meta=".meta"
fi
if [ ! -d "$fstree" ] ; then
  echo "$fstree: directory not found" 1>&2
  exit 2
fi

ipcdir=$(mktemp -d)
trap "rm -rf $ipcdir" EXIT

runpipe() {
  local fd="$1" ; shift
  mkfifo "$ipcdir/$fd"
  (
    "$@" < "$ipcdir/$fd" &
  )
  eval "exec $fd>"'$ipcdir/$fd'
  rm -f "$ipcdir/$fd"
}

specials() {
  if read -r firstline ; then
    (
      echo "$firstline" | tr '\n' '\0'
      exec tr '\n' '\0'
    ) | ( cd "$1" && cpio -o -H newc -0) | gzip $v > "$2"
  else
    rm -f "$2"
  fi
}

caplist() {
  while read -r firstline
  do
    firstcmd="$(cd "$1" && getcap "$firstline")"
    [ -z "$firstcmd" ] && continue
    # Found stuff...
    (
      echo "$firstcmd"
      tr '\n' '\0'| ( cd "$1" && xargs -0 -r getcap )
    ) | gzip $v > "$2"
    return 0
  done
  rm -f "$2"
}

faclist() {
  if read -r firstline ; then
    (
      echo "$firstline" | tr '\n' '\0'
      exec tr '\n' '\0'
    ) | ( cd "$1" && xargs -0 -r getfacl -p -n ) | gzip $v > "$2"
  else
    rm -f "$2"
  fi
}

gzlist() {
  if read -r firstline ; then
    (
      echo "$firstline"
      exec cat
    ) | gzip $v > "$1"
  else
    rm -f "$1"
  fi
}

metadir="$fstree/$meta"
[ ! -d "$metadir" ] && mkdir "$metadir"

runpipe 10 specials "$fstree" "$metadir/specials.cpio.gz"
runpipe 20 caplist "$fstree" "$metadir/caps.txt.gz"
runpipe 30 faclist "$fstree" "$metadir/facl.txt.gz"
runpipe 40 gzlist "$metadir/filelist.txt.gz"

find "$fstree" -print | sed -e "s!^$fstree/!!" -e "s!^$fstree\$!!" | (
  while read -r FPATH
  do
    (
      [ -z "$FPATH" ] || [ x"$(echo $FPATH | cut -d/ -f1)" = x"$meta" ] || [ ! -e "$fstree/$FPATH" ]
    ) && continue
    set - $(stat -c '%u:%g %a %h %i %s %F' "$fstree/$FPATH")
    [ $# -lt 6 ] && continue
    usrgrp="$1" ; mode="$2" ; hcnt="$3" ino="$4" sz="$5"; shift 5
    ftype="$*"

    case "$ftype" in
    directory|regular\ file|regular\ empty\ file)
      echo "$usrgrp $mode $hcnt $ino $FPATH" >&40
      echo "$FPATH" >&20
      echo "$FPATH" >&30
      ;;
    *)
      echo "$FPATH" >&10
      ;;
    esac
  done
)
