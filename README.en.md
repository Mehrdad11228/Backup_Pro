# Backup_Pro (Backup & Transfer)

A simple interactive **backup + transfer** tool for popular panels, with **Telegram reporting** and **cron scheduling**.

## Quick Install / Run

```bash
sudo bash -c "$(curl -sL https://github.com/Mehrdad11228/Backup_Pro/raw/main/Backup-Transfor.sh)"
Supported Panels
Marzneshin

Pasarguard

Marzban

X-ui (config + cert only)

What This Script Does
Installs required packages (zip/tar/7z, db clients, sshpass, rsync, etc.)

Shows a menu:

Install Backuper

Remove Backuper

Run Backup Now

Transfer Backup

Creates a panel-specific backup script in /root/

Schedules automatic backups using crontab

Sends backup archive + report to Telegram

Backup (Flow)
text
Copy code
Backup
├─ Detect Panel & DB Type
├─ Copy Required Paths
├─ (Optional) Database Dump
├─ Compress (zip/tgz/7z/tar/gzip)
└─ Send to Telegram + Cleanup
Transfer (Flow)
text
Copy code
Transfer
├─ Select Panel
├─ (Optional) DB Dump on Source
├─ Copy Data to Temp Folder
├─ Remote Cleanup (delete old paths)
├─ Rsync to Remote (sshpass)
└─ Restart Panel on Remote (nohup) + Report
Backup Content (Per Panel)
Marzneshin
Paths:

/etc/opt/marzneshin/

/var/lib/marzneshin/

/var/lib/marznode/ (only needed files)

DB:

SQLite: included in files

MySQL/MariaDB: tries to dump using credentials from docker-compose.yml

Marzban
Paths:

/opt/marzban/

/var/lib/marzban/

DB:

SQLite: included in files

MySQL/MariaDB: dumps using .env (MYSQL_PASSWORD)

Pasarguard
Paths:

/opt/pasarguard/

/opt/pg-node/

/var/lib/pasarguard/

/var/lib/pg-node/

DB:

SQLite: included in files

MySQL/MariaDB: dumps from SQLALCHEMY_DATABASE_URL

PostgreSQL: dumps via docker exec pg_dump (auto-detect postgres container)

X-ui
Paths:

/etc/x-ui/

/root/cert/

Notes
Run as root (sudo).

Telegram may reject large files; script warns when archive size is > 50MB.

Transfer mode removes old paths on remote server before copying (replace strategy).

Generated Files
Backup scripts:

/root/marzneshin_backup.sh

/root/marzban_backup.sh

/root/pasarguard_backup.sh

/root/x-ui_backup.sh
