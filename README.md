
```markdown
# 🛡️ Backup_Pro (Time Backup & Migration)
**Automated Backups & Server-to-Server Migration for VPN Panels.**

---

## 🌐 Select Language / انتخاب زبان
> **Click on your preferred language to expand the documentation.**
>
> **برای مشاهده مستندات، روی زبان مورد نظر خود کلیک کنید.**

---

<details>
<summary><b>🇬🇧 English Documentation (Click to Expand)</b></summary>

### 📝 Project Overview
**Backup_Pro** is a powerful Bash utility designed for administrators of VPN panels. It provides two core modules: **Automated Backups** and **Seamless Migration (Transfer)**.

### ✨ Key Features
* **Smart DB Detection:** Automatically identifies SQLite, MySQL, MariaDB, or PostgreSQL.
* **Telegram Integration:** Sends compressed archives to your Telegram bot.
* **Migration (Transfer):** Move all data from a **Source** to a **Destination** server via SSH.
* **Service Trigger:** Automatically restarts the panel service on the remote server.

### 🚀 Installation
Run as **root**:
```bash
sudo bash -c "$(curl -sL [https://github.com/Mehrdad11228/Backup_Pro/raw/main/Backup-Transfor.sh](https://github.com/Mehrdad11228/Backup_Pro/raw/main/Backup-Transfor.sh))"

```

### 🌲 Script Structure

```text
Backup-Transfor.sh
├── 📂 Option 1: Backup Module
│   ├── 🔍 Auto-Detect DB
│   ├── 📦 Compression (zip, 7z)
│   └── 📤 Telegram & CronJob
└── 🚛 Option 2: Transfer Module
    ├── 🔑 Remote Auth
    ├── 🛰️ Data Sync (Rsync)
    └── 🔄 Remote Restart

```

</details>

---

<details dir="rtl">
<summary><b>🇮🇷 مستندات فارسی (برای مشاهده کلیک کنید)</b></summary>

### 📝 معرفی پروژه

پروژه **Backup_Pro** یک ابزار تحت Bash برای مدیریت پنل‌های VPN است. این اسکریپت دو قابلیت اصلی **پشتیبان‌گیری خودکار** و **انتقال (Migration)** بین سرورها را فراهم می‌کند.

### ✨ ویژگی‌های کلیدی

* **تشخیص هوشمند دیتابیس:** شناسایی خودکار SQLite، MySQL، MariaDB و Postgres.
* **اتصال به تلگرام:** ارسال فایل‌های بک‌آپ به ربات تلگرام همراه با گزارش.
* **انتقال (Transfer):** جابجایی کامل یوزرها و تنظیمات به سرور جدید از طریق SSH.
* **ریستارت خودکار:** اجرای مجدد سرویس پنل در سرور مقصد پس از انتقال.

### 🚀 نصب و اجرا

اجرا با دسترسی **root**:

```bash
sudo bash -c "$(curl -sL [https://github.com/Mehrdad11228/Backup_Pro/raw/main/Backup-Transfor.sh](https://github.com/Mehrdad11228/Backup_Pro/raw/main/Backup-Transfor.sh))"

```

### 🌲 ساختار درختی اسکریپت

```text
Backup-Transfor.sh
├── 📂 گزینه ۱: ماژول بک‌آپ
│   ├── 🔍 تشخیص خودکار دیتابیس
│   ├── 📦 فشرده‌سازی (zip, 7z)
│   └── 📤 تلگرام و کرون‌جاب
└── 🚛 گزینه ۲: ماژول انتقال (Transfer)
    ├── 🔑 احراز هویت مقصد
    ├── 🛰️ همگام‌سازی (Rsync)
    └── 🔄 ریستارت پنل مقصد

```

</details>

---

**Developed with ❤️ by Mehrdad11228**

```

---

### چرا این نسخه بهتر است؟
1.  **اشغال فضای کمتر:** وقتی صفحه باز می‌شود، کاربر فقط دو گزینه "English" و "فارسی" را می‌بیند و صفحه با متن‌های طولانی شلوغ نشده است.
2.  **تمرکز کاربر:** کاربر روی هر کدام کلیک کند، فقط همان بخش باز می‌شود (مثل یک منوی آکاردئونی).
3.  **ظاهر حرفه‌ای:** در گیت‌هاب این متد برای پروژه‌های چندزبانه بسیار مرسوم است.

**نکته:** در بخش فارسی از `dir="rtl"` استفاده کردم تا چیدمان متن برای فارسی‌زبانان از راست به چپ باشد.

آیا می‌خواهید بخش **نمونه گزارش تلگرام** (اسکرین‌شات یا کد گزارش) را هم به یکی از این بخش‌ها اضافه کنم؟

```
