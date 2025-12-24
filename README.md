
---

# BackupPro Documentation

**Backup_Pro** is a comprehensive bash script designed to automate the process of backing up and transferring data for popular proxy management panels. It ensures data safety and simplifies migration between servers.

## 🚀 Quick Start

To run the script directly, use the following command:

```bash
sudo bash -c "$(curl -sL https://github.com/Alfred-1313/Backup_Pro/raw/main/Backup-Transfor.sh)"

```

---

## 🛠 User Workflow (Flowchart)

Below is the logical structure of how the script operates:

```text
Backup_Pro Script
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

```

---

## 📋 Supported Panels

The script supports the following management panels for backup and migration:

| Panel Name | Description | Status |
| --- | --- | --- |
| **Marzban** | V2Ray proxy manager with Python/FastAPI | ✅ Supported |
| **Marzneshin** | Specialized distribution of Marzban | ✅ Supported |
| **Pasarguard** | Advanced panel management system | ✅ Supported |
| **X-ui** | Popular lightweight web UI for Xray/V2Ray | ✅ Supported |

---

## 📂 Backup System (Local Storage)

In the **Backup** section, the script identifies critical directories and databases for each panel and creates a compressed archive stored locally.

| Panel | Backup Directories | Output Format |
| --- | --- | --- |
| **Marzban** | `/var/lib/marzban` | `.tar.gz` |
| **Marzneshin** | `/var/lib/marzneshin` | `.tar.gz` |
| **Pasarguard** | `/var/lib/pasarguard` | `.tar.gz` |
| **X-ui** | `/etc/x-ui` & `/usr/local/x-ui/bin` | `.tar.gz` |

---

## 📤 Transfer System (Remote Migration)

The **Transfer** section is designed for server-to-server migration. It automates the archiving and sending process to a destination IP.

| Panel | Source Folders to Transfer | Transfer Method |
| --- | --- | --- |
| **Marzban** | `/var/lib/marzban` | SSH / SCP |
| **Marzneshin** | `/var/lib/marzneshin` | SSH / SCP |
| **Pasarguard** | `/var/lib/pasarguard` | SSH / SCP |
| **X-ui** | `/etc/x-ui` & Database files | SSH / SCP |

---

## ⚙️ Features

* **Automated Compression:** All backups are automatically zipped to save space.
* **Simple Interface:** Interactive menu for easy navigation.
* **Security:** Uses secure protocols for data transfer.
* **Universal Compatibility:** Works on most Debian-based and RHEL-based distributions.

---

## 📝 Requirements

* Root access (Sudo)
* `curl` and `tar` installed on the system.
* SSH access enabled (for the Transfer module).

---

### آیا مایل هستید بخش "عیب‌یابی" (Troubleshooting) یا "سوالات متداول" (FAQ) را هم به این داکیومنت اضافه کنم؟
