#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

set -euf -o pipefail

bashio::log.info "Starting Hass.io rsync-folders docker container!"

server=$(bashio::config server)
port=$(bashio::config port)
target=$(bashio::config target)
username=$(bashio::config username)
password=$(bashio::config password)
auto_purge=$(bashio::config auto_purge)
ssh_enabled=$(bashio::config ssh_enabled)
rsync_opts="-aHz --delete -F --no-perms"

gen_backup=$(bashio::config gen_backup)
metaindex=$(bashio::config metaindex)

if $gen_backup ; then
  bname="Automatic backup $(date +%Y-%m-%d_%H:%M)"
  bashio::log.info "Automatic backup \"$bname\""
  payload=$(bashio::var.json name "$bname")
  bashio::api.supervisor POST /backups/new/full "$payload"
  bashio::cache.flush_all
fi

for folder in config addons backup share ssl media
do
  folder_enabled=$(bashio::config f_$folder)
  [ -z "$folder_enabled" ] && continue
  if [ x"$folder_enabled" = x"true" ] ; then
    $metaindex && /meta.sh "/$folder"
    if $ssh_enabled ; then
      rsyncurl="$username@$server:$target/$folder"
      bashio::log.info "Start rsync/ssh $folder to $rsyncurl"
      sshpass -p "$password" rsync  -e "ssh -p $port -o StrictHostKeyChecking=no" $rsync_opts "/$folder/" "$rsyncurl"
    else
      rsyncurl="$username@$server::$target/$folder"
      bashio::log.info "Start rsync/rsync $folder to $rsyncurl"
      sshpass -p "$password" rsync $rsync_opts --port=$port "/$folder/" "$rsyncurl"
    fi
  else
    bashio::log.info "Skipping $folder"
  fi
done

if [ $auto_purge -ge 1 ]; then
  bashio::log.info "Start auto purge, keep last $auto_purge backups"
  rm -f $(ls -1t /backup | grep '\.tar$' | awk "NR>$auto_purge")
fi

bashio::log.info " Finished rsync-folder"
