#!/usr/bin/env bash
# =============================================================================
# ELDOAR – Electronic Document Archive
# =============================================================================
#
# Ein Script für alles:
#
#   Auf dem Proxmox-HOST ausführen (erstellt LXC-Container + installiert):
#     bash -c "$(wget -qLO - https://raw.githubusercontent.com/jalbersdorfer/postarchiv/master/lxc/eldoar.sh)"
#
#   Im LXC-Container ausführen (Update):
#     bash /opt/eldoar.sh
#
# Das Script erkennt automatisch die Umgebung:
#   /etc/pve/ vorhanden             →  Proxmox-Host  →  CT erstellen + installieren
#   Kein /etc/pve, /app/.git vorhanden  →  im CT, bereits installiert  →  Update
#   Kein /etc/pve, kein /app/.git       →  im CT, frisch              →  Vollinstallation
# =============================================================================

set -euo pipefail

# ERR-Trap: zeigt Zeile + Exit-Code bei unerwarteten Fehlern
trap 'echo -e "\n\033[01;31m[✗] Script failed at line ${LINENO} (exit code $?)\033[m" >&2' ERR

# --- Visuals (tteck-Style) ----------------------------------------------------
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"
INFO="${YW}ℹ${CL}"

msg_info()  { local MSG="$1"; echo -ne " ${INFO} ${YW}${MSG}${CL}..."; }
msg_ok()    { local MSG="$1"; echo -e "\r ${CM} ${GN}${MSG}${CL}  "; }
msg_error() { local MSG="$1"; echo -e "\r ${CROSS} ${RD}${MSG}${CL}"; exit 1; }

header_info() {
  clear
  cat <<'EOF'
    ______ __    ____  ____  ___    ____
   / ____// /   / __ \/ __ \/   |  / __ \
  / __/  / /   / / / / / / / /| | / /_/ /
 / /___ / /___/ /_/ / /_/ / ___ |/ _, _/
/_____//_____/_____/\____/_/  |_/_/ |_|

 Electronic Document Archive
EOF
  echo -e "  ${BL}Proxmox LXC Installer${CL}\n"
}

[[ $EUID -ne 0 ]] && { echo -e "${CROSS} Run as root"; exit 1; }

# =============================================================================
# MODUS-ERKENNUNG
# pct liegt je nach Proxmox-Version unter /usr/sbin/ oder /usr/bin/.
# /etc/pve/ existiert ausschließlich auf Proxmox-VE-Nodes → sicherste Prüfung.
# =============================================================================
if [[ -d /etc/pve ]] || command -v pct &>/dev/null; then
  MODE="host"
elif [[ -d /app/.git ]]; then
  MODE="update"
else
  MODE="install"
fi

# =============================================================================
# HOST-MODUS – läuft auf dem Proxmox-Host
# =============================================================================
if [[ "$MODE" == "host" ]]; then
  header_info

  # Defaults
  CTID=$(pvesh get /cluster/nextid)
  HOSTNAME="eldoar"
  CORES=2
  RAM=2048
  DISK=8
  STORAGE=$(pvesm status -content rootdir | awk 'NR>1 {print $1; exit}')
  BRIDGE="vmbr0"
  TEMPLATE_STORAGE=$(pvesm status -content vztmpl | awk 'NR>1 {print $1; exit}')
  TEMPLATE_NAME="debian-12-standard"
  # Zufälliges Root-Passwort generieren (16 Zeichen, alphanumerisch)
  # Subshell mit pipefail deaktiviert – tr+head erzeugt SIGPIPE, das sonst
  # mit set -o pipefail einen sofortigen Exit auslöst.
  ROOT_PASSWORD=$(set +o pipefail; tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)

  echo -e "  ${YW}Default settings:${CL}"
  echo -e "   CT-ID   : ${BL}${CTID}${CL}"
  echo -e "   Hostname: ${BL}${HOSTNAME}${CL}"
  echo -e "   Cores   : ${BL}${CORES}${CL}"
  echo -e "   RAM     : ${BL}${RAM} MB${CL}"
  echo -e "   Disk    : ${BL}${DISK} GB${CL} (${BL}${STORAGE}${CL})"
  echo -e "   Bridge  : ${BL}${BRIDGE}${CL}"
  echo ""

  read -rp "  Use default settings? [Y/n]: " DEFAULTS
  if [[ "${DEFAULTS,,}" == "n" ]]; then
    read -rp "  CT-ID    [${CTID}]: "    IN; [[ -n "$IN" ]] && CTID="$IN"
    read -rp "  Hostname [${HOSTNAME}]: " IN; [[ -n "$IN" ]] && HOSTNAME="$IN"
    read -rp "  Cores    [${CORES}]: "   IN; [[ -n "$IN" ]] && CORES="$IN"
    read -rp "  RAM (MB) [${RAM}]: "     IN; [[ -n "$IN" ]] && RAM="$IN"
    read -rp "  Disk (GB)[${DISK}]: "    IN; [[ -n "$IN" ]] && DISK="$IN"
    read -rp "  Storage  [${STORAGE}]: " IN; [[ -n "$IN" ]] && STORAGE="$IN"
    read -rp "  Bridge   [${BRIDGE}]: "  IN; [[ -n "$IN" ]] && BRIDGE="$IN"
    read -rp "  Root PW  [${ROOT_PASSWORD}]: " IN; [[ -n "$IN" ]] && ROOT_PASSWORD="$IN"
  fi
  echo ""

  # Template suchen oder herunterladen
  msg_info "Looking for Debian 12 template"
  TEMPLATE_PATH=$(pvesm list "$TEMPLATE_STORAGE" --content vztmpl 2>/dev/null \
    | awk "/$TEMPLATE_NAME/"' {print $1; exit}')

  if [[ -z "$TEMPLATE_PATH" ]]; then
    msg_ok "Template not found locally – downloading"
    msg_info "Downloading Debian 12 template"
    pveam update >/dev/null
    AVAIL=$(pveam available --section system | awk "/$TEMPLATE_NAME/"' {print $2; exit}')
    [[ -z "$AVAIL" ]] && msg_error "Debian 12 template not found in pveam"
    pveam download "$TEMPLATE_STORAGE" "$AVAIL" >/dev/null
    TEMPLATE_PATH="${TEMPLATE_STORAGE}:vztmpl/${AVAIL}"
  fi
  msg_ok "Template ready: ${TEMPLATE_PATH##*/}"

  # Container erstellen
  msg_info "Creating LXC container ${CTID}"
  pct create "$CTID" "$TEMPLATE_PATH" \
    --hostname   "$HOSTNAME" \
    --cores      "$CORES" \
    --memory     "$RAM" \
    --rootfs     "${STORAGE}:${DISK}" \
    --net0       "name=eth0,bridge=${BRIDGE},ip=dhcp,firewall=1" \
    --onboot     1 \
    --unprivileged 1 \
    --features   "nesting=1" \
    --start      1 \
    >/dev/null
  msg_ok "LXC container ${CTID} created and started"

  # Root-Passwort setzen
  msg_info "Setting root password"
  pct exec "$CTID" -- bash -c "echo 'root:${ROOT_PASSWORD}' | chpasswd"
  msg_ok "Root password set"

  # Warten bis Netzwerk bereit
  msg_info "Waiting for container network"
  for i in $(seq 1 30); do
    IP=$(pct exec "$CTID" -- hostname -I 2>/dev/null | awk '{print $1}') && [[ -n "$IP" ]] && break
    sleep 2
  done
  [[ -z "${IP:-}" ]] && msg_error "Container has no IP after 60s"
  msg_ok "Container IP: ${IP}"

  # Script in den CT kopieren und ausführen
  # $0 ist eine echte Datei wenn lokal ausgeführt; bei wget-Pipe muss neu geladen werden
  SCRIPT_SRC="$0"
  if [[ ! -f "$SCRIPT_SRC" ]]; then
    msg_info "Re-downloading script (was piped via wget)"
    SCRIPT_SRC="/tmp/eldoar.sh"
    wget -qO "$SCRIPT_SRC" \
      "https://raw.githubusercontent.com/jalbersdorfer/postarchiv/master/lxc/eldoar.sh"
    msg_ok "Script downloaded"
  fi
  msg_info "Copying script into container"
  pct push "$CTID" "$SCRIPT_SRC" /opt/eldoar.sh
  pct exec "$CTID" -- chmod +x /opt/eldoar.sh
  msg_ok "Script ready at /opt/eldoar.sh"

  echo ""
  echo -e " ${YW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
  echo -e " ${BL}▶ Ausgabe ab hier kommt aus dem Container (CT ${CTID})${CL}"
  echo -e " ${YW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
  echo ""

  pct exec "$CTID" -- bash /opt/eldoar.sh

  echo ""
  echo -e " ${YW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
  echo -e " ${BL}◀ Ende Container-Ausgabe${CL}"
  echo -e " ${YW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
  echo ""
  echo -e " ${CM} ${GN}ELDOAR erfolgreich installiert in CT ${CTID}${CL}"
  echo ""
  echo -e "   ${BL}Web interface${CL} : http://${IP}:3000"
  echo -e "   ${BL}Admin panel${CL}   : http://${IP}:3000/admin"
  echo -e "   ${BL}Upload${CL}        : http://${IP}:3000/upload"
  echo ""
  echo -e "   ${YW}Container-Login (z.B. via Proxmox Console oder SSH):${CL}"
  echo -e "   ${BL}Benutzer  :${CL} root"
  echo -e "   ${BL}Passwort  :${CL} ${GN}${ROOT_PASSWORD}${CL}"
  echo -e "   ${BL}SSH       :${CL} ssh root@${IP}"
  echo ""
  echo -e "   ${BL}Data directory${CL}: /app/data/files"
  echo -e "   ${BL}Env config${CL}    : /etc/eldoar.env"
  echo ""
  echo -e "   ${YW}Für Updates später im CT ausführen:${CL}"
  echo -e "   ${BL}bash /opt/eldoar.sh${CL}"
  echo -e "   ${YW}oder vom Host:${CL}"
  echo -e "   ${BL}pct exec ${CTID} -- bash /opt/eldoar.sh${CL}"
  echo ""
  exit 0
fi

# =============================================================================
# UPDATE-MODUS – ELDOAR bereits installiert
# =============================================================================
if [[ "$MODE" == "update" ]]; then
  header_info
  echo -e " ${YW}Existing installation detected – running update${CL}\n"

  msg_info "Pulling latest code"
  git -C /app pull --quiet
  msg_ok "Code updated ($(git -C /app log -1 --format='%h %s'))"

  msg_info "Updating Perl modules"
  cd /app
  cpanm --notest --quiet --installdeps . 2>/dev/null
  msg_ok "Perl modules up to date"

  msg_info "Restarting services"
  systemctl restart manticore
  systemctl restart eldoar
  msg_ok "Services restarted"

  echo ""
  echo -e " ${CM} ${GN}ELDOAR updated successfully${CL}"
  IP=$(hostname -I | awk '{print $1}')
  echo -e "   ${BL}Web interface${CL} : http://${IP}:3000"
  echo ""
  exit 0
fi

# =============================================================================
# INSTALL-MODUS – frischer Container
# =============================================================================
header_info
echo -e " ${YW}Fresh container detected – running full installation${CL}\n"

APP_DIR="/app"
APP_REPO="https://github.com/jalbersdorfer/postarchiv.git"

# Locale-Warnungen im frischen Container unterdrücken
export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

msg_info "Updating system packages"
apt-get update -qq >/dev/null 2>&1
apt-get upgrade -y -qq >/dev/null 2>&1
msg_ok "System packages updated"

msg_info "Installing build dependencies"
apt-get install -y --no-install-recommends \
  build-essential \
  libmariadb-dev \
  libmariadb3 \
  libdbi-perl \
  libdbd-mysql-perl \
  libtemplate-perl \
  perl \
  cpanminus \
  git \
  curl \
  wget \
  gnupg \
  ca-certificates \
  default-mysql-client \
  openssh-server \
  >/dev/null 2>&1
msg_ok "Installed build dependencies"

msg_info "Configuring SSH (root login + password auth)"
sed -i 's/#\?PermitRootLogin.*/PermitRootLogin yes/'       /etc/ssh/sshd_config
sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl enable -q ssh
systemctl start ssh
msg_ok "SSH configured and started"

msg_info "Configuring console auto-login"
# Proxmox LXC GUI Console nutzt container-getty@1 (nicht @tty1, nicht console-getty)
# tty%I wird von systemd zu tty1 expandiert wenn der Service @1 heißt
GETTY_OVERRIDE="/etc/systemd/system/container-getty@1.service.d/override.conf"
mkdir -p "$(dirname "$GETTY_OVERRIDE")"
cat >"$GETTY_OVERRIDE" <<'AUTOLOGIN'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear --keep-baud tty%I 115200,38400,9600 $TERM
AUTOLOGIN
systemctl daemon-reload
systemctl restart container-getty@1 2>/dev/null || true
msg_ok "Console auto-login configured"

msg_info "Installing PDF, OCR & image tools"
apt-get install -y --no-install-recommends \
  poppler-utils \
  ocrmypdf \
  unpaper \
  tesseract-ocr \
  tesseract-ocr-deu \
  img2pdf \
  imagemagick \
  ghostscript \
  incron \
  >/dev/null 2>&1
msg_ok "Installed PDF, OCR & image tools"

msg_info "Fixing ImageMagick PDF policy"
POLICY_FILE="/etc/ImageMagick-6/policy.xml"
if [[ -f "$POLICY_FILE" ]]; then
  sed -i '/disable ghostscript format types/,+6d' "$POLICY_FILE"
  msg_ok "ImageMagick PDF policy fixed"
else
  echo -e "\r ${INFO} ${YW}policy.xml not found – skip${CL}  "
fi

msg_info "Adding Manticore Search repository"
# Manticore stellt ein .deb-Paket bereit das das Repo korrekt einrichtet
wget -qO /tmp/manticore-repo.deb https://repo.manticoresearch.com/manticore-repo.noarch.deb
dpkg -i /tmp/manticore-repo.deb >/dev/null 2>&1
apt-get update -qq >/dev/null 2>&1
msg_ok "Manticore Search repository added"

msg_info "Installing Manticore Search"
apt-get install -y manticore manticore-extra >/dev/null 2>&1
msg_ok "Installed Manticore Search"

msg_info "Configuring Manticore Search"
mkdir -p /var/lib/manticore /var/log/manticore /run/manticore
chown -R manticore:manticore \
  /var/lib/manticore /var/log/manticore /run/manticore 2>/dev/null || true
cat >/etc/manticoresearch/manticore.conf <<'MANTICORE_CONF'
table testrt {
  type              = rt
  rt_mem_limit      = 128M
  path              = /var/lib/manticore/testrt

  rt_field          = content
  rt_field          = tags
  rt_attr_uint      = gid
  rt_attr_string    = title
  rt_attr_timestamp = doc_timestamp

  expand_keywords   = 1
}

table doc_tags {
  type              = rt
  rt_mem_limit      = 128M
  path              = /var/lib/manticore/doc_tags

  rt_field          = dummy

  rt_attr_bigint    = doc_id
  rt_attr_string    = tag
  rt_attr_timestamp = set_at
  rt_attr_timestamp = removed_at
}

searchd {
  listen          = 9312
  listen          = 9306:mysql
  listen          = 9308:http

  pid_file        = /run/manticore/searchd.pid
  log             = /var/log/manticore/searchd.log
  query_log       = /var/log/manticore/query.log

  network_timeout = 5
  seamless_rotate = 1
  preopen_tables  = 1
  unlink_old      = 1
}
MANTICORE_CONF
msg_ok "Configured Manticore Search"

msg_info "Cloning ELDOAR application"
git clone --quiet "$APP_REPO" "$APP_DIR"
msg_ok "ELDOAR cloned to ${APP_DIR}"

msg_info "Installing Perl modules (Dancer2 + dependencies via CPAN)"
cd "$APP_DIR"
# DBI, DBD::mysql 4.050 und Template kommen bereits via apt → cpanm überspringt sie
cpanm --notest --quiet --installdeps . 2>/dev/null
find /usr/local/lib/perl5 -type d \( -name '.git' -o -name 't' -o -name 'examples' \) \
  -exec rm -rf {} + 2>/dev/null || true
find /usr/local/lib/perl5 -name '*.bs' -delete 2>/dev/null || true
msg_ok "Perl modules installed"

msg_info "Setting up application directories"
mkdir -p "${APP_DIR}/data/files" "${APP_DIR}/public" "${APP_DIR}/import"
[[ ! -L "${APP_DIR}/public/data" ]] && ln -s "${APP_DIR}/data" "${APP_DIR}/public/data"
chmod +x "${APP_DIR}"/*.sh 2>/dev/null || true
chmod +x "${APP_DIR}"/*.pl 2>/dev/null || true
msg_ok "Application directories ready"

msg_info "Writing environment config"
cat >/etc/eldoar.env <<'EOF'
SPHINX_HOST=127.0.0.1
SPHINX_PORT=9306
OVERVIEW_LIMIT=18
OVERVIEW_ORDER=DESC
ELDOAR_HOME=/app
EOF
msg_ok "Environment config written (/etc/eldoar.env)"

msg_info "Creating ELDOAR systemd service"
cat >/etc/systemd/system/eldoar.service <<'EOF'
[Unit]
Description=ELDOAR Electronic Document Archive
Documentation=https://github.com/jalbersdorfer/postarchiv
After=network.target manticore.service
Requires=manticore.service

[Service]
Type=simple
WorkingDirectory=/app
EnvironmentFile=/etc/eldoar.env
ExecStartPre=/bin/bash -c 'for i in $(seq 1 30); do \
  mysql -h 127.0.0.1 -P 9306 -e "SELECT 1" >/dev/null 2>&1 && break || sleep 1; done'
ExecStart=/usr/bin/perl /app/dancerApp.pl
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=eldoar

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
msg_ok "ELDOAR systemd service created"


msg_info "Starting Manticore Search"
systemctl enable -q manticore
systemctl start manticore
for i in $(seq 1 30); do
  mysql -h 127.0.0.1 -P 9306 -e "SELECT 1" >/dev/null 2>&1 && break || sleep 1
done
msg_ok "Manticore Search started"

msg_info "Starting ELDOAR"
systemctl enable -q eldoar
systemctl start eldoar
msg_ok "ELDOAR started"

msg_info "Cleaning up"
apt-get clean >/dev/null 2>&1
rm -rf /var/lib/apt/lists/* /tmp/* 2>/dev/null || true
msg_ok "Cleanup done"

IP=$(hostname -I | awk '{print $1}')
echo ""
echo -e " ${YW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
echo -e " ${CM} ${GN}ELDOAR installed successfully${CL}"
echo -e " ${YW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
echo ""
echo -e "   ${BL}Web interface${CL} : http://${IP}:3000"
echo -e "   ${BL}Admin panel${CL}   : http://${IP}:3000/admin"
echo -e "   ${BL}Upload${CL}        : http://${IP}:3000/upload"
echo ""
echo -e "   ${BL}Logs${CL}          : journalctl -u eldoar -f"
echo -e "   ${BL}Status${CL}        : systemctl status eldoar manticore"
echo -e "   ${BL}Env config${CL}    : /etc/eldoar.env"
echo -e "   ${BL}Data${CL}          : /app/data/files"
echo ""
echo -e "   ${YW}Tipp – Proxmox Bind Mount für persistente Daten:${CL}"
echo -e "   ${BL}Datacenter → CT → Resources → Add → Bind Mount${CL}"
echo -e "   Host-Pfad: /mnt/dein-storage/eldoar  →  CT-Pfad: /app/data/files"
echo ""
echo -e "   ${YW}Für zukünftige Updates:${CL}"
echo -e "   ${BL}bash /opt/eldoar.sh${CL}"
echo ""
