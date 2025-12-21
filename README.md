
---

# 🛡️ Backup_Pro (Time Backup & Migration)

**The Ultimate Solution for VPN Panel Data Management: Automated Backups & Server-to-Server Migration.**

---

## 🌐 Language / زبان

* [English Documentation](https://www.google.com/search?q=%23english)
* [مستندات فارسی](https://www.google.com/search?q=%23farsi)

---

<a name="english"></a>

## 🇬🇧 English Documentation

### 📝 Project Overview

**Backup_Pro** is a powerful, interactive Bash utility designed for administrators of VPN panels (Marzban, Marzneshin, Pasarguard, and X-UI). It bridges the gap between data security and server mobility by providing two core modules: **Automated Backups** and **Seamless Migration (Transfer)**.

### ✨ Key Features

#### 1. Automated Backup Module

* **Smart DB Detection:** Automatically identifies SQLite, MySQL, MariaDB, or PostgreSQL by parsing configuration files.
* **Telegram Integration:** Sends compressed backup archives directly to your Telegram bot with detailed HTML reports.
* **Flexible Scheduling:** Built-in CronJob manager to set intervals (Minutes/Hours).
* **Compression Options:** Supports `zip`, `7z` (high compression), `tar.gz`, and more.

#### 2. Server-to-Server Transfer (Migration)

* **Zero-Manual Effort:** Transfers all configurations and databases from a **Source** to a **Destination** server.
* **Remote Management:** Automatically cleans destination directories and restarts the panel service on the remote server after transfer.
* **Secure Sync:** Utilizes `rsync` over SSH for fast and secure data synchronization.

### 🚀 Quick Start (Installation)

Run the following command as **root**:

```bash
sudo bash -c "$(curl -sL https://github.com/Mehrdad11228/Backup_Pro/raw/main/Backup-Transfor.sh)"

```

### 🌲 Script Logic Structure

```text
Backup-Transfor.sh (Entry Point)
├── 🛠️ Initialization (Root Check & Dependency Install)
├── ⚙️ Main Menu (Feature Selection)
│   ├── 📂 Option 1: Install Backuper (Telegram & Cron)
│   │   ├── 🔍 Auto-Detect Panel & Database
│   │   ├── 🔐 Input Telegram Token/ChatID
│   │   ├── 📦 Create Optimized Backup Script
│   │   └── ⏰ Register CronJob
│   │
│   └── 🚛 Option 2: Transfer/Migration (Server to Server)
│       ├── 🔑 Remote Auth (IP, User, Password)
│       ├── 🧹 Remote Cleanup (Wipe old data in Destination)
│       ├── 🛰️ Data Sync (Rsyncing /etc, /var/lib, /opt)
│       ├── 🗄️ DB Migration (SQL Dump & Transfer)
│       └── 🔄 Service Trigger (Remote Panel Restart)
│
└── 📤 Final Report (Professional UI Output)

```

---

<a name="farsi"></a>

## 🇮🇷 مستندات فارسی

### 📝 معرفی پروژه

پروژه **Backup_Pro** یک ابزار تعاملی و قدرتمند تحت Bash است که برای مدیران پنل‌های VPN (مرزبان، مرزنیشین، پاسارگاد و X-UI) طراحی شده است. این اسکریپت با ترکیب دو قابلیت **پشتیبان‌گیری خودکار** و **مهاجرت (انتقال) بین سرورها**، امنیت و جابجایی داده‌ها را ساده می‌کند.

### ✨ ویژگی‌های کلیدی

#### ۱. ماژول پشتیبان‌گیری خودکار

* **تشخیص هوشمند دیتابیس:** شناسایی خودکار نوع پایگاه‌داده (SQLite, MySQL, MariaDB, Postgres) از روی فایل‌های کانفیگ.
* **اتصال به تلگرام:** ارسال فایل‌های فشرده به ربات تلگرام همراه با گزارش دقیق وضعیت سرور.
* **زمان‌بندی (CronJob):** قابلیت تنظیم اجرای خودکار بک‌آپ در فواصل زمانی مشخص (دقیقه یا ساعت).
* **فرمت‌های متنوع:** پشتیبانی از `zip` ، `7z` (فشرده‌سازی حداکثری)، `tar.gz` و غیره.

#### ۲. انتقال سرور به سرور (Migration)

* **انتقال بی‌دردسر:** جابجایی کامل تمام تنظیمات، یوزرها و دیتابیس‌ها از **سرور مبدا** به **سرور مقصد**.
* **مدیریت از راه دور:** پاکسازی خودکار پوشه‌های مقصد و ریستارت کردن پنل در سرور جدید پس از پایان انتقال.
* **همگام‌سازی سریع:** استفاده از پروتکل `rsync` بر بستر SSH برای تضمین سرعت و امنیت.

### 🚀 نصب و اجرای سریع

دستور زیر را در ترمینال خود با دسترسی **root** وارد کنید:

```bash
sudo bash -c "$(curl -sL https://github.com/Mehrdad11228/Backup_Pro/raw/main/Backup-Transfor.sh)"

```

### 🌲 ساختار منطقی و درختی اسکریپت

```text
Backup-Transfor.sh (ورودی اصلی)
├── 🛠️ آماده‌سازی (بررسی دسترسی روت و نصب پیش‌نیازها)
├── ⚙️ منوی اصلی (انتخاب قابلیت)
│   ├── 📂 گزینه ۱: نصب بک‌آپ‌گیر (تلگرام و کرون‌جاب)
│   │   ├── 🔍 تشخیص خودکار پنل و دیتابیس
│   │   ├── 🔐 دریافت توکن تلگرام و چت‌آیدی
│   │   ├── 📦 ساخت اسکریپت بک‌آپ بهینه شده
│   │   └── ⏰ ثبت در زمان‌بندی سیستم (Cron)
│   │
│   └── 🚛 گزینه ۲: انتقال و مهاجرت (سرور به سرور)
│       ├── 🔑 دریافت اطلاعات مقصد (IP, User, Password)
│       ├── 🧹 پاکسازی مقصد (حذف داده‌های قدیمی در مقصد)
│       ├── 🛰️ همگام‌سازی (انتقال مسیرهای etc، var/lib و opt)
│       ├── 🗄️ انتقال دیتابیس (تهیه Dump و انتقال فایل SQL)
│       └── 🔄 راه اندازی مجدد (ریستارت پنل در مقصد)
│
└── 📤 گزارش نهایی (نمایش وضعیت در باکس‌های گرافیکی)

```

---

### 📊 Supported Panels / پنل‌های پشتیبانی شده

| Panel | Backup Paths | Transfer Support |
| --- | --- | --- |
| **Marzban** | `/opt/marzban`, `/var/lib/marzban` | ✅ Yes |
| **Marzneshin** | `/etc/opt/marzneshin`, `/var/lib/marznode`, `/var/lib/marzneshin` | ✅ Yes |
| **Pasarguard** | `/opt/pasarguard`, `/opt/pg-node`, `/var/lib/pasarguard` | ✅ Yes |
| **X-UI** | `/etc/x-ui`, `/root/cert/` | ✅ Yes |

---

**Developed with ❤️ by Mehrdad11228**
*If you find this tool helpful, please give it a ⭐ on GitHub!*

---

**نکته برای گیت‌هاب:** این متن را در فایلی به نام `README.md` در ریشه اصلی مخزن (Repository) خود قرار دهید.

