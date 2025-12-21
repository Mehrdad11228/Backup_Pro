# Backup_Pro — Backup & Transfer Manager (Marzneshin / Marzban / Pasarguard / X-ui)

`Backup_Pro` یک اسکریپت تعاملی (Interactive) برای **تهیه بک‌آپ زمان‌بندی‌شده** و همچنین **انتقال بک‌آپ بین سرورها** است.  
این ابزار از چند پنل رایج (Marzneshin, Marzban, Pasarguard, X-ui) پشتیبانی می‌کند، نوع دیتابیس را تشخیص می‌دهد، بک‌آپ را فشرده‌سازی می‌کند و در صورت نیاز فایل را به **Telegram** ارسال می‌کند.

---

## 🚀 نصب و اجرا (Quick Start)

برای اجرا روی سرور (Ubuntu/Debian) از دستور زیر استفاده کنید:

```bash
sudo bash -c "$(curl -sL https://github.com/Mehrdad11228/Backup_Pro/raw/main/Backup-Transfor.sh)"
✅ قابلیت‌ها

رابط کاربری ترمینالی با رنگ‌بندی و منوی ساده

نصب خودکار پیش‌نیازها (ابزارهای فشرده‌سازی، کلاینت‌های DB، sshpass و…)

بک‌آپ‌گیری از مسیرهای اصلی هر پنل

تشخیص نوع دیتابیس (SQLite / MySQL / MariaDB / PostgreSQL) بر اساس فایل تنظیمات

تهیه Dump دیتابیس (در صورت نیاز) با mysqldump یا pg_dump

فشرده‌سازی با فرمت‌های:

zip / tgz / 7z / tar / gzip / gz

ارسال خودکار بک‌آپ به تلگرام (Bot API)

زمان‌بندی اجرای بک‌آپ با crontab

حذف کامل ابزار (پاک کردن اسکریپت‌ها و cron job ها)

انتقال بک‌آپ به سرور دیگر با sshpass + rsync و اجرای Restart روی مقصد

🧩 پنل‌های پشتیبانی‌شده و مسیرهای بک‌آپ
1) Marzneshin

مسیرهای بک‌آپ:

/etc/opt/marzneshin/

/var/lib/marzneshin/

/var/lib/marznode/ (فقط xray_config.json)

دیتابیس:

تشخیص از docker-compose.yml

SQLite: فایل دیتابیس داخل مسیرهای کپی‌شده موجود است (dump جدا ندارد)

MySQL/MariaDB: dump با mysqldump

2) Marzban

مسیرهای بک‌آپ:

/opt/marzban/

/var/lib/marzban/ (به‌جز فولدر mysql/ در حالت کپی)

دیتابیس:

تشخیص از /opt/marzban/.env و SQLALCHEMY_DATABASE_URL

SQLite: فایل DB همراه فایل‌هاست

MySQL/MariaDB: dump با mysqldump و پسورد از MYSQL_PASSWORD

3) Pasarguard

مسیرهای بک‌آپ:

/opt/pasarguard/

/opt/pg-node/

/var/lib/pasarguard/

/var/lib/pg-node/

دیتابیس:

تشخیص از /opt/pasarguard/.env و SQLALCHEMY_DATABASE_URL

SQLite: dump ندارد

PostgreSQL: dump با pg_dump (معمولاً داخل کانتینر postgres)

MySQL/MariaDB: dump با mysqldump

4) X-ui

مسیرهای بک‌آپ:

/etc/x-ui/

/root/cert/

🗂️ فایل‌هایی که اسکریپت ایجاد می‌کند

پس از نصب (Install Backuper) برای هر پنل، یک اسکریپت بک‌آپ اختصاصی ایجاد می‌شود:

Marzneshin: /root/marzneshin_backup.sh

Marzban: /root/marzban_backup.sh

Pasarguard: /root/pasarguard_backup.sh

X-ui: /root/x-ui_backup.sh

همچنین یک فولدر موقت بک‌آپ می‌سازد (و در پایان پاک می‌کند):

/root/backuper_marzneshin

/root/backuper_marzban

/root/backuper_pasarguard

/root/backuper_x-ui

⏱️ زمان‌بندی (Cron)

داخل مرحله نصب، شما می‌توانید بازه بک‌آپ را انتخاب کنید:

هر N دقیقه: */N * * * *

هر N ساعت: 0 */N * * *

Cron job به صورت خودکار روی root crontab ثبت می‌شود.

📤 ارسال به تلگرام (Telegram)

فایل بک‌آپ با متد sendDocument ارسال می‌شود.

اگر حجم فایل بیش از 50MB شود، یک پیام هشدار برای شما ارسال می‌کند.

کپشن گزارش (Report) شامل:

نام اسکریپت

IP سرور

تاریخ

نام پنل

نوع دیتابیس

مسیرهایی که بک‌آپ شده‌اند

حجم بک‌آپ

توجه: توکن و Chat ID داخل فایل اسکریپت بک‌آپ ذخیره می‌شود. (امنیت را در نظر بگیرید.)

🔁 Transfer Backup (انتقال بک‌آپ بین دو سرور)

این بخش برای مهاجرت/کلون کردن تنظیمات از Server A (منبع) به Server B (مقصد) است.

قبل از انتقال، اسکریپت روی مقصد برخی مسیرها را حذف و دوباره ایجاد می‌کند.

انتقال با rsync انجام می‌شود.

در پایان، روی مقصد دستور Restart پنل اجرا می‌شود:

marzneshin restart

marzban restart

pasarguard restart

x-ui restart

نکته خیلی مهم: این عملیات می‌تواند داده‌های موجود روی سرور مقصد را پاک کند. قبل از انتقال، از مقصد بک‌آپ بگیرید.

🌳 نمودار شاخه‌ای (ساختار کلی اسکریپت)
Backup-Transfor.sh
├─ Pretty UI + Helpers
│  ├─ supports_color / banner / menu_item / info / ok / warn / die
│  └─ need_root / pause / prompt
├─ install_requirements
│  └─ apt update/upgrade + install packages
├─ DB Detection
│  ├─ detect_db_type()            → Marzneshin (docker-compose.yml)
│  ├─ detect_db_type_Marzban()    → Marzban (.env)
│  └─ detect_db_type_pasarguard() → Pasarguard (.env)
├─ Backup Script Generators
│  ├─ create_backup_script()              → Marzneshin
│  ├─ create_backup_script_Marzban()      → Marzban
│  ├─ create_backup_script_pasarguard()   → Pasarguard
│  └─ create_backup_script_x_ui()         → X-ui
├─ Main Actions (Menu)
│  ├─ install_backuper   → ساخت اسکریپت + cron + بک‌آپ اولیه + تلگرام
│  ├─ remove_backuper    → حذف اسکریپت‌ها + حذف cron + پاکسازی پوشه‌ها
│  ├─ run_script         → اجرای دستی بک‌آپ
│  └─ transfer_backup    → انتقال به سرور مقصد + restart
└─ main_menu
   └─ install_requirements سپس نمایش منو

🧭 فلوچارت (Mermaid) — منوی اصلی

گیت‌هاب از Mermaid پشتیبانی می‌کند. اگر در نمایش مشکل داشتید، از Tree بالا استفاده کنید.

flowchart TD
    A([Start]) --> B[Install Requirements<br/>apt update/upgrade + install deps]
    B --> C{Main Menu}
    C -->|1 Install Backuper| D[Choose Panel Type<br/>Marzneshin / Pasarguard / X-ui / Marzban]
    D --> E[Get Telegram Token + Chat ID + Compression + Caption]
    E --> F[Set Cron Interval<br/>Minutes or Hours]
    F --> G[Detect DB Type]
    G --> H[Generate Panel Backup Script<br/>/root/*_backup.sh]
    H --> I[Save Config + Cron Job]
    I --> J[Run First Backup + Send to Telegram]
    C -->|2 Remove Backuper| K[Delete scripts + remove cron + cleanup dirs]
    C -->|3 Run Script| L[Run existing /root/*_backup.sh]
    C -->|4 Transfer Backup| M[Select Panel + Remote Credentials]
    M --> N[Pre-check local paths]
    N --> O[Remote cleanup + rsync transfer]
    O --> P[Remote restart panel]
    C -->|5 Exit| Q([Exit])

🔐 نکات امنیتی و پیشنهادها

ابزار sshpass باعث می‌شود رمز عبور در فرایند/کامند استفاده شود. برای امنیت بهتر:

پیشنهاد: انتقال را با SSH Key انجام دهید (اگر قصد توسعه دارید).

توکن تلگرام داخل فایل بک‌آپ ذخیره می‌شود:

دسترسی فایل‌های /root/*_backup.sh را محدود کنید: chmod 700

بخش Transfer روی مقصد داده‌ها را حذف می‌کند:

قبل از اجرا روی مقصد بک‌آپ داشته باشید.

🛠️ رفع خطاهای رایج

SSH connection error:

IP/یوزر/پسورد را بررسی کنید

پورت SSH (معمولاً 22) باز باشد

سرویس sshd فعال باشد

DB dump failed:

اطلاعات DB در .env یا docker-compose.yml را بررسی کنید

سرویس DB در حال اجرا باشد

mysqldump / pg_dump نصب باشد

Backup too large:

نوع فشرده‌سازی را 7z انتخاب کنید

ارسال تلگرام ممکن است محدودیت حجم داشته باشد
