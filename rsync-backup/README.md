# Rsync Backups add-on for Home Assistant

Transfers directories from your Home Assistant instance to a remote rsync server.

## Instalation

Go to your Add-on Store in the Supervisor panel and add https://github.com/stefangries/hassio-addons to your repositories.
Afterwards the addon can be installed via the UI.

## Configuration

This section describes each of the add-on configuration options.

Example add-on configuration:

```
server: 192.168.178.12
port: 22
directory:
  - source: /backup/
    destination: /volume1/NetBackup/HomeAssistant/backups/
    flags: '-av'
  - source: /share/NextCloud/
    destination: /volume1/NetBackup/HomeAssistant/nextcloud/
    flags: '-av --delete'
username: my_rsync_username
password: my_rsync_password
auto_purge: 0
```

### Option: `server` (required)

Server host or IP, e.g. `localhost`, a Domain or an IP.

### Option: `port` (required)

Server ssh port, e.g. `22`.

### Option: `directory` (required)

A list of backup tasks. Each tasks consists of the following values:

#### Option: `source` (required)
Directory on the Home Assistant instance that should be backed up, e.g. `/share/myfolder/`.

#### Option: `destination` (required)
Directory on the destination Server where your backup should be placed, e.g. `/volume1/NetBackup/HomeAssistant/`.

#### Option: `flags` (required)
Options which should be passed to rsync, e.g. `-av`. When copying recursive directories, use `-av -r`. If you like to delete files at the destiation, which are missing at the source, use `-av --delete`.
All options are documented at https://download.samba.org/pub/rsync/rsync.1.

### Option: `username` (required)

Server ssh user, e.g. `root`.

### Option: `password` (required)

Server ssh password, e.g. `password`.

### Option: `auto_purge` (required)

This addon is able to delete old backup files in your `/backup` folder after syncronizing them.
The number of recent backups keep in Home Assistant, e.g. "5". Set to "0" to disable automatic deletion of backups.
The `auto_purge` option is only available for your `/backup` folder!

## How to use

Run addon in the automation, example automation below:

```yaml
- alias: 'hassio_daily_backup'
  trigger:
    platform: 'time'
    at: '3:00:00'
  action:
    - service: 'hassio.snapshot_full'
      data_template:
        name: "Automated Backup {{ now().strftime('%Y-%m-%d') }}"
        password: !secret hassio_snapshot_password
    # wait for snapshot done, then sync snapshots
    - delay: '00:10:00'
    - service: 'hassio.addon_start'
      data:
        addon: '69c7aa1d_rsync_backups_sgr'
```

# Credits

This Addon is based on the great work of Karol Tyka, available at https://github.com/tykarol/homeassistant-addon-rsync-backup.
