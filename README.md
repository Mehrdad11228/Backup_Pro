# Backup_Pro — بکاپ و ترنسفر پنل‌ها (Telegram + SSH)

[English README](README.en.md)

این اسکریپت برای **بکاپ‌گیری زمان‌بندی‌شده** و همچنین **ترنسفر (مهاجرت)** داده‌ها بین دو سرور طراحی شده است.

## پنل‌های پشتیبانی‌شده
- **Marzneshin**
- **Marzban**
- **Pasarguard**
- **X-ui**

## نصب و اجرا
> نکته: اسکریتپت هنگام اجرا، پکیج‌ها را نصب/آپدیت می‌کند. با دسترسی root اجرا کنید.

```bash
sudo bash -c "$(curl -sL https://github.com/Mehrdad11228/Backup_Pro/raw/main/Backup-Transfor.sh)"
قابلیت‌ها (خلاصه)

ساخت بکاپ و ارسال به تلگرام (Bot Token + Chat ID)

انتخاب نوع فشرده‌سازی: zip / tgz / 7z / tar / gzip / gz

زمان‌بندی با cron (دقیقه‌ای یا ساعتی)

تشخیص نوع دیتابیس (بسته به پنل)

انتقال فایل‌ها به سرور مقصد با sshpass + rsync

ری‌استارت پنل روی سرور مقصد پس از ترنسفر

مسیرهای بکاپ/ترنسفر (جدول)
Backup (فایل‌هایی که داخل آرشیو بکاپ قرار می‌گیرند)
Panel	Included Paths (Source)	Notes
Marzneshin	/etc/opt/marzneshin/
/var/lib/marznode/ (فقط xray_config.json)
/var/lib/marzneshin/	پوشه‌های mysql و assets داخل /var/lib/marzneshin/ بکاپ نمی‌شوند
Marzban	/opt/marzban/
/var/lib/marzban/	مسیر mysql/ از /var/lib/marzban/ حذف می‌شود
Pasarguard	/opt/pasarguard/
/opt/pg-node/
/var/lib/pasarguard/
/var/lib/pg-node/	-
X-ui	/etc/x-ui/
/root/cert/	-
Transfer (مسیرهایی که به سرور مقصد کپی می‌شوند)
Panel	Remote Replace/Copy (Destination)	Optional DB / Extra
Marzneshin	/etc/opt/marzneshin
/var/lib/marznode
/var/lib/marzneshin	اگر DB ≠ sqlite: انتقال /var/lib/marzneshin/mysql + (اختیاری) فولدر دامپ: /root/Marzneshin-DB
Marzban	/opt/marzban
/var/lib/marzban	(اختیاری) فولدر دامپ: /root/Marzban-DB
Pasarguard	/opt/pasarguard
/opt/pg-node
/var/lib/pasarguard
/var/lib/pg-node	اگر DB=MySQL/MariaDB: انتقال /var/lib/mysql/pasarguard (با توقف/استارت سرویس)
اگر DB=PostgreSQL: انتقال /var/lib/postgresql (با توقف/استارت سرویس)
(اختیاری) فولدر دامپ: /root/Pasarguard-DB
X-ui	/etc/x-ui
/root/cert	گزینه نصب X-ui روی مقصد (Sanaei/Alireza) + سپس x-ui restart
پشتیبانی دیتابیس (خلاصه)

Marzneshin: sqlite / mysql / mariadb

Marzban: sqlite / mysql / mariadb

Pasarguard: sqlite / mysql / mariadb / postgresql

X-ui: دیتابیس ندارد (فقط فایل/کانفیگ)

نمودار شاخه‌ای عملیات (فقط انگلیسی)
Backup Flow
Backup
├─ Install requirements (apt)
├─ Select panel
├─ Collect paths into /root/backuper_<panel>/
├─ Detect DB type (if supported)
│  ├─ SQLite -> include DB files from copied folders
│  └─ MySQL/MariaDB/PostgreSQL -> create SQL dump (if configured)
├─ Compress (zip/tgz/7z/tar/gzip/gz)
├─ Send to Telegram (document + caption)
└─ Cleanup temp files

Transfer Flow
Transfer
├─ Select panel
├─ Pre-check required folders on Source
├─ Get remote SSH credentials
├─ (Optional) Create DB dump on Source
├─ Build local temp payload folder
├─ Remote cleanup (delete & recreate target paths)
├─ rsync data to Remote
├─ (Optional) rsync DB dump folder to Remote
├─ Restart panel on Remote
└─ Cleanup local temp files + show report

نکات مهم

ترنسفر مسیرهای مقصد را پاک می‌کند و جایگزین می‌کند؛ قبل از اجرا مطمئن شوید.

برای ترنسفر، دسترسی SSH (پورت 22) و پسورد کاربر مقصد لازم است.

بهتر است قبل از استفاده در محیط اصلی، یک‌بار روی سرور تست اجرا شود.
