# rsync-folders

## Configuration

This section describes each of the add-on configuration options.

Example add-on configuration:

```yaml
server: rsync-server
port: 22
target: hassio-backups
username: user
password: password

auto_purge: 0
ssh_enabled: true
f_config: true
f_addons: false
f_backup: true
f_share: false
f_ssl: false
f_media: false
```
or you can use also `!secret` eg.: (edit configuration in YAML):

```yaml
password: '!secret rsync_backups_password'
```

### Option: `server` (required)

Server host or IP, e.g. `localhost`.

### Option: `port` (required)

Server port, e.g. `22` or `873`.

### Option: `target` (required)

Directory on the server for backups, e.g. `~/hassio-backups`.  Note
for `rsync` protocol, this is the `rsync` module to use.  You can
have sub-folders in the module if needed.

### Option: `user` (required)

Server user, e.g. `root`.

### Option: `password` (required)

Server password, e.g. `password`.

### Option: `auto_purge` (required)

The number of recent backups keep in Home Assistant, e.g. "5".
Set to "0" to disable automatic deletion of backups.

### Option: `gen_backup`

Trigger a Full backup when run

### Option: `metaindex`

Save metadata when doing rsync.

### Option: `ssh_enabled`

Use `ssh` protocol, or the `rsync` protocol.

### Option: `f_config`

Sync `config` folder

### Option: `f_addons`

Sync `addons` folder

### Option: `f_backup`

Sync `backup` folder

### Option: `f_share`

Sync `share` folder

### Option: `f_ssl`

Sync `ssl` folder

### Option: `f_media`

Sync `media` folder


## How to use

Run addon in the automation, example automation below:

```yaml
- alias: 'hassio_daily_backup'
  trigger:
    platform: 'time'
    at: '3:00:00'
  action:
    - service: 'hassio.backup_full'
      data_template:
        name: "Automated Backup {{ now().strftime('%Y-%m-%d') }}"
        # password: !secret hassio_snapshot_password
    # wait for snapshot done, then sync snapshots
    - delay: '00:10:00'
    - service: 'hassio.addon_start'
      data:
        addon: '2caa1d32_rsync_backups' # you can get the addon id from URL when you go to the addon info
```


