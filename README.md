# Creality K1C (2025) Klipper GitHub Backup

An automated, non-destructive Git backup solution specifically designed for the Creality K1C (2025 Revision running Creality OS / Klipper). Back up your complete Klipper configuration to GitHub with a single click from Fluidd or Mainsail.

## Disclaimer

THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.
The author and contributors are not responsible or liable for any damage, data loss, system instability, bricked hardware, or any other issues resulting from the use of this script or repository. Use this tool entirely at your own risk. Always maintain local copies of your critical configuration files before making changes.

## Features

- 2025 K1C Architecture Ready: Built specifically for Creality OS / Buildroot environment with full persistence in /usr/data/printer_data/config.
- Entware & Permission Fixes: Automatically sets up required environment variables (HOME=/usr/data, Entware PATHs, and .git permissions) to prevent background execution errors in Klipper.
- 1-Click Macro: Execute backups directly from your Web UI (Fluidd / Mainsail) via the BACKUP_GITHUB macro.
- Clean Repository Management: Automatically excludes temporary system files, database locks, and auto-generated timestamped backups (printer-*.cfg).
- Interactive One-Line Installer: Simple installation script that prompts for your GitHub credentials and handles configuration automatically.

## Prerequisites

Before running the installer, ensure you have:
1. Root Access & Helper Script: Root access enabled on your K1C with Guilouz Helper Script / Entware support.
2. gcode_shell_command: Installed on your printer (via Creality Helper Script / KIAUH).
3. GitHub Personal Access Token (PAT): Generated on GitHub under Settings -> Developer Settings -> Personal Access Tokens (Classic) with repo scope enabled.
4. GitHub Repository: An empty repository created on your GitHub account (e.g., k1c-2025-klipper-backup).

## Quick Installation

Log in to your printer via SSH (ssh root@<PRINTER_IP>) and run the following command:

curl -sSL -O https://raw.githubusercontent.com/SnorritxD/k1c-2025-klipper-backup/main/install.sh && sh install.sh && rm install.sh

The interactive script will prompt you for:
- GitHub Username (e.g., SnorritxD)
- GitHub Email Address
- Repository Name (e.g., k1c-2025-klipper-backup)
- Personal Access Token (PAT)

## How It Works

The setup configures three core components inside /usr/data/printer_data/config:

1. .gitignore — Filters out unnecessary logs and backup iterations:
   .git/
   *.bkp
   *.log
   database.sqlite*
   .DS_Store
   printer-*.cfg

2. git_backup.sh — A shell script tailored for Creality OS that checks for file changes, commits them with a timestamp, and pushes to main:
   #!/bin/sh
   export PATH=/opt/bin:/opt/sbin:/usr/bin:/bin:$PATH
   export HOME=/usr/data

   cd /usr/data/printer_data/config || exit 1

   git config --global --add safe.directory /usr/data/printer_data/config 2>/dev/null

   if [ -n "$(git status --porcelain)" ]; then
       echo "Changes detected, uploading..."
       git add .
       git commit -m "Auto-backup: $(date +'%Y-%m-%d %H:%M:%S')"
       if git push origin main; then
           echo "Backup completed successfully!"
       else
           echo "Error during git push."
           exit 1
       fi
   else
       echo "No changes detected."
   fi

3. printer.cfg Macro Integration — Adds the shell execution macro to Klipper:
   [gcode_macro BACKUP_GITHUB]
   description: Backs up Klipper configuration to GitHub
   gcode:
       RUN_SHELL_COMMAND CMD=git_backup_script

   [gcode_shell_command git_backup_script]
   command: sh /usr/data/printer_data/config/git_backup.sh
   timeout: 30.0
   verbose: True

## Usage

### Manual Backup via Fluidd / Mainsail
1. Open Fluidd or Mainsail.
2. Click the BACKUP_GITHUB button in the Macro panel (or enter BACKUP_GITHUB in the console).
3. Check the console output to confirm the push succeeded.

### Optional: Automatic Backup After Every Print
Add the BACKUP_GITHUB command to your existing PRINT_END macro in gcode_macro.cfg or printer.cfg:

[gcode_macro PRINT_END]
gcode:
    # ... your existing end gcode ...
    BACKUP_GITHUB

## License

MIT License. Free to use, modify, and distribute for the 3D printing community.
