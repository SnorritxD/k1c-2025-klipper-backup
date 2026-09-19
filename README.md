# Creality K1C (2025) Klipper GitHub Backup

An automated, non-destructive Git backup solution specifically designed for the Creality K1C (and other Creality OS / Klipper printers running BusyBox). Back up your complete Klipper configuration to GitHub with a single click from Fluidd or Mainsail.

## Disclaimer

THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.
The author and contributors are not responsible or liable for any damage, data loss, system instability, bricked hardware, or any other issues resulting from the use of this script or repository. Use this tool entirely at your own risk. Always maintain local copies of your critical configuration files before making changes.

## Features

- **Creality OS Architecture Ready:** Built specifically for the Buildroot / BusyBox environment with full persistence in `/usr/data/printer_data/config`.
- **BusyBox & awk Macro Insertion:** Automatically detects the Klipper `SAVE_CONFIG` block and inserts the backup macro safely above it without corrupting printer settings.
- **Entware & Permission Fixes:** Automatically sets up required environment variables (`HOME=/usr/data`, Entware PATHs, and `.git` permissions) to prevent background execution errors.
- **1-Click Macro:** Execute backups directly from your Web UI (Fluidd / Mainsail) via the `BACKUP_GITHUB` macro.
- **Clean Repository Management:** Automatically excludes temporary system files, database locks, and auto-generated timestamped backups (`printer-*.cfg`).
- **Interactive Installer:** Simple step-by-step installation script that prompts for your GitHub credentials and handles configuration automatically.

## Prerequisites

Before running the installer, ensure you have:
1. **Root Access & Helper Script:** Root access enabled on your K1C (2025 Revision) using the [Creality Helper Script 2025](https://github.com/C0DEbrained/Creality-Helper-Script-2025) with Entware support. This specific helper script environment is required for proper path structures and package management.
2. **gcode_shell_command:** Installed on your printer via the Creality Helper Script menu.
3. **GitHub Personal Access Token (PAT):** Generated on GitHub under `Settings` -> `Developer Settings` -> `Personal Access Tokens (Classic)` with the `repo` scope enabled.
4. **GitHub Repository:** An empty repository created on your GitHub account (e.g., `K1C-klipper-backup`).

## Quick Installation

Log in to your printer via SSH (`ssh root@<PRINTER_IP>`) and run the following commands:

```bash
cd /usr/data/printer_data/config
wget --no-check-certificate https://raw.githubusercontent.com/SnorritxD/k1c-2025-klipper-backup/main/install.sh -O /tmp/install.sh
sed -i 's/\r$//' /tmp/install.sh
sh /tmp/install.sh
rm /tmp/install.sh
```

The interactive script will prompt you for:
- GitHub Username
- GitHub Email Address
- Repository Name
- Personal Access Token (PAT)

## Clean up / Reinstall (Optional)

If you already have a previous installation or need to start completely fresh, run these commands first before installing:

```bash
cd /usr/data/printer_data/config
rm -rf .git git_backup.sh .gitignore
```

## How It Works

The setup configures three core components inside `/usr/data/printer_data/config`:

1. **`.gitignore`** — Filters out unnecessary logs and backup iterations (`.git/`, `*.bkp`, `*.log`, `database.sqlite*`, `printer-*.cfg`).
2. **`git_backup.sh`** — A shell script tailored for Creality OS that checks for file changes, commits them with a timestamp, and pushes to `main`.
3. **`printer.cfg` Macro Integration** — Adds the shell execution macro safely above the `SAVE_CONFIG` block.

## Usage

### Manual Backup via Fluidd / Mainsail
1. Open Fluidd or Mainsail.
2. Click the `BACKUP_GITHUB` button in the Macro panel (or enter `BACKUP_GITHUB` in the console).
3. Check the console output to confirm the push succeeded.

### Optional: Automatic Backup After Every Print
Add the `BACKUP_GITHUB` command to your existing `PRINT_END` macro in `gcode_macro.cfg` or `printer.cfg`:

[gcode_macro PRINT_END]
gcode:
    # ... your existing end gcode ...
    BACKUP_GITHUB

## License

MIT License. Free to use, modify, and distribute for the 3D printing community.
