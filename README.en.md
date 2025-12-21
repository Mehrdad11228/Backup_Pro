

Interactive terminal UI (colors, menus)

Automatic dependency installation (compression tools, DB clients, sshpass, etc.)

Panel-aware backup paths (per supported panel)

Database type detection (SQLite / MySQL / MariaDB / PostgreSQL)

Optional database dump:

mysqldump for MySQL/MariaDB

pg_dump (often via Docker exec) for PostgreSQL

Compression formats:

zip / tgz / 7z / tar / gzip / gz

Send backups to Telegram (Bot API)

Schedule backups via crontab

Clean uninstall (remove scripts + cron jobs + folders)

Transfer backups between servers using sshpass + rsync and trigger remote restart

📦 Installation & Run
sudo bash -c "$(curl -sL https://github.com/Mehrdad11228/Backup_Pro/raw/main/Backup-Transfor.sh)"


Requires root privileges. On start, it runs apt update/upgrade and installs required packages.

🗂️ What gets backed up?
Marzneshin

Paths:

/etc/opt/marzneshin/

/var/lib/marzneshin/

/var/lib/marznode/ (only xray_config.json)

DB:

Detected from docker-compose.yml

SQLite: included in copied files

MySQL/MariaDB: dumped via mysqldump

Marzban

Paths:

/opt/marzban/

/var/lib/marzban/ (excluding some subdirs in copy stage)

DB:

Detected from /opt/marzban/.env (SQLALCHEMY_DATABASE_URL)

SQLite: included in files

MySQL/MariaDB: dumped via mysqldump (password from MYSQL_PASSWORD)

Pasarguard

Paths:

/opt/pasarguard/, /opt/pg-node/

/var/lib/pasarguard/, /var/lib/pg-node/

DB:

Detected from /opt/pasarguard/.env

SQLite: no dump

PostgreSQL: pg_dump (commonly inside docker postgres container)

MySQL/MariaDB: mysqldump

X-ui

Paths:

/etc/x-ui/

/root/cert/

🔁 Transfer Backup (Server A ➜ Server B)

Performs local pre-check to ensure required paths exist on source

Cleans target paths (deletes old data) and transfers with rsync

Triggers restart on destination:

marzneshin restart / marzban restart / pasarguard restart / x-ui restart

⚠️ Warning: Transfer can delete existing data on the destination server. Backup destination first.

🌳 Script Structure (Tree)
Backup-Transfor.sh
├─ UI helpers + menu rendering
├─ install_requirements (apt + packages)
├─ DB detection (Marzneshin/Marzban/Pasarguard)
├─ Backup script generators (creates /root/*_backup.sh)
├─ Menu actions:
│  ├─ Install Backuper (cron + first backup + telegram)
│  ├─ Remove Backuper
│  ├─ Run Script Now
│  └─ Transfer Backup
└─ main_menu

🧭 Flowchart (Mermaid)
flowchart TD
    A([Start]) --> B[Install Requirements]
    B --> C{Menu}
    C -->|Install| D[Collect Telegram + Compression + Caption]
    D --> E[Set Cron]
    E --> F[Detect DB]
    F --> G[Generate Backup Script]
    G --> H[Run First Backup + Telegram]
    C -->|Remove| I[Remove scripts + cron + cleanup]
    C -->|Run Now| J[Execute existing backup script]
    C -->|Transfer| K[Remote credentials + pre-check + rsync + restart]
    C -->|Exit| L([Exit])

🔐 Security Notes

sshpass uses passwords non-interactively; consider SSH keys if you plan to improve security.

Telegram token/chat_id are written into the generated backup scripts under /root/.
Restrict permissions: chmod 700 /root/*_backup.sh
