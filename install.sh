#!/bin/sh

CONFIG_DIR="/usr/data/printer_data/config"

if [ ! -d "$CONFIG_DIR" ]; then
    echo "Error: Configuration directory $CONFIG_DIR not found!"
    exit 1
fi

cd "$CONFIG_DIR" || exit 1

export PATH=/opt/bin:/opt/sbin:/usr/bin:/bin:$PATH
export HOME=/usr/data

echo "=========================================="
echo " Creality K1C GitHub Backup Installer"
echo "=========================================="
echo ""

if ! command -v git >/dev/null 2>&1; then
    echo "[!] Git niet gevonden. Bezig met installeren via opkg..."
    opkg update
    opkg install git git-http
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: Git kon niet worden geinstalleerd. Zorg dat Entware actief is."
        exit 1
    fi
fi

read -p "GitHub Username: " GH_USER
read -p "GitHub Email Address: " GH_EMAIL
read -p "GitHub Repository Name: " GH_REPO
read -p "Personal Access Token PAT: " GH_TOKEN

if [ -z "$GH_USER" ] || [ -z "$GH_EMAIL" ] || [ -z "$GH_REPO" ] || [ -z "$GH_TOKEN" ]; then
    echo "Error: Alle velden zijn verplicht."
    exit 1
fi

echo ""
echo "[1/5] Creating .gitignore..."
cat << 'EOF' > .gitignore
.git/
*.bkp
*.log
database.sqlite*
.DS_Store
printer-*.cfg
EOF

echo "[2/5] Creating backup script..."
cat << 'EOF' > git_backup.sh
#!/bin/sh
export PATH=/opt/bin:/opt/sbin:/usr/bin:/bin:$PATH
export HOME=/usr/data

cd /usr/data/printer_data/config || exit 1

git -c safe.directory=/usr/data/printer_data/config add .
git -c safe.directory=/usr/data/printer_data/config commit -m "Klipper backup $(date +'%Y-%m-%d %H:%M:%S')"

if git -c safe.directory=/usr/data/printer_data/config push origin main; then
    echo "Backup succesvol gepusht naar GitHub!"
else
    echo "Geen wijzigingen om te pushen of fout bij versturen."
    exit 1
fi
EOF

chmod +x git_backup.sh
sed -i 's/\r$//' git_backup.sh

echo "[3/5] Adding Klipper macro to printer.cfg..."
if [ -f "printer.cfg" ]; then
    if ! grep -q "BACKUP_GITHUB" printer.cfg; then
        cat << 'EOF' >> printer.cfg

[gcode_macro BACKUP_GITHUB]
description: Backs up Klipper configuration to GitHub
gcode:
    RUN_SHELL_COMMAND CMD=git_backup_script

[gcode_shell_command git_backup_script]
command: sh /usr/data/printer_data/config/git_backup.sh
timeout: 30.0
verbose: True
EOF
        echo "Macro succesvol toegevoegd aan printer.cfg."
    else
        echo "Macro is al aanwezig in printer.cfg."
    fi
else
    echo "Waarschuwing: printer.cfg niet gevonden. Voeg de macro handmatig toe."
fi

echo "[4/5] Configuring Git repository..."
git config --global --add safe.directory /usr/data/printer_data/config
git config --global --add safe.directory '*'

if [ ! -d ".git" ]; then
    git init
fi

git config user.name "$GH_USER"
git config user.email "$GH_EMAIL"
git remote remove origin 2>/dev/null
git remote add origin "https://${GH_USER}:${GH_TOKEN}@github.com/${GH_USER}/${GH_REPO}.git"
git branch -M main

echo "[5/5] Running initial backup and setting permissions..."
git -c safe.directory=/usr/data/printer_data/config add .
git -c safe.directory=/usr/data/printer_data/config commit -m "Initial Creality K1C auto-backup"
git -c safe.directory=/usr/data/printer_data/config push -u origin main

chmod -R 777 .git

echo ""
echo "=========================================="
echo " Installatie succesvol afgerond!"
echo " Let op: Zorg dat gcode_shell_command geinstalleerd is."
echo " Herstart Klipper/Fluidd/Mainsail om de macro te activeren."
echo "=========================================="
