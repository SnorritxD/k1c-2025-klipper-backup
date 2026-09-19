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
    echo "[!] Git not found. Installing via opkg..."
    opkg update
    opkg install git git-http
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: Failed to install Git. Please ensure Entware is enabled."
        exit 1
    fi
fi

read -p "GitHub Username: " GH_USER
read -p "GitHub Email Address: " GH_EMAIL
read -p "GitHub Repository Name: " GH_REPO
read -p "Personal Access Token PAT: " GH_TOKEN

if [ -z "$GH_USER" ] || [ -z "$GH_EMAIL" ] || [ -z "$GH_REPO" ] || [ -z "$GH_TOKEN" ]; then
    echo "Error: All fields are required."
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
    echo "Backup successfully pushed to GitHub!"
else
    echo "No changes to push or an error occurred while pushing."
    exit 1
fi
EOF

chmod +x git_backup.sh
sed -i 's/\r$//' git_backup.sh

echo "[3/5] Adding Klipper macro to printer.cfg..."
if [ -f "printer.cfg" ]; then
    if ! grep -q "BACKUP_GITHUB" printer.cfg; then
        MACRO_BLOCK='[gcode_macro BACKUP_GITHUB]
description: Backs up Klipper configuration to GitHub
gcode:
    RUN_SHELL_COMMAND CMD=git_backup_script

[gcode_shell_command git_backup_script]
command: sh /usr/data/printer_data/config/git_backup.sh
timeout: 30.0
verbose: True
'
        # Plaats de macro veilig bóven het SAVE_CONFIG blok met awk
        if grep -q "SAVE_CONFIG" printer.cfg; then
            awk -v block="$MACRO_BLOCK" '
                /#\*# <---------------------- SAVE_CONFIG ---------------------->/ { print block }
                { print }
            ' printer.cfg > printer.cfg.tmp && mv printer.cfg.tmp printer.cfg
            echo "Macro successfully inserted above SAVE_CONFIG in printer.cfg."
        else
            printf "\n%s\n" "$MACRO_BLOCK" >> printer.cfg
            echo "Macro successfully added to the end of printer.cfg."
        fi
    else
        echo "Macro is already present in printer.cfg."
    fi
else
    echo "Warning: printer.cfg not found. Please add the macro manually."
fi

echo "[4/5] Configuring Git repository..."
git config --global --add safe.directory /usr/data/printer_data/config
git config --global --add safe.directory '*'

if [ ! -d ".git" ]; then
    git init
fi

# Zorg dat de .git map vanaf begin volledig beschrijfbaar is voor Klipper/root
chmod -R 777 .git

git config user.name "$GH_USER"
git config user.email "$GH_EMAIL"
git remote remove origin 2>/dev/null
git remote add origin "https://${GH_USER}:${GH_TOKEN}@github.com/${GH_USER}/${GH_REPO}.git"
git branch -M main

echo "[5/5] Running initial backup and setting permissions..."
git -c safe.directory=/usr/data/printer_data/config add .
git -c safe.directory=/usr/data/printer_data/config commit -m "Initial Creality K1C auto-backup"

# Force push om eventuele lege remote / conflict bestanden probleemloos te overschrijven
git -c safe.directory=/usr/data/printer_data/config push -u origin main --force

# Definitief alle rechten openzetten voor de servicegebruiker
chmod -R 777 .git

echo ""
echo "=========================================="
echo " Installation completed successfully!"
echo " Note: Make sure 'gcode_shell_command' is installed."
echo " Restart Klipper/Fluidd/Mainsail to activate the macro."
echo "=========================================="
