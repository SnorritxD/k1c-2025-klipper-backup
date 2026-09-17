#!/bin/sh

CONFIG_DIR="/usr/data/printer_data/config"

if [ ! -d "$CONFIG_DIR" ]; then
    echo "Error: Configuration directory $CONFIG_DIR not found!"
    exit 1
fi

cd "$CONFIG_DIR" || exit 1

echo "=========================================="
echo " Creality K1C (2025) GitHub Backup Installer"
echo "=========================================="
echo ""

# Prompt for user input
read -p "GitHub Username: " GH_USER
read -p "GitHub Email Address: " GH_EMAIL
read -p "GitHub Repository Name: " GH_REPO
read -p "Personal Access Token (PAT): " GH_TOKEN

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
cd /usr/data/printer_data/config

if [ -n "$(git status --porcelain)" ]; then
    echo "Changes detected, uploading..."
    git add .
    git commit -m "Auto-backup: $(date +'%Y-%m-%d %H:%M:%S')"
    git push origin main
    echo "Backup completed successfully!"
else
    echo "No changes detected."
fi
EOF

chmod +x git_backup.sh

echo "[3/5] Adding Klipper macro to printer.cfg..."
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
    echo "Macro added successfully."
else
    echo "Macro is already present in printer.cfg."
fi

echo "[4/5] Configuring Git..."
git init
git config user.name "$GH_USER"
git config user.email "$GH_EMAIL"
git remote remove origin 2>/dev/null
git remote add origin "https://${GH_USER}:${GH_TOKEN}@github.com/${GH_USER}/${GH_REPO}.git"
git branch -M main

echo "[5/5] Running initial backup..."
git add .
git commit -m "Initial Creality K1C (2025) auto-backup"
git push -u origin main

echo ""
echo "=========================================="
echo " Installation completed!"
echo " Restart Klipper/Fluidd to activate the macro."
echo "=========================================="
