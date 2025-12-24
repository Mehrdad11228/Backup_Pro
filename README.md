Backup_Pro DocumentationBackup_Pro is a comprehensive bash script designed to automate the process of backing up and transferring data for popular proxy management panels. It ensures data safety and simplifies migration between servers.🚀 Quick StartTo run the script directly, use the following command:Bashsudo bash -c "$(curl -sL https://github.com/Mehrdad11228/Backup_Pro/raw/main/Backup-Transfor.sh)"
🛠 User Workflow (Flowchart)Below is the logical structure of how the script operates:PlaintextBackup_Pro Script
├── [1] Backup Module (Local)
│   ├── Select Panel
│   │   ├── Marzban ───> Archive Data ───> Save to /var/lib/backup_pro/local
│   │   ├── Marzneshin ──> Archive Data ───> Save to /var/lib/backup_pro/local
│   │   ├── Pasarguard ──> Archive Data ───> Save to /var/lib/backup_pro/local
│   │   └── X-ui ────────> Archive Data ───> Save to /var/lib/backup_pro/local
│   └── Compression & Logging
│
└── [2] Transfer Module (Remote)
    ├── Select Panel
    │   ├── Marzban / Marzneshin / Pasarguard / X-ui
    ├── Input Remote Server Credentials (IP, Port, User)
    └── Secure Transfer (SCP/RSYNC) ───> Destination Server
📋 Supported PanelsThe script supports the following management panels for backup and migration:Panel NameDescriptionStatusMarzbanV2Ray proxy manager with Python/FastAPI✅ SupportedMarzneshinSpecialized distribution of Marzban✅ SupportedPasarguardAdvanced panel management system✅ SupportedX-uiPopular lightweight web UI for Xray/V2Ray✅ Supported📂 Backup System (Local Storage)In the Backup section, the script identifies critical directories and databases for each panel and creates a compressed archive stored locally.PanelBackup DirectoriesOutput FormatMarzban/var/lib/marzban.tar.gzMarzneshin/var/lib/marzneshin.tar.gzPasarguard/var/lib/pasarguard.tar.gzX-ui/etc/x-ui & /usr/local/x-ui/bin.tar.gz📤 Transfer System (Remote Migration)The Transfer section is designed for server-to-server migration. It automates the archiving and sending process to a destination IP.PanelSource Folders to TransferTransfer MethodMarzban/var/lib/marzbanSSH / SCPMarzneshin/var/lib/marzneshinSSH / SCPPasarguard/var/lib/pasarguardSSH / SCPX-ui/etc/x-ui & Database filesSSH / SCP⚙️ FeaturesAutomated Compression: All backups are automatically zipped to save space.Simple Interface: Interactive menu for easy navigation.Security: Uses secure protocols for data transfer.Universal Compatibility: Works on most Debian-based and RHEL-based distributions.📝 RequirementsRoot access (Sudo)curl and tar installed on the system.SSH access enabled (for the Transfer module).
