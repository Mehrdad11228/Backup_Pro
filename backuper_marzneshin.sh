#!/bin/bash

# ==============================
#         Pretty UI Setup
# ==============================
supports_color() { [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; }

if supports_color; then
  RESET=$'\e[0m'
  BOLD=$'\e[1m'
  DIM=$'\e[2m'

  BLUE=$'\e[34m'
  CYAN=$'\e[96m'
  GREEN=$'\e[92m'
  YELLOW=$'\e[93m'
  RED=$'\e[91m'
  GRAY=$'\e[90m'
  MAGENTA=$'\e[95m'
else
  RESET=""; BOLD=""; DIM=""
  BLUE=""; CYAN=""; GREEN=""; YELLOW=""; RED=""; GRAY=""; MAGENTA=""
fi

ICON_OK="${GREEN}✔${RESET}"
ICON_ERR="${RED}✖${RESET}"
ICON_INFO="${CYAN}ℹ${RESET}"
ICON_WARN="${YELLOW}⚠${RESET}"
ARROW="${CYAN}➜${RESET}"

WIDTH=41
TITLE="Time Backup"
LINE=$(printf '%*s' "$WIDTH" '' | tr ' ' '=')

hr() { echo -e "${GRAY}$(printf '%*s' "${WIDTH:-41}" '' | tr ' ' '=')${RESET}"; }
hr2() { echo -e "${GRAY}$(printf '%*s' 41 '' | tr ' ' '-')${RESET}"; }

center_text() {
  local text="$1"
  local w="${2:-41}"
  local pad=$(( (w - ${#text}) / 2 ))
  (( pad < 0 )) && pad=0
  printf "%*s%s\n" "$pad" "" "$text"
}

banner() {
  local t="$1"
  clear
  echo -e "${GRAY}=========================================${RESET}"
  echo -e "${BOLD}${BLUE}$(center_text "$t" 41)${RESET}"
  echo -e "${GRAY}=========================================${RESET}"
  echo
}

menu_item() {
  local n="$1"; shift
  echo -e "${CYAN}[${n}]${RESET} $*"
}

prompt() {
  local msg="$1"
  read -p "${ARROW} ${msg}" REPLY
}

pause() {
  read -p "${DIM}Press Enter to continue...${RESET}" _
}

die() {
  echo -e "${ICON_ERR} ${RED}$*${RESET}"
  pause
  return 1
}

info() { echo -e "${ICON_INFO} $*"; }
ok()   { echo -e "${ICON_OK} $*"; }
warn() { echo -e "${ICON_WARN} $*"; }

need_root() {
  if [[ $EUID -ne 0 ]]; then
    echo -e "${ICON_ERR} ${RED}Please run as root (sudo).${RESET}"
    exit 1
  fi
}

# ==============================
#   Install Required Packages
# ==============================
install_requirements() {
  need_root
  banner "Installing Packages"
  info "Updating system and installing required packages..."

  apt update -y && apt upgrade -y
  apt install -y zip unzip tar gzip p7zip-full mariadb-client sshpass xz-utils zstd postgresql-client-common

  ok "Requirements installed."
  sleep 1
}

# ==============================
# Detect Database Type Marzban
# ==============================
detect_db_type_Marzban() {
  local env_file="/opt/marzban/.env"
  [[ ! -f "$env_file" ]] && { echo ".env not found."; echo ""; return; }

  local line db_url
  line=$(grep -E '^\s*SQLALCHEMY_DATABASE_URL\s*=' "$env_file" | tail -n1)
  [[ -z "$line" ]] && { echo "SQLALCHEMY_DATABASE_URL not found."; echo ""; return; }

  db_url=${line#*=}
  db_url=$(echo "$db_url" | sed -e 's/[[:space:]]*#.*$//' \
                                -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
                                -e 's/^["'\'']\(.*\)["'\'']$/\1/')
  [[ -z "$db_url" ]] && { echo "SQLALCHEMY_DATABASE_URL not found."; echo ""; return; }

  if [[ "$db_url" == sqlite* ]]; then
    echo "sqlite"
  elif [[ "$db_url" == mariadb* ]]; then
    echo "mariadb"
  elif [[ "$db_url" == mysql* || "$db_url" == *"mysql+"* || "$db_url" == *"mysql://"* ]]; then
    echo "mysql"
  elif [[ "$db_url" == *"mariadb"* ]]; then
    echo "mariadb"
  else
    echo "Unsupported DB URL: $db_url"
    echo ""
  fi
}

# ==============================
# Detect Database Type Pasarguard
# ==============================
detect_db_type_pasarguard() {
  local env_file="/opt/pasarguard/.env"
  [[ ! -f "$env_file" ]] && { echo ".env not found."; echo ""; return; }

  local db_url
  db_url=$(grep -E '^SQLALCHEMY_DATABASE_URL=' "$env_file" | tail -n1 | cut -d'=' -f2- | tr -d "\"'")
  db_url=$(echo "$db_url" | xargs)
  [[ -z "$db_url" ]] && { echo "SQLALCHEMY_DATABASE_URL not found."; echo ""; return; }

  if [[ "$db_url" == sqlite* ]]; then
    echo "sqlite"
  elif [[ "$db_url" == postgresql* ]]; then
    echo "postgresql"
  elif [[ "$db_url" == mysql* || "$db_url" == *"mysql+"* || "$db_url" == *"mysql://"* ]]; then
    echo "mysql"
  elif [[ "$db_url" == *"mariadb"* ]]; then
    echo "mariadb"
  else
    echo "Unsupported DB URL: $db_url"
    echo ""
  fi
}

# ==============================
# Detect Database Type Marzneshin
# ==============================
detect_db_type() {
  local docker_file="/etc/opt/marzneshin/docker-compose.yml"
  if [[ ! -f "$docker_file" ]]; then
    echo "docker-compose.yml not found. Assuming SQLite."
    echo "sqlite"
    return
  fi

  local db_url
  db_url=$(grep -i "SQLALCHEMY_DATABASE_URL" "$docker_file" | head -1 | cut -d'"' -f2 | cut -d"'" -f2)
  if [[ -z "$db_url" ]]; then
    echo "SQLALCHEMY_DATABASE_URL not found. Assuming SQLite."
    echo "sqlite"
    return
  fi

  if [[ "$db_url" == sqlite* ]]; then
    echo "sqlite"
  elif [[ "$db_url" == *"mysql"* ]] && [[ "$db_url" != *"mariadb"* ]]; then
    echo "mysql"
  elif [[ "$db_url" == *"mariadb"* ]] || grep -q "MARIADB_ROOT_PASSWORD" "$docker_file"; then
    echo "mariadb"
  else
    echo "sqlite"
  fi
}

# ==============================
# Create Backup Script Marzban
# ==============================
create_backup_script_Marzban() {
  local db_type="$1"
  local script_file="/root/marzban_backup.sh"

  cat > "$script_file" <<'EOF'
#!/bin/bash
BACKUP_DIR="/root/backuper_marzban"
BOT_TOKEN="__BOT_TOKEN__"
CHAT_ID="__CHAT_ID__"
CAPTION="__CAPTION__"
COMP_TYPE="__COMP_TYPE__"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_BASE="$BACKUP_DIR/backup_$DATE"
ARCHIVE=""

mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR" || exit 1

# Copy paths Marzban
mkdir -p opt/marzban var/lib/marzban
rsync -a /opt/marzban/ opt/marzban/ 2>/dev/null || true
rsync -a --exclude='mysql/' /var/lib/marzban/ var/lib/marzban/ 2>/dev/null || true

# ==============================
# Database Backup Section Marzban
# ==============================
DB_BACKUP_DONE=0
ENV_FILE="/opt/marzban/.env"
if [ -f "$ENV_FILE" ]; then
EOF

  if [[ "$db_type" == "sqlite" ]]; then
    cat >> "$script_file" <<'EOF'
    # SQLite: No external dump needed
    echo "SQLite detected. DB files included in /var/lib/marzban/"
    DB_BACKUP_DONE=1
EOF
  elif [[ "$db_type" == "mysql" || "$db_type" == "mariadb" ]]; then
    cat >> "$script_file" <<'EOF'
    DB_NAME="marzban"
    DB_USER="marzban"
    DB_PASS=""

    # Read MYSQL_PASSWORD from .env
    DB_PASS=$(
        grep -E '^[[:space:]]*MYSQL_PASSWORD[[:space:]]*=' "$ENV_FILE" \
        | tail -n1 \
        | sed -E 's/^[[:space:]]*MYSQL_PASSWORD[[:space:]]*=[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/' \
        | tr -d "'"
    )

    if [ -n "$DB_PASS" ]; then
        echo "Backing up MySQL/MariaDB database (user=$DB_USER, db=$DB_NAME)..."
        mysqldump -h 127.0.0.1 -P 3306 -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/marzban_backup.sql" 2>/dev/null && DB_BACKUP_DONE=1
        [ $DB_BACKUP_DONE -eq 1 ] && echo "DB backup completed." || echo "DB backup failed."
    else
        echo "MYSQL_PASSWORD not found (or empty) in $ENV_FILE."
    fi
EOF
  fi

  cat >> "$script_file" <<'EOF'
else
    echo ".env not found. Skipping DB backup."
fi

# ==============================
# Compression Section
# ==============================
ARCHIVE="$OUTPUT_BASE"
if [ "$COMP_TYPE" == "zip" ]; then
    ARCHIVE="$OUTPUT_BASE.zip"
    zip -r "$ARCHIVE" . > /dev/null
elif [ "$COMP_TYPE" == "tgz" ]; then
    ARCHIVE="$OUTPUT_BASE.tgz"
    tar -czf "$ARCHIVE" . > /dev/null
elif [ "$COMP_TYPE" == "7z" ]; then
    ARCHIVE="$OUTPUT_BASE.7z"
    7z a -t7z -m0=lzma2 -mx=9 -mfb=256 -md=1536m -ms=on "$ARCHIVE" . > /dev/null
elif [ "$COMP_TYPE" == "tar" ]; then
    ARCHIVE="$OUTPUT_BASE.tar"
    tar -cf "$ARCHIVE" . > /dev/null
elif [ "$COMP_TYPE" == "gzip" ] || [ "$COMP_TYPE" == "gz" ]; then
    ARCHIVE="$OUTPUT_BASE.tar.gz"
    tar -cf - . | gzip > "$ARCHIVE"
else
    ARCHIVE="$OUTPUT_BASE.zip"
    zip -r "$ARCHIVE" . > /dev/null
fi

# ==============================
# File size check & Telegram send
# ==============================
if [ ! -f "$ARCHIVE" ]; then
    echo "Backup file not created!"
    rm -rf "$BACKUP_DIR"/*
    exit 1
fi

FILE_SIZE_MB=$(du -m "$ARCHIVE" | cut -f1)
echo "Backup created: $ARCHIVE ($FILE_SIZE_MB MB)"

# Send to Telegram
if [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ]; then
    SCRIPT_NAME=$(basename "$0")
    SERVER_IP=$(hostname -I | awk '{print $1}')
    REPORT_CAPTION=$(cat <<EOFCAP
$CAPTION

➖➖➖➖➖➖➖➖➖➖

📦 Backup Report

• <code>Script Name:</code> $SCRIPT_NAME
• <code>IP Server:</code> $SERVER_IP
• <code>Date:</code> $(date '+%Y-%m-%d %H:%M:%S')
• <code>Panel:</code> __PANEL_NAME__
• <code>Database:</code> __DB_TYPE__
• <code>Backup File:</code> /opt/marzban/ & /var/lib/marzban/
• <code>Backup Size:</code> ${FILE_SIZE_MB} MB
EOFCAP
)
    CAPTION_WITH_SIZE="$REPORT_CAPTION"
    if [ "$FILE_SIZE_MB" -gt 50 ]; then
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
             -d chat_id="$CHAT_ID" \
             -d text="Warning: Backup file > 50MB (${FILE_SIZE_MB} MB). Telegram may not accept it." >/dev/null
    fi
    curl -s \
         -F chat_id="$CHAT_ID" \
         -F parse_mode=HTML \
         -F caption="$CAPTION_WITH_SIZE" \
         -F document=@"$ARCHIVE" \
         "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" >/dev/null && \
         echo "Backup successfully sent to Telegram!" || echo "Failed to send via Telegram."
else
    echo "Telegram credentials missing. Skipping send."
fi

# Cleanup
rm -rf "$BACKUP_DIR"/*
EOF

  chmod +x "$script_file"
}

# ==============================
# Create Backup Script Marzneshin
# ==============================
create_backup_script() {
  local db_type="$1"
  local script_file="/root/marzneshin_backup.sh"

  cat > "$script_file" <<'EOF'
#!/bin/bash
BACKUP_DIR="/root/backuper_marzneshin"
BOT_TOKEN="__BOT_TOKEN__"
CHAT_ID="__CHAT_ID__"
CAPTION="__CAPTION__"
COMP_TYPE="__COMP_TYPE__"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_BASE="$BACKUP_DIR/backup_$DATE"
ARCHIVE=""
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR" || exit 1

# Copy paths Marzneshin
mkdir -p etc/opt var/lib/marznode var/lib/marzneshin
cp -r /etc/opt/marzneshin/ etc/opt/ 2>/dev/null || true
rsync -a --include='xray_config.json' --exclude='*' /var/lib/marznode/ var/lib/marznode/ 2>/dev/null || true
rsync -a --exclude='mysql' --exclude='assets' /var/lib/marzneshin/ var/lib/marzneshin/ 2>/dev/null || true

# ==============================
# Database Backup Section Marzneshin
# ==============================
DB_BACKUP_DONE=0
DOCKER_COMPOSE="/etc/opt/marzneshin/docker-compose.yml"
if [ -f "$DOCKER_COMPOSE" ]; then
EOF

  if [[ "$db_type" == "sqlite" ]]; then
    cat >> "$script_file" <<'EOF'
    # SQLite: No external dump needed
    echo "SQLite detected. DB files included in /var/lib/marzneshin/"
    DB_BACKUP_DONE=1
EOF
  elif [[ "$db_type" == "mysql" ]]; then
    cat >> "$script_file" <<'EOF'
    DB_PASS=$(grep 'MYSQL_ROOT_PASSWORD:' "$DOCKER_COMPOSE" | awk -F': ' '{print $2}' | tr -d ' "')
    DB_NAME=$(grep 'MYSQL_DATABASE:' "$DOCKER_COMPOSE" | awk -F': ' '{print $2}' | tr -d ' "')
    DB_USER="root"
    if [ -n "$DB_PASS" ] && [ -n "$DB_NAME" ]; then
        echo "Backing up MySQL database..."
        mysqldump -h 127.0.0.1 -P 3306 -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/marzneshin_backup.sql" 2>/dev/null && DB_BACKUP_DONE=1
        [ $DB_BACKUP_DONE -eq 1 ] && echo "MySQL backup completed." || echo "MySQL backup failed."
    else
        echo "MySQL credentials not found."
    fi
EOF
  elif [[ "$db_type" == "mariadb" ]]; then
    cat >> "$script_file" <<'EOF'
    DB_PASS=$(grep 'MARIADB_ROOT_PASSWORD:' "$DOCKER_COMPOSE" | awk -F': ' '{print $2}' | tr -d ' "')
    DB_NAME=$(grep 'MARIADB_DATABASE:' "$DOCKER_COMPOSE" | awk -F': ' '{print $2}' | tr -d ' "')
    DB_USER="root"
    if [ -n "$DB_PASS" ] && [ -n "$DB_NAME" ]; then
        echo "Backing up MariaDB database..."
        mysqldump -h 127.0.0.1 -P 3306 -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/marzneshin_backup.sql" 2>/dev/null && DB_BACKUP_DONE=1
        [ $DB_BACKUP_DONE -eq 1 ] && echo "MariaDB backup completed." || echo "MariaDB backup failed."
    else
        echo "MariaDB credentials not found."
    fi
EOF
  fi

  cat >> "$script_file" <<'EOF'
else
    echo "docker-compose.yml not found. Skipping DB backup."
fi

# ==============================
# Compression Section
# ==============================
ARCHIVE="$OUTPUT_BASE"
if [ "$COMP_TYPE" == "zip" ]; then
    ARCHIVE="$OUTPUT_BASE.zip"
    zip -r "$ARCHIVE" . > /dev/null
elif [ "$COMP_TYPE" == "tgz" ]; then
    ARCHIVE="$OUTPUT_BASE.tgz"
    tar -czf "$ARCHIVE" . > /dev/null
elif [ "$COMP_TYPE" == "7z" ]; then
    ARCHIVE="$OUTPUT_BASE.7z"
    7z a -t7z -m0=lzma2 -mx=9 -mfb=256 -md=1536m -ms=on "$ARCHIVE" . > /dev/null
elif [ "$COMP_TYPE" == "tar" ]; then
    ARCHIVE="$OUTPUT_BASE.tar"
    tar -cf "$ARCHIVE" . > /dev/null
elif [ "$COMP_TYPE" == "gzip" ] || [ "$COMP_TYPE" == "gz" ]; then
    ARCHIVE="$OUTPUT_BASE.tar.gz"
    tar -cf - . | gzip > "$ARCHIVE"
else
    ARCHIVE="$OUTPUT_BASE.zip"
    zip -r "$ARCHIVE" . > /dev/null
fi

# ==============================
# File size check & Telegram send
# ==============================
if [ ! -f "$ARCHIVE" ]; then
    echo "Backup file not created!"
    rm -rf "$BACKUP_DIR"/*
    exit 1
fi

FILE_SIZE_MB=$(du -m "$ARCHIVE" | cut -f1)
echo "Backup created: $ARCHIVE ($FILE_SIZE_MB MB)"

# Send to Telegram
if [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ]; then
    SCRIPT_NAME=$(basename "$0")
    SERVER_IP=$(hostname -I | awk '{print $1}')
    REPORT_CAPTION=$(cat <<EOFCAP
$CAPTION

➖➖➖➖➖➖➖➖➖➖

📦 Backup Report

• <code>Script Name:</code> $SCRIPT_NAME
• <code>IP Server:</code> $SERVER_IP
• <code>Date:</code> $(date '+%Y-%m-%d %H:%M:%S')
• <code>Panel:</code> __PANEL_NAME__
• <code>Database:</code> __DB_TYPE__
• <code>Backup File:</code> /etc/opt/marzneshin/ & /var/lib/marzneshin/ & /var/lib/marznode/
• <code>Backup Size:</code> ${FILE_SIZE_MB} MB
EOFCAP
)
    CAPTION_WITH_SIZE="$REPORT_CAPTION"
    if [ "$FILE_SIZE_MB" -gt 50 ]; then
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
             -d chat_id="$CHAT_ID" \
             -d text="Warning: Backup file > 50MB (${FILE_SIZE_MB} MB). Telegram may not accept it." >/dev/null
    fi
    curl -s \
         -F chat_id="$CHAT_ID" \
         -F parse_mode=HTML \
         -F caption="$CAPTION_WITH_SIZE" \
         -F document=@"$ARCHIVE" \
         "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" >/dev/null && \
         echo "Backup successfully sent to Telegram!" || echo "Failed to send via Telegram."
else
    echo "Telegram credentials missing. Skipping send."
fi

# Cleanup
rm -rf "$BACKUP_DIR"/*
EOF

  chmod +x "$script_file"
}

# ==============================
# Create Backup Script Pasarguard
# ==============================
create_backup_script_pasarguard() {
  local db_type="$1"
  local script_file="/root/pasarguard_backup.sh"

  cat > "$script_file" <<'EOF'
#!/bin/bash
BACKUP_DIR="/root/backuper_pasarguard"
BOT_TOKEN="__BOT_TOKEN__"
CHAT_ID="__CHAT_ID__"
CAPTION="__CAPTION__"
COMP_TYPE="__COMP_TYPE__"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_BASE="$BACKUP_DIR/backup_$DATE"
ARCHIVE=""
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR" || exit 1

# Copy paths Pasarguard
mkdir -p opt/pasarguard opt/pg-node var/lib/pasarguard var/lib/pg-node
rsync -a /opt/pasarguard/   opt/pasarguard/   2>/dev/null || true
rsync -a /opt/pg-node/      opt/pg-node/      2>/dev/null || true
rsync -a /var/lib/pasarguard/ var/lib/pasarguard/ 2>/dev/null || true
rsync -a /var/lib/pg-node/    var/lib/pg-node/    2>/dev/null || true

# ==============================
# Database Backup Section Pasarguard
# ==============================
DB_BACKUP_DONE=0
ENV_FILE="/opt/pasarguard/.env"

parse_db_url() {
    local url="$1"
    url="${url#*://}"
    local creds="${url%%@*}"
    local hostdb="${url#*@}"
    local user="${creds%%:*}"
    local pass="${creds#*:}"; pass="${pass%%@*}"
    local hostport="${hostdb%%/*}"
    local dbname="${hostdb#*/}"
    local host="${hostport%%:*}"
    local port="${hostport##*:}"
    echo "$user" "$pass" "$host" "$port" "$dbname"
}

if [ -f "$ENV_FILE" ]; then
    DB_URL=$(grep -E '^SQLALCHEMY_DATABASE_URL=' "$ENV_FILE" | tail -n1 | cut -d'=' -f2- | tr -d "\"'" | xargs)
    if [ -n "$DB_URL" ]; then
        DB_PROTO=$(echo "$DB_URL" | cut -d':' -f1)
        if [[ "$DB_PROTO" == sqlite* ]]; then
            echo "SQLite detected. DB files included in copied folders; no dump needed."
            DB_BACKUP_DONE=1
        else
            read DB_USER DB_PASS DB_HOST DB_PORT DB_NAME < <(parse_db_url "$DB_URL")
            : "${DB_USER:=pasarguard}"
            : "${DB_NAME:=pasarguard}"
            if [[ "$DB_PROTO" == postgresql* ]]; then
                : "${DB_PORT:=5432}"
                echo "Backing up PostgreSQL database..."
                PGPASSWORD="$DB_PASS" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -F c "$DB_NAME" > "$BACKUP_DIR/pasarguard_backup.dump" 2>/dev/null && DB_BACKUP_DONE=1
                [ $DB_BACKUP_DONE -eq 1 ] && echo "PostgreSQL backup completed." || echo "PostgreSQL backup failed."
            elif [[ "$DB_PROTO" == mysql* || "$DB_PROTO" == mariadb* ]]; then
                : "${DB_PORT:=3306}"
                echo "Backing up MariaDB/MySQL database..."
                mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" \
                    --single-transaction --routines --triggers --events --skip-lock-tables \
                    "$DB_NAME" > "$BACKUP_DIR/pasarguard_backup.sql" 2>/dev/null && DB_BACKUP_DONE=1
                [ $DB_BACKUP_DONE -eq 1 ] && echo "MariaDB/MySQL backup completed." || echo "MariaDB/MySQL backup failed."
            else
                echo "Unsupported DB protocol: $DB_PROTO"
            fi
        fi
    else
        echo "SQLALCHEMY_DATABASE_URL not found. Skipping DB backup."
    fi
else
    echo ".env not found. Skipping DB backup."
fi

# ==============================
# Compression Section
# ==============================
ARCHIVE="$OUTPUT_BASE"
if [ "$COMP_TYPE" == "zip" ]; then
    ARCHIVE="$OUTPUT_BASE.zip"
    zip -r "$ARCHIVE" . > /dev/null
elif [ "$COMP_TYPE" == "tgz" ]; then
    ARCHIVE="$OUTPUT_BASE.tgz"
    tar -czf "$ARCHIVE" . > /dev/null
elif [ "$COMP_TYPE" == "7z" ]; then
    ARCHIVE="$OUTPUT_BASE.7z"
    7z a -t7z -m0=lzma2 -mx=9 -mfb=256 -md=1536m -ms=on "$ARCHIVE" . > /dev/null
elif [ "$COMP_TYPE" == "tar" ]; then
    ARCHIVE="$OUTPUT_BASE.tar"
    tar -cf "$ARCHIVE" . > /dev/null
elif [ "$COMP_TYPE" == "gzip" ] || [ "$COMP_TYPE" == "gz" ]; then
    ARCHIVE="$OUTPUT_BASE.tar.gz"
    tar -cf - . | gzip > "$ARCHIVE"
else
    ARCHIVE="$OUTPUT_BASE.zip"
    zip -r "$ARCHIVE" . > /dev/null
fi

# ==============================
# File size check & Telegram send
# ==============================
if [ ! -f "$ARCHIVE" ]; then
    echo "Backup file not created!"
    rm -rf "$BACKUP_DIR"/*
    exit 1
fi

FILE_SIZE_MB=$(du -m "$ARCHIVE" | cut -f1)
echo "Backup created: $ARCHIVE ($FILE_SIZE_MB MB)"

# Send to Telegram
if [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ]; then
    SCRIPT_NAME=$(basename "$0")
    SERVER_IP=$(hostname -I | awk '{print $1}')
    REPORT_CAPTION=$(cat <<EOFCAP
$CAPTION

➖➖➖➖➖➖➖➖➖➖

📦 Backup Report

• <code>Script Name:</code> $SCRIPT_NAME
• <code>IP Server:</code> $SERVER_IP
• <code>Date:</code> $(date '+%Y-%m-%d %H:%M:%S')
• <code>Panel:</code> __PANEL_NAME__
• <code>Database:</code> __DB_TYPE__
• <code>Backup File:</code> $ARCHIVE
• <code>Backup Size:</code> ${FILE_SIZE_MB} MB
EOFCAP
)
    CAPTION_WITH_SIZE="$REPORT_CAPTION"
    if [ "$FILE_SIZE_MB" -gt 50 ]; then
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
             -d chat_id="$CHAT_ID" \
             -d parse_mode=HTML \
             -d text="Warning: Backup file > 50MB (${FILE_SIZE_MB} MB). Telegram may not accept it." >/dev/null
    fi
    curl -s \
         -F chat_id="$CHAT_ID" \
         -F parse_mode=HTML \
         -F caption="$CAPTION_WITH_SIZE" \
         -F document=@"$ARCHIVE" \
         "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" >/dev/null && \
         echo "Backup successfully sent to Telegram!" || echo "Failed to send via Telegram."
else
    echo "Telegram credentials missing. Skipping send."
fi

# Cleanup
rm -rf "$BACKUP_DIR"/*
EOF

  chmod +x "$script_file"
}

# ==============================
# Create Backup Script X-UI
# ==============================
create_backup_script_x_ui() {
  local script_file="/root/x-ui_backup.sh"

  cat > "$script_file" <<'EOF'
#!/bin/bash
BACKUP_DIR="/root/backuper_x-ui"
BOT_TOKEN="__BOT_TOKEN__"
CHAT_ID="__CHAT_ID__"
CAPTION="__CAPTION__"
COMP_TYPE="__COMP_TYPE__"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_BASE="$BACKUP_DIR/backup_$DATE"
ARCHIVE=""
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR" || exit 1

# Copy paths X-UI (contents only)
mkdir -p etc/x-ui root/cert/
rsync -a /etc/x-ui/ etc/x-ui/ 2>/dev/null || true
cp -a /root/cert/. root/cert/ 2>/dev/null || true

# ==============================
# Compression Section
# ==============================
ARCHIVE="$OUTPUT_BASE"
if [ "$COMP_TYPE" == "zip" ]; then
    ARCHIVE="$OUTPUT_BASE.zip"
    zip -r "$ARCHIVE" . > /dev/null
elif [ "$COMP_TYPE" == "tgz" ]; then
    ARCHIVE="$OUTPUT_BASE.tgz"
    tar -czf "$ARCHIVE" . > /dev/null
elif [ "$COMP_TYPE" == "7z" ]; then
    ARCHIVE="$OUTPUT_BASE.7z"
    7z a -t7z -m0=lzma2 -mx=9 -mfb=256 -md=1536m -ms=on "$ARCHIVE" . > /dev/null
elif [ "$COMP_TYPE" == "tar" ]; then
    ARCHIVE="$OUTPUT_BASE.tar"
    tar -cf "$ARCHIVE" . > /dev/null
elif [ "$COMP_TYPE" == "gzip" ] || [ "$COMP_TYPE" == "gz" ]; then
    ARCHIVE="$OUTPUT_BASE.tar.gz"
    tar -cf - . | gzip > "$ARCHIVE"
else
    ARCHIVE="$OUTPUT_BASE.zip"
    zip -r "$ARCHIVE" . > /dev/null
fi

# ==============================
# File size check & Telegram send
# ==============================
if [ ! -f "$ARCHIVE" ]; then
    echo "Backup file not created!"
    rm -rf "$BACKUP_DIR"/*
    exit 1
fi

FILE_SIZE_MB=$(du -m "$ARCHIVE" | cut -f1)
echo "Backup created: $ARCHIVE ($FILE_SIZE_MB MB)"

# Send to Telegram
if [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ]; then
    SCRIPT_NAME=$(basename "$0")
    SERVER_IP=$(hostname -I | awk '{print $1}')
REPORT_CAPTION=$(cat <<EOFCAP

➖➖➖➖➖➖➖➖➖➖

📦 Backup Report

• <code>Script Name:</code> $SCRIPT_NAME
• <code>IP Server:</code> $SERVER_IP
• <code>Date:</code> $(date '+%Y-%m-%d')
• <code>Panel:</code> X-ui
• <code>Backup File:</code> /etc/x-ui/ & /root/cert/
• <code>Usage Backup:</code> ${FILE_SIZE_MB} MB
EOFCAP
)

CAPTION_WITH_SIZE="$REPORT_CAPTION"

if [ "$FILE_SIZE_MB" -gt 50 ]; then
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
         -d chat_id="$CHAT_ID" \
         -d parse_mode=HTML \
         -d text="Warning: Backup file &gt; 50MB (${FILE_SIZE_MB} MB). Telegram may not accept it." >/dev/null
fi

curl -s \
     -F chat_id="$CHAT_ID" \
     -F parse_mode=HTML \
     -F caption="$CAPTION_WITH_SIZE" \
     -F document=@"$ARCHIVE" \
     "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" >/dev/null && \
     echo "Backup successfully sent to Telegram!" || echo "Failed to send via Telegram."
else
    echo "Telegram credentials missing. Skipping send."
fi

# Cleanup
rm -rf "$BACKUP_DIR"/*
EOF

  chmod +x "$script_file"
}

# ==============================
# Install Backuper (UI improved)
# ==============================
install_backuper() {
  need_root

  while true; do
    banner "Select Backup Type"
    menu_item 1 "Marzneshin"
    menu_item 2 "Pasarguard"
    menu_item 3 "X-ui"
    menu_item 4 "Marzban"
    echo
    hr2
    read -p "${ARROW} Choose an option: " PANEL_OPTION
    [[ -z "$PANEL_OPTION" ]] && { warn "No option selected."; sleep 1; return; }

    case "$PANEL_OPTION" in
      1) PANEL_TYPE="Marzneshin"; break ;;
      2) PANEL_TYPE="Pasarguard"; break ;;
      3) PANEL_TYPE="X-ui"; break ;;
      4) PANEL_TYPE="Marzban"; break ;;
      *) warn "Invalid choice. Try again."; sleep 1 ;;
    esac
  done

  banner "Setup: $PANEL_TYPE"

  echo -e "${BOLD}${MAGENTA}Step 1${RESET} - Enter Telegram Bot Token"
  read -p "${ARROW} Token Telegram: " BOT_TOKEN
  [[ -z "$BOT_TOKEN" ]] && { die "Token cannot be empty."; return; }

  echo -e "\n${BOLD}${MAGENTA}Step 2${RESET} - Enter Chat ID"
  read -p "${ARROW} Chat ID: " CHAT_ID
  [[ -z "$CHAT_ID" ]] && { die "Chat ID cannot be empty."; return; }

  echo -e "\n${BOLD}${MAGENTA}Step 3${RESET} - Select Compression Type"
  cat <<'EOF'
File Type:
  [1] zip
  [2] tgz
  [3] 7z
  [4] tar
  [5] gzip
  [6] gz
EOF
  read -p "${ARROW} Choose (1-6) [default: zip]: " COMP_TYPE_OPT
  case $COMP_TYPE_OPT in
    1) COMP_TYPE="zip" ;;
    2) COMP_TYPE="tgz" ;;
    3) COMP_TYPE="7z" ;;
    4) COMP_TYPE="tar" ;;
    5) COMP_TYPE="gzip" ;;
    6) COMP_TYPE="gz" ;;
    ""|*) COMP_TYPE="zip"; info "Using default: zip" ;;
  esac

  echo -e "\n${BOLD}${MAGENTA}Step 4${RESET} - Enter File Caption (optional)"
  read -p "${ARROW} Caption File: " CAPTION
  [[ -z "$CAPTION" ]] && CAPTION=""

  # Step 5 - Backup Interval (minutes or hours)
  while true; do
    clear
    echo -e "${GRAY}$LINE${RESET}"
    local pad=$(( (WIDTH - ${#TITLE}) / 2 ))
    printf "%*s%b%b%b\n" "$pad" "" "$BOLD$BLUE" "$TITLE" "$RESET"
    echo -e "${GRAY}$LINE${RESET}"
    echo
    menu_item 1 "Minutes"
    menu_item 2 "Hours"
    echo
    hr2
    read -p "${ARROW} Choose option [1-2]: " TIME_UNIT

    if [[ -z "$TIME_UNIT" ]]; then
      warn "No option selected. Please choose."
      sleep 1
      continue
    fi

    case "$TIME_UNIT" in
      1)
        clear
        read -p "${ARROW} Enter backup interval in minutes [default: 10]: " MINUTES
        [[ -z "$MINUTES" ]] && MINUTES=10
        if ! [[ "$MINUTES" =~ ^[0-9]+$ ]] || (( MINUTES < 1 || MINUTES > 59 )); then
          warn "Invalid minutes. Using default: 10."
          MINUTES=10
        fi
        CRON_TIME="*/$MINUTES * * * *"
        ok "Backup will run every $MINUTES minute(s)."
        break
        ;;
      2)
        clear
        read -p "${ARROW} Enter backup interval in hours (1-24) [default: 1]: " HOURS
        [[ -z "$HOURS" ]] && HOURS=1
        if ! [[ "$HOURS" =~ ^[0-9]+$ ]] || (( HOURS < 1 || HOURS > 24 )); then
          warn "Invalid hours. Using default: 1."
          HOURS=1
        fi
        CRON_TIME="0 */$HOURS * * *"
        ok "Backup will run every $HOURS hour(s)."
        break
        ;;
      *)
        warn "Invalid choice. Try again."
        sleep 1
        ;;
    esac
  done

  # Step 6 - Detect Database + build scripts
  if [[ "$PANEL_TYPE" == "Pasarguard" ]]; then
    MISSING_DIRS=()
    [[ ! -d "/opt/pasarguard" ]]     && MISSING_DIRS+=("/opt/pasarguard")
    [[ ! -d "/opt/pg-node" ]]        && MISSING_DIRS+=("/opt/pg-node")
    [[ ! -d "/var/lib/pasarguard" ]] && MISSING_DIRS+=("/var/lib/pasarguard")
    [[ ! -d "/var/lib/pg-node" ]]    && MISSING_DIRS+=("/var/lib/pg-node")
    if (( ${#MISSING_DIRS[@]} > 0 )); then
      banner "Pasarguard Not Found"
      echo -e "${RED}Missing required paths:${RESET}"
      for d in "${MISSING_DIRS[@]}"; do echo -e "  ${RED}-${RESET} $d"; done
      pause
      return
    fi

    echo -e "\n${BOLD}${MAGENTA}Step 6${RESET} - Detecting Database Type (Pasarguard)"
    DB_TYPE=$(detect_db_type_pasarguard)
    case $DB_TYPE in
      postgresql) ok "Pasarguard: PostgreSQL detected." ;;
      mariadb|mysql) ok "Pasarguard: MariaDB/MySQL detected." ;;
      sqlite) ok "Pasarguard: SQLite detected." ;;
      "") die "DB type not found. Aborting." ; return ;;
      *) die "Unsupported DB type. Aborting." ; return ;;
    esac

    create_backup_script_pasarguard "$DB_TYPE"
    sed -i "s|__BOT_TOKEN__|$BOT_TOKEN|g" /root/pasarguard_backup.sh
    sed -i "s|__CHAT_ID__|$CHAT_ID|g" /root/pasarguard_backup.sh
    sed -i "s|__CAPTION__|$CAPTION|g" /root/pasarguard_backup.sh
    sed -i "s|__COMP_TYPE__|$COMP_TYPE|g" /root/pasarguard_backup.sh
    sed -i "s|__PANEL_NAME__|Pasarguard|g" /root/pasarguard_backup.sh
    sed -i "s|__DB_TYPE__|$DB_TYPE|g" /root/pasarguard_backup.sh

    (crontab -l 2>/dev/null | grep -v "pasarguard_backup.sh"; echo "$CRON_TIME bash /root/pasarguard_backup.sh") | crontab -
    echo -e "\n${BOLD}${MAGENTA}Step 7${RESET} - Running first backup..."
    bash /root/pasarguard_backup.sh
    ok "Backup successfully sent"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="Backuper installed and first backup sent." >/dev/null

  elif [[ "$PANEL_TYPE" == "Marzneshin" ]]; then
    MISSING_DIRS=()
    [[ ! -d "/etc/opt/marzneshin" ]] && MISSING_DIRS+=("/etc/opt/marzneshin")
    [[ ! -d "/var/lib/marzneshin" ]] && MISSING_DIRS+=("/var/lib/marzneshin")
    [[ ! -d "/var/lib/marznode" ]]   && MISSING_DIRS+=("/var/lib/marznode")
    if (( ${#MISSING_DIRS[@]} > 0 )); then
      banner "Marzneshin Not Found"
      echo -e "${RED}Missing required paths:${RESET}"
      for d in "${MISSING_DIRS[@]}"; do echo -e "  ${RED}-${RESET} $d"; done
      pause
      return
    fi

    echo -e "\n${BOLD}${MAGENTA}Step 6${RESET} - Detecting Database Type (Marzneshin)"
    DB_TYPE=$(detect_db_type)
    case $DB_TYPE in
      sqlite) ok "SQLite detected." ;;
      mysql) ok "MySQL detected." ;;
      mariadb) ok "MariaDB detected." ;;
      *) die "DB type unknown/unsupported. Aborting." ; return ;;
    esac

    create_backup_script "$DB_TYPE"
    sed -i "s|__BOT_TOKEN__|$BOT_TOKEN|g" /root/marzneshin_backup.sh
    sed -i "s|__CHAT_ID__|$CHAT_ID|g" /root/marzneshin_backup.sh
    sed -i "s|__CAPTION__|$CAPTION|g" /root/marzneshin_backup.sh
    sed -i "s|__COMP_TYPE__|$COMP_TYPE|g" /root/marzneshin_backup.sh
    sed -i "s|__PANEL_NAME__|Marzneshin|g" /root/marzneshin_backup.sh
    sed -i "s|__DB_TYPE__|$DB_TYPE|g" /root/marzneshin_backup.sh

    (crontab -l 2>/dev/null | grep -v "marzneshin_backup.sh"; echo "$CRON_TIME bash /root/marzneshin_backup.sh") | crontab -
    echo -e "\n${BOLD}${MAGENTA}Step 7${RESET} - Running first backup..."
    bash /root/marzneshin_backup.sh
    ok "Backup successfully sent"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="Backuper installed and first backup sent." >/dev/null

  elif [[ "$PANEL_TYPE" == "Marzban" ]]; then
    MISSING_DIRS=()
    [[ ! -d "/opt/marzban" ]]     && MISSING_DIRS+=("/opt/marzban")
    [[ ! -d "/var/lib/marzban" ]] && MISSING_DIRS+=("/var/lib/marzban")
    if (( ${#MISSING_DIRS[@]} > 0 )); then
      banner "Marzban Not Found"
      echo -e "${RED}Missing required paths:${RESET}"
      for d in "${MISSING_DIRS[@]}"; do echo -e "  ${RED}-${RESET} $d"; done
      pause
      return
    fi

    echo -e "\n${BOLD}${MAGENTA}Step 6${RESET} - Detecting Database Type (Marzban)"
    DB_TYPE=$(detect_db_type_Marzban)
    case $DB_TYPE in
      sqlite) ok "SQLite detected." ;;
      mysql) ok "MySQL detected." ;;
      mariadb) ok "MariaDB detected." ;;
      *) die "DB type unknown/unsupported. Aborting." ; return ;;
    esac

    DB_LABEL="$DB_TYPE"
    if [[ "$DB_TYPE" == "mysql" || "$DB_TYPE" == "mariadb" ]]; then
      DB_LABEL="Mysql/Maria"
    fi

    create_backup_script_Marzban "$DB_TYPE"
    sed -i "s|__BOT_TOKEN__|$BOT_TOKEN|g" /root/marzban_backup.sh
    sed -i "s|__CHAT_ID__|$CHAT_ID|g" /root/marzban_backup.sh
    sed -i "s|__CAPTION__|$CAPTION|g" /root/marzban_backup.sh
    sed -i "s|__COMP_TYPE__|$COMP_TYPE|g" /root/marzban_backup.sh
    sed -i "s|__PANEL_NAME__|Marzban|g" /root/marzban_backup.sh
    sed -i "s|__DB_TYPE__|$DB_LABEL|g" /root/marzban_backup.sh

    (crontab -l 2>/dev/null | grep -v "marzban_backup.sh"; echo "$CRON_TIME bash /root/marzban_backup.sh") | crontab -
    echo -e "\n${BOLD}${MAGENTA}Step 7${RESET} - Running first backup..."
    bash /root/marzban_backup.sh
    ok "Backup successfully sent"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="Backuper installed and first backup sent." >/dev/null

  else
    if [[ ! -d "/etc/x-ui" ]]; then
      banner "X-ui Not Found"
      echo -e "${RED}Missing required path:${RESET}\n  ${RED}-${RESET} /etc/x-ui"
      pause
      return
    fi

    echo -e "\n${BOLD}${MAGENTA}Step 6${RESET} - Creating X-ui backup script..."
    create_backup_script_x_ui
    sed -i "s|__BOT_TOKEN__|$BOT_TOKEN|g" /root/x-ui_backup.sh
    sed -i "s|__CHAT_ID__|$CHAT_ID|g" /root/x-ui_backup.sh
    sed -i "s|__CAPTION__|$CAPTION|g" /root/x-ui_backup.sh
    sed -i "s|__COMP_TYPE__|$COMP_TYPE|g" /root/x-ui_backup.sh
    sed -i "s|__PANEL_NAME__|X-ui|g" /root/x-ui_backup.sh

    (crontab -l 2>/dev/null | grep -v "x-ui_backup.sh"; echo "$CRON_TIME bash /root/x-ui_backup.sh") | crontab -
    echo -e "\n${BOLD}${MAGENTA}Step 7${RESET} - Running first backup..."
    bash /root/x-ui_backup.sh
    ok "Backup successfully sent"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="Backuper installed and first backup sent." >/dev/null
  fi

  pause
}

# ==============================
# Remove Backuper (UI improved)
# ==============================
remove_backuper() {
  need_root
  banner "Remove Backuper"
  info "Removing scripts and cron jobs..."

  rm -f /root/marzneshin_backup.sh /root/pasarguard_backup.sh /root/marzban_backup.sh /root/x-ui_backup.sh
  rm -rf /root/backuper_marzneshin /root/backuper_pasarguard /root/backuper_marzban /root/backuper_x-ui
  crontab -l 2>/dev/null | grep -v 'marzneshin_backup.sh' | grep -v 'pasarguard_backup.sh' | grep -v 'marzban_backup.sh' | grep -v 'x-ui_backup.sh' | crontab -

  ok "Backuper removed successfully."
  pause
}

# ==============================
# Run Script Manually (UI improved)
# ==============================
run_script() {
  need_root
  banner "Run Backup Now"

  if   [[ -f /root/marzban_backup.sh ]]; then
    info "Running: marzban_backup.sh"
    bash /root/marzban_backup.sh
  elif [[ -f /root/marzneshin_backup.sh ]]; then
    info "Running: marzneshin_backup.sh"
    bash /root/marzneshin_backup.sh
  elif [[ -f /root/pasarguard_backup.sh ]]; then
    info "Running: pasarguard_backup.sh"
    bash /root/pasarguard_backup.sh
  elif [[ -f /root/x-ui_backup.sh ]]; then
    info "Running: x-ui_backup.sh"
    bash /root/x-ui_backup.sh
  else
    warn "Backup script not found. Install first."
  fi

  pause
}

# ==============================
# Transfer Backup (UI improved)
# ==============================
transfer_backup() {
  need_root

  while true; do
    banner "Transfer Backup"
    menu_item 1 "Marzneshin"
    menu_item 2 "Pasarguard"
    menu_item 3 "X-ui"
    echo
    hr2
    read -p "${ARROW} Choose (1-3): " PANEL_OPTION
    case "$PANEL_OPTION" in
      1) PANEL_TYPE="Marzneshin"; break ;;
      2) PANEL_TYPE="Pasarguard"; break ;;
      3) PANEL_TYPE="X-ui"; break ;;
      *) warn "Invalid choice. Please select 1, 2, or 3."; sleep 1 ;;
    esac
  done

  clear
  echo -e "${BOLD}${BLUE}Enter Remote Server Details${RESET}\n"
  read -p "${ARROW} IP Server [Client]: " REMOTE_IP
  read -p "${ARROW} User Server [Client] (default: root): " REMOTE_USER
  [[ -z "$REMOTE_USER" ]] && REMOTE_USER="root"
  read -s -p "${ARROW} Password Server [Client]: " REMOTE_PASS
  echo

  INSTALL_XUI="N"
  XUI_VARIANT="S"
  if [[ "$PANEL_TYPE" == "X-ui" ]]; then
    read -p "${ARROW} Install X-ui on remote? (Y/n) [default: N]: " INSTALL_XUI
    INSTALL_XUI=${INSTALL_XUI^^}
    [[ -z "$INSTALL_XUI" ]] && INSTALL_XUI="N"
    if [[ "$INSTALL_XUI" == "Y" ]]; then
      read -p "${ARROW} Choose X-ui variant: Sanaei or Alireza (S/A) [default: S]: " XUI_VARIANT
      XUI_VARIANT=${XUI_VARIANT^^}
      [[ -z "$XUI_VARIANT" ]] && XUI_VARIANT="S"
      if [[ "$XUI_VARIANT" != "A" ]]; then XUI_VARIANT="S"; fi
    fi
  fi

  TRANSFER_SCRIPT=$(mktemp /tmp/Transfer_backup.XXXXXX.sh)
  trap 'rm -f "$TRANSFER_SCRIPT"' EXIT

  if [[ "$PANEL_TYPE" == "Marzneshin" ]]; then
    PANEL_NAME="Marzneshin"
    BACKUP_DIR="/root/backuper_marzneshin"
    REMOTE_ETC="/etc/opt/marzneshin"
    REMOTE_NODE="/var/lib/marznode"
    REMOTE_MARZ="/var/lib/marzneshin"
    REMOTE_DB="/root/Marzneshin-Mysql"
    DB_ENABLED=0
    DB_DIR_NAME="Marzneshin-Mysql"

    MISSING_DIRS=()
    [[ ! -d "/etc/opt/marzneshin" ]] && MISSING_DIRS+=("/etc/opt/marzneshin")
    [[ ! -d "/var/lib/marzneshin" ]] && MISSING_DIRS+=("/var/lib/marzneshin")
    [[ ! -d "/var/lib/marznode" ]] && MISSING_DIRS+=("/var/lib/marznode")
    if [[ ${#MISSING_DIRS[@]} -gt 0 ]]; then
      banner "CRITICAL ERROR"
      echo -e "${RED}The following required directories are missing:${RESET}"
      for dir in "${MISSING_DIRS[@]}"; do echo -e "  ${RED}-${RESET} $dir"; done
      echo
      warn "Please install Marzneshin properly before transferring."
      pause
      return
    fi

    DB_TYPE=$(detect_db_type)
    case $DB_TYPE in
      sqlite)
        info "Database: SQLite (files included in /var/lib/marzneshin)"
        DB_BACKUP_SCRIPT=""
        DB_ENABLED=0
        ;;
      mysql)
        info "Database: MySQL"
        DB_ENABLED=1
        DB_BACKUP_SCRIPT=$(cat <<'EOF'
DOCKER_COMPOSE="/etc/opt/marzneshin/docker-compose.yml"
DB_PASS=\$(grep 'MYSQL_ROOT_PASSWORD:' "\$DOCKER_COMPOSE" | awk -F': ' '{print \$2}' | tr -d ' "')
DB_NAME=\$(grep 'MYSQL_DATABASE:' "\$DOCKER_COMPOSE" | awk -F': ' '{print \$2}' | tr -d ' "')
DB_USER="root"
if [ -n "\$DB_PASS" ] && [ -n "\$DB_NAME" ]; then
    mkdir -p "\$OUTPUT_DIR/Marzneshin-Mysql"
    mysqldump -h 127.0.0.1 -P 3306 -u "\$DB_USER" -p"\$DB_PASS" "\$DB_NAME" > "\$OUTPUT_DIR/Marzneshin-Mysql/marzneshin_backup.sql" 2>/dev/null && \
    echo "MySQL backup created." || echo "MySQL backup failed."
else
    echo "MySQL credentials not found in docker-compose.yml"
fi
EOF
)
        ;;
      mariadb)
        info "Database: MariaDB"
        DB_ENABLED=1
        DB_BACKUP_SCRIPT=$(cat <<'EOF'
DOCKER_COMPOSE="/etc/opt/marzneshin/docker-compose.yml"
DB_PASS=\$(grep 'MARIADB_ROOT_PASSWORD:' "\$DOCKER_COMPOSE" | awk -F': ' '{print \$2}' | tr -d ' "')
DB_NAME=\$(grep 'MARIADB_DATABASE:' "\$DOCKER_COMPOSE" | awk -F': ' '{print \$2}' | tr -d ' "')
DB_USER="root"
if [ -n "\$DB_PASS" ] && [ -n "\$DB_NAME" ]; then
    mkdir -p "\$OUTPUT_DIR/Marzneshin-Mysql"
    mysqldump -h 127.0.0.1 -P 3306 -u "\$DB_USER" -p"\$DB_PASS" "\$DB_NAME" > "\$OUTPUT_DIR/Marzneshin-Mysql/marzneshin_backup.sql" 2>/dev/null && \
    echo "MariaDB backup created." || echo "MariaDB backup failed."
else
    echo "MariaDB credentials not found in docker-compose.yml"
fi
EOF
)
        ;;
    esac

    cat > "$TRANSFER_SCRIPT" <<EOF
#!/bin/bash
BACKUP_DIR="$BACKUP_DIR"
REMOTE_IP="$REMOTE_IP"
REMOTE_USER="$REMOTE_USER"
REMOTE_PASS="$REMOTE_PASS"
REMOTE_ETC="$REMOTE_ETC"
REMOTE_NODE="$REMOTE_NODE"
REMOTE_MARZ="$REMOTE_MARZ"
REMOTE_DB="$REMOTE_DB"
DB_ENABLED="$DB_ENABLED"
DB_DIR_NAME="$DB_DIR_NAME"
EOF

    cat >> "$TRANSFER_SCRIPT" <<'EOF'
echo "Starting transfer backup ($PANEL_NAME)..."
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "----------------------------------------"

DATE=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_DIR="${BACKUP_DIR}/backup_${DATE}"

mkdir -p "$OUTPUT_DIR"

echo "Copying local folders..."
cp -r /etc/opt/marzneshin/ "$OUTPUT_DIR/etc_opt/" 2>/dev/null
cp -r /var/lib/marznode/ "$OUTPUT_DIR/var_lib_marznode/" 2>/dev/null
rsync -a --exclude='mysql' /var/lib/marzneshin/ "$OUTPUT_DIR/var_lib_marzneshin/" 2>/dev/null

DOCKER_COMPOSE="/etc/opt/marzneshin/docker-compose.yml"
EOF
    printf '%s\n' "$DB_BACKUP_SCRIPT" >> "$TRANSFER_SCRIPT"
    cat >> "$TRANSFER_SCRIPT" <<'EOF'

echo "Installing sshpass if needed..."
command -v sshpass &>/dev/null || (apt update && apt install -y sshpass)

echo "Cleaning remote server..."
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@${REMOTE_IP}" "
    echo 'Removing old data...'
    rm -rf '$REMOTE_ETC' '$REMOTE_NODE' '$REMOTE_MARZ'
    mkdir -p '$REMOTE_ETC' '$REMOTE_NODE' '$REMOTE_MARZ'
    if [ "$DB_ENABLED" = "1" ]; then
        rm -rf '$REMOTE_DB'
        mkdir -p '$REMOTE_DB'
    fi
" || { echo "Failed to connect to remote server!"; exit 1; }

echo "Transferring data to $REMOTE_IP..."
sshpass -p "$REMOTE_PASS" rsync -a "$OUTPUT_DIR/etc_opt/" "$REMOTE_USER@${REMOTE_IP}:$REMOTE_ETC/" && echo "etc_opt transferred"
sshpass -p "$REMOTE_PASS" rsync -a "$OUTPUT_DIR/var_lib_marznode/" "$REMOTE_USER@${REMOTE_IP}:$REMOTE_NODE/" && echo "var_lib_marznode transferred"
sshpass -p "$REMOTE_PASS" rsync -a "$OUTPUT_DIR/var_lib_marzneshin/" "$REMOTE_USER@${REMOTE_IP}:$REMOTE_MARZ/" && echo "var_lib_marzneshin transferred"
if [ "$DB_ENABLED" = "1" ] && [ -d "$OUTPUT_DIR/$DB_DIR_NAME" ]; then
    sshpass -p "$REMOTE_PASS" rsync -a "$OUTPUT_DIR/$DB_DIR_NAME/" "$REMOTE_USER@${REMOTE_IP}:$REMOTE_DB/" && echo "Database transferred"
fi

echo "Restarting Marzneshin on remote..."
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@${REMOTE_IP}" "marzneshin restart" && echo "Restart successful" || echo "Restart failed"

echo "Cleaning local backup..."
rm -rf "$BACKUP_DIR"

echo "========================================"
echo "       TRANSFER COMPLETED!"
echo "       Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
EOF

  elif [[ "$PANEL_TYPE" == "Pasarguard" ]]; then
    PANEL_NAME="Pasarguard"
    BACKUP_DIR="/root/backuper_pasarguard"
    REMOTE_PAS="/opt/pasarguard"
    REMOTE_PG_NODE="/opt/pg-node"
    REMOTE_LIB_PAS="/var/lib/pasarguard"
    REMOTE_LIB_PG="/var/lib/pg-node"
    REMOTE_DB="/root/Pasarguard-DB"
    DB_ENABLED=0
    DB_DIR_NAME="Pasarguard-DB"

    MISSING_DIRS=()
    [[ ! -d "/opt/pasarguard" ]] && MISSING_DIRS+=("/opt/pasarguard")
    [[ ! -d "/opt/pg-node" ]] && MISSING_DIRS+=("/opt/pg-node")
    [[ ! -d "/var/lib/pasarguard" ]] && MISSING_DIRS+=("/var/lib/pasarguard")
    [[ ! -d "/var/lib/pg-node" ]] && MISSING_DIRS+=("/var/lib/pg-node")
    if [[ ${#MISSING_DIRS[@]} -gt 0 ]]; then
      banner "CRITICAL ERROR"
      echo -e "${RED}The following required directories are missing:${RESET}"
      for dir in "${MISSING_DIRS[@]}"; do echo -e "  ${RED}-${RESET} $dir"; done
      echo
      warn "Please install Pasarguard properly before transferring."
      pause
      return
    fi

    DB_TYPE=$(detect_db_type_pasarguard)
    case $DB_TYPE in
      sqlite)
        info "Database: SQLite (files included in copied folders)"
        DB_BACKUP_SCRIPT=""
        DB_ENABLED=0
        ;;
      mysql|mariadb)
        info "Database: MariaDB/MySQL"
        DB_ENABLED=1
        DB_BACKUP_SCRIPT=$(cat <<'EOF'
ENV_FILE="/opt/pasarguard/.env"
parse_db_url() {
    local url="\$1"
    url="\${url#*://}"
    local creds="\${url%%@*}"
    local hostdb="\${url#*@}"
    local user="\${creds%%:*}"
    local pass="\${creds#*:}"; pass="\${pass%%@*}"
    local hostport="\${hostdb%%/*}"
    local dbname="\${hostdb#*/}"
    local host="\${hostport%%:*}"
    local port="\${hostport##*:}"
    echo "\$user" "\$pass" "\$host" "\$port" "\$dbname"
}
if [ -f "\$ENV_FILE" ]; then
    DB_URL=\$(grep -E '^SQLALCHEMY_DATABASE_URL=' "\$ENV_FILE" | tail -n1 | cut -d'=' -f2- | tr -d "\\\"'" | xargs)
    if [ -n "\$DB_URL" ]; then
        read DB_USER DB_PASS DB_HOST DB_PORT DB_NAME < <(parse_db_url "\$DB_URL")
        : "\${DB_USER:=pasarguard}"
        : "\${DB_NAME:=pasarguard}"
        : "\${DB_PORT:=3306}"
        echo "Backing up MariaDB/MySQL database..."
        mkdir -p "\$OUTPUT_DIR/Pasarguard-DB"
        mysqldump -h "\$DB_HOST" -P "\$DB_PORT" -u "\$DB_USER" -p"\$DB_PASS" \\
            --single-transaction --routines --triggers --events --skip-lock-tables \\
            "\$DB_NAME" > "\$OUTPUT_DIR/Pasarguard-DB/pasarguard_backup.sql" 2>/dev/null && \\
            echo "MariaDB/MySQL backup created." || echo "MariaDB/MySQL backup failed."
    else
        echo "SQLALCHEMY_DATABASE_URL not found in .env"
    fi
else
    echo ".env not found for Pasarguard"
fi
EOF
)
        ;;
      postgresql)
        info "Database: PostgreSQL"
        DB_ENABLED=1
        DB_BACKUP_SCRIPT=$(cat <<'EOF'
ENV_FILE="/opt/pasarguard/.env"
parse_db_url() {
    local url="\$1"
    url="\${url#*://}"
    local creds="\${url%%@*}"
    local hostdb="\${url#*@}"
    local user="\${creds%%:*}"
    local pass="\${creds#*:}"; pass="\${pass%%@*}"
    local hostport="\${hostdb%%/*}"
    local dbname="\${hostdb#*/}"
    local host="\${hostport%%:*}"
    local port="\${hostport##*:}"
    echo "\$user" "\$pass" "\$host" "\$port" "\$dbname"
}
if [ -f "\$ENV_FILE" ]; then
    DB_URL=\$(grep -E '^SQLALCHEMY_DATABASE_URL=' "\$ENV_FILE" | tail -n1 | cut -d'=' -f2- | tr -d "\\\"'" | xargs)
    if [ -n "\$DB_URL" ]; then
        read DB_USER DB_PASS DB_HOST DB_PORT DB_NAME < <(parse_db_url "\$DB_URL")
        : "\${DB_USER:=pasarguard}"
        : "\${DB_NAME:=pasarguard}"
        : "\${DB_PORT:=5432}"
        echo "Backing up PostgreSQL database..."
        mkdir -p "\$OUTPUT_DIR/Pasarguard-DB"
        PGPASSWORD="\$DB_PASS" pg_dump -h "\$DB_HOST" -p "\$DB_PORT" -U "\$DB_USER" -F c "\$DB_NAME" > "\$OUTPUT_DIR/Pasarguard-DB/pasarguard_backup.dump" 2>/dev/null && \\
            echo "PostgreSQL backup created." || echo "PostgreSQL backup failed."
    else
        echo "SQLALCHEMY_DATABASE_URL not found in .env"
    fi
else
    echo ".env not found for Pasarguard"
fi
EOF
)
        ;;
      *)
        warn "Database: unknown/unsupported. Skipping DB dump."
        DB_BACKUP_SCRIPT=""
        DB_ENABLED=0
        ;;
    esac

    cat > "$TRANSFER_SCRIPT" <<EOF
#!/bin/bash
BACKUP_DIR="$BACKUP_DIR"
REMOTE_IP="$REMOTE_IP"
REMOTE_USER="$REMOTE_USER"
REMOTE_PASS="$REMOTE_PASS"
REMOTE_PAS="$REMOTE_PAS"
REMOTE_PG_NODE="$REMOTE_PG_NODE"
REMOTE_LIB_PAS="$REMOTE_LIB_PAS"
REMOTE_LIB_PG="$REMOTE_LIB_PG"
REMOTE_DB="$REMOTE_DB"
DB_ENABLED="$DB_ENABLED"
DB_DIR_NAME="$DB_DIR_NAME"
EOF

    cat >> "$TRANSFER_SCRIPT" <<'EOF'
echo "Starting transfer backup ($PANEL_NAME)..."
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "----------------------------------------"

DATE=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_DIR="${BACKUP_DIR}/backup_${DATE}"

mkdir -p "$OUTPUT_DIR"

echo "Copying local folders..."
rsync -a /opt/pasarguard/ "$OUTPUT_DIR/opt_pasarguard/" 2>/dev/null
rsync -a /opt/pg-node/ "$OUTPUT_DIR/opt_pg_node/" 2>/dev/null
rsync -a /var/lib/pasarguard/ "$OUTPUT_DIR/var_lib_pasarguard/" 2>/dev/null
rsync -a /var/lib/pg-node/ "$OUTPUT_DIR/var_lib_pg_node/" 2>/dev/null
EOF
    printf '%s\n' "$DB_BACKUP_SCRIPT" >> "$TRANSFER_SCRIPT"
    cat >> "$TRANSFER_SCRIPT" <<'EOF'

echo "Installing sshpass if needed..."
command -v sshpass &>/dev/null || (apt update && apt install -y sshpass)

echo "Cleaning remote server..."
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@${REMOTE_IP}" "
    echo 'Removing old data...'
    rm -rf '$REMOTE_PAS' '$REMOTE_PG_NODE' '$REMOTE_LIB_PAS' '$REMOTE_LIB_PG'
    mkdir -p '$REMOTE_PAS' '$REMOTE_PG_NODE' '$REMOTE_LIB_PAS' '$REMOTE_LIB_PG'
    if [ "$DB_ENABLED" = "1" ]; then
        rm -rf '$REMOTE_DB'
        mkdir -p '$REMOTE_DB'
    fi
" || { echo "Failed to connect to remote server!"; exit 1; }

echo "Transferring data to $REMOTE_IP..."
sshpass -p "$REMOTE_PASS" rsync -a "$OUTPUT_DIR/opt_pasarguard/" "$REMOTE_USER@${REMOTE_IP}:$REMOTE_PAS/" && echo "opt_pasarguard transferred"
sshpass -p "$REMOTE_PASS" rsync -a "$OUTPUT_DIR/opt_pg_node/" "$REMOTE_USER@${REMOTE_IP}:$REMOTE_PG_NODE/" && echo "opt_pg_node transferred"
sshpass -p "$REMOTE_PASS" rsync -a "$OUTPUT_DIR/var_lib_pasarguard/" "$REMOTE_USER@${REMOTE_IP}:$REMOTE_LIB_PAS/" && echo "var_lib_pasarguard transferred"
sshpass -p "$REMOTE_PASS" rsync -a "$OUTPUT_DIR/var_lib_pg_node/" "$REMOTE_USER@${REMOTE_IP}:$REMOTE_LIB_PG/" && echo "var_lib_pg_node transferred"
if [ "$DB_ENABLED" = "1" ] && [ -d "$OUTPUT_DIR/$DB_DIR_NAME" ]; then
    sshpass -p "$REMOTE_PASS" rsync -a "$OUTPUT_DIR/$DB_DIR_NAME/" "$REMOTE_USER@${REMOTE_IP}:$REMOTE_DB/" && echo "Database transferred"
fi

echo "Restarting Pasarguard on remote..."
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@${REMOTE_IP}" "pasarguard restart" && echo "Restart successful" || echo "Restart failed"

echo "Cleaning local backup..."
rm -rf "$BACKUP_DIR"

echo "========================================"
echo "       TRANSFER COMPLETED!"
echo "       Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
EOF

  elif [[ "$PANEL_TYPE" == "X-ui" ]]; then
    PANEL_NAME="X-ui"
    BACKUP_DIR="/root/backuper_X-ui"
    REMOTE_ETC="/etc/x-ui"
    REMOTE_CERT="/root/cert"

    MISSING_DIRS=()
    [[ ! -d "/etc/x-ui" ]] && MISSING_DIRS+=("/etc/x-ui")
    [[ ! -d "/root/cert/" ]] && MISSING_DIRS+=("/root/cert/")
    if [[ ${#MISSING_DIRS[@]} -gt 0 ]]; then
      banner "CRITICAL ERROR"
      echo -e "${RED}The following required directories are missing:${RESET}"
      for dir in "${MISSING_DIRS[@]}"; do echo -e "  ${RED}-${RESET} $dir"; done
      echo
      warn "Please install X-ui properly before transferring."
      pause
      return
    fi

    cat > "$TRANSFER_SCRIPT" <<EOF
#!/bin/bash
echo "Starting transfer backup ($PANEL_NAME)..."
echo "Date: \$(date '+%Y-%m-%d %H:%M:%S')"
echo "----------------------------------------"

BACKUP_DIR="$BACKUP_DIR"
REMOTE_IP="$REMOTE_IP"
REMOTE_USER="$REMOTE_USER"
REMOTE_PASS="$REMOTE_PASS"
REMOTE_ETC="$REMOTE_ETC"
REMOTE_CERT="$REMOTE_CERT"
INSTALL_XUI="$INSTALL_XUI"
XUI_VARIANT="$XUI_VARIANT"
DATE=\$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_DIR="\$BACKUP_DIR/backup_\$DATE"

mkdir -p "\$OUTPUT_DIR"

echo "Copying local folders..."
rsync -a /etc/x-ui/ "\$OUTPUT_DIR/etc_x-ui/" 2>/dev/null
cp -a /root/cert/. "\$OUTPUT_DIR/root_cert/" 2>/dev/null

echo "Installing sshpass if needed..."
command -v sshpass &>/dev/null || (apt update && apt install -y sshpass)

if [ "\$INSTALL_XUI" = "Y" ]; then
    echo "Installing X-ui on remote..."
    if [ "\$XUI_VARIANT" = "A" ]; then
        sshpass -p "\$REMOTE_PASS" ssh -o StrictHostKeyChecking=no "\$REMOTE_USER@\${REMOTE_IP}" "printf '\n' | bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)" && echo "Alireza X-ui installed" || echo "Install failed"
    else
        sshpass -p "\$REMOTE_PASS" ssh -o StrictHostKeyChecking=no "\$REMOTE_USER@\${REMOTE_IP}" "printf '\n' | bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)" && echo "Sanaei X-ui installed" || echo "Install failed"
    fi
fi

echo "Cleaning remote server..."
sshpass -p "\$REMOTE_PASS" ssh -o StrictHostKeyChecking=no "\$REMOTE_USER@\${REMOTE_IP}" "
    rm -rf '\$REMOTE_ETC' '\$REMOTE_CERT'
    mkdir -p '\$REMOTE_ETC' '\$REMOTE_CERT'
" || { echo "Failed to connect to remote server!"; exit 1; }

echo "Transferring data to \$REMOTE_IP..."
sshpass -p "\$REMOTE_PASS" rsync -a "\$OUTPUT_DIR/etc_x-ui/" "\$REMOTE_USER@\${REMOTE_IP}:\$REMOTE_ETC/" && echo "etc_x-ui transferred"
sshpass -p "\$REMOTE_PASS" rsync -a "\$OUTPUT_DIR/root_cert/" "\$REMOTE_USER@\${REMOTE_IP}:\$REMOTE_CERT/" && echo "root_cert transferred"

echo "Restarting X-ui on remote..."
sshpass -p "\$REMOTE_PASS" ssh -o StrictHostKeyChecking=no "\$REMOTE_USER@\${REMOTE_IP}" "x-ui restart" && echo "Restart successful" || echo "Restart failed"

echo "Cleaning local backup..."
rm -rf "\$BACKUP_DIR"

echo "========================================"
echo "       TRANSFER COMPLETED!"
echo "       Date: \$(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
EOF

  else
    warn "Invalid choice."
    pause
    return
  fi

  chmod +x "$TRANSFER_SCRIPT"
  info "Running transfer..."
  hr2
  bash "$TRANSFER_SCRIPT"
  rm -f "$TRANSFER_SCRIPT"
  trap - EXIT
  pause
}

# ==============================
# Main Menu (UI improved)
# ==============================
main_menu() {
  while true; do
    banner "Backuper Menu"
    menu_item 1 "Install Backuper"
    menu_item 2 "Remove Backuper"
    menu_item 3 "Run Script"
    menu_item 4 "Transfer Backup"
    menu_item 5 "Exit"
    echo
    hr2
    read -p "${ARROW} Choose an option: " OPTION

    case $OPTION in
      1) install_backuper ;;
      2) remove_backuper ;;
      3) run_script ;;
      4) transfer_backup ;;
      5) echo -e "${GREEN}Bye!${RESET}"; exit 0 ;;
      *) warn "Invalid choice!"; sleep 1 ;;
    esac
  done
}

# ==============================
# Start
# ==============================
install_requirements
main_menu
