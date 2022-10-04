#!/bin/bash
set -e

echo "[Info] Starting Hass.io rsync-folders docker container!"

CONFIG_PATH=/data/options.json
server=$(jq --raw-output ".server" $CONFIG_PATH)
port=$(jq --raw-output ".port" $CONFIG_PATH)
directory=$(jq --raw-output ".directory" $CONFIG_PATH)
username=$(jq --raw-output ".username" $CONFIG_PATH)
password=$(jq --raw-output ".password" $CONFIG_PATH)
auto_purge=$(jq --raw-output ".auto_purge" $CONFIG_PATH)
ssh_enabled=$(jq --raw-output ".ssh_enabled" $CONFIG_PATH)

for folder in config addons backup share ssl media
do
  folder_enabled=$(jq --raw-output ".f_${folder}" $CONFIG_PATH)
  echo "Folder: $folder enabled:$folder_enabled ($ssh_enabled)"
  [ -z "$folder_enabled" ] && continue
  if [ x"$folder_enabled" = x"true" ] ; then
    echo "[Info] Start rsync $folder"
  else
    echo "[Info] Skipping $folder"
  fi

#~ rsyncurl="$username@$server:$directory"
#~ echo "[Info] Start rsync backups to $rsyncurl"
#~ sshpass -p $password rsync -av -e "ssh -p $port -o StrictHostKeyChecking=no" /backup/ $rsyncurl
done

#~ if [ $auto_purge -ge 1 ]; then
	#~ echo "[Info] Start auto purge, keep last $auto_purge backups"
	#~ rm `ls -t /backup/*.tar | awk "NR>$auto_purge"`
#~ fi

echo "[Info] Finished rsync-folder"
