 <div align="center">

# 🖨️ Creality K1C (2025) Klipper GitHub Backup

**Back up your Klipper configuration to your own GitHub repository.**

One-click backups from Fluidd or Mainsail · Git version history · Creality OS support

![Platform](https://img.shields.io/badge/Platform-Creality%20K1C%202025-blue)
![Firmware](https://img.shields.io/badge/Firmware-Klipper-orange)
![Backup](https://img.shields.io/badge/Backup-GitHub-black?logo=github)
![Shell](https://img.shields.io/badge/Shell-BusyBox%20compatible-lightgrey)

</div>

---

## ✨ Features

* ☁️ **GitHub backups:** Push eligible Klipper configuration files to your own GitHub repository.
* 🕒 **Version history:** Record configuration changes in Git commits with timestamps.
* 🖲️ **One-click backup:** Run the `BACKUP_GITHUB` macro from Fluidd or Mainsail.
* 🔧 **Entware integration:** Attempts to install Git through `opkg` if Git is not available.
* 📁 **Persistent storage:** Uses `/usr/data/printer_data/config` for the Git repository and backup script.
* 🧹 **File exclusions:** Creates a `.gitignore` for selected logs, database files, backup files, and other generated files.
* ⚙️ **Interactive setup:** Prompts for your GitHub username, email, repository name, and Personal Access Token.

## 🎯 Compatibility and prerequisites

Designed for a rooted **Creality K1C (2025 model)** running Creality OS and Klipper, with configuration files stored at:

`/usr/data/printer_data/config`

Before installation, make sure you have:

1. **Root SSH access** to your printer.
2. **Entware support** if Git needs to be installed through `opkg`.
3. **The `gcode_shell_command` extension** installed and configured so Klipper can execute the backup script through the macro.
4. **A GitHub repository** for your backups. An empty repository is strongly recommended.
5. **A GitHub Personal Access Token (PAT)** with the permissions required to push to your repository.

The installer does not install `gcode_shell_command` for you.

## 🚀 Quick installation

Connect to your printer over SSH as `root`:

```sh
cd /usr/data/printer_data/config

wget --no-check-certificate \
  https://raw.githubusercontent.com/SnorritxD/k1c-2025-klipper-backup/main/install.sh \
  -O /tmp/install.sh

sed -i 's/\r$//' /tmp/install.sh

sh /tmp/install.sh

rm -f /tmp/install.sh
```

The installer prompts you for:

* GitHub username
* GitHub email address
* Repository name
* Personal Access Token (PAT)

It then configures Git, creates `git_backup.sh`, writes `.gitignore`, attempts to add the macro to `printer.cfg`, and attempts an initial push to GitHub.

> **Important:** The initial push uses `git push --force`. If the remote `main` branch already contains files or commits, its existing history may be overwritten. Use a dedicated, empty repository unless you intentionally want to replace the remote branch.

## ⚙️ How it works

The installer configures the following files under `/usr/data/printer_data/config`:

| File            | Purpose                                                                                                         |
| --------------- | --------------------------------------------------------------------------------------------------------------- |
| `.gitignore`    | Excludes selected file patterns from Git staging.                                                               |
| `git_backup.sh` | Stages eligible changes, attempts a timestamped commit, and pushes `main` to GitHub.                            |
| `printer.cfg`   | Receives the `BACKUP_GITHUB` macro if the installer finds the file and does not find the macro already present. |
| `.git/`         | Stores the local Git repository, history, settings, and remote configuration.                                   |

### 🧹 Files excluded from Git

The installer creates this `.gitignore`:

```gitignore
.git/
*.bkp
*.log
database.sqlite*
.DS_Store
printer-*.cfg
```

These patterns exclude matching files from ordinary Git staging when they are not already tracked. They do not automatically remove files that Git is already tracking.

## 🖲️ Usage

### Manual backup from Fluidd or Mainsail

1. Open Fluidd or Mainsail.
2. Find the `BACKUP_GITHUB` macro in the macro panel.
3. Run the macro.
4. Check the console output and the backup log or GitHub repository to confirm the result.

You can also enter this command in the Klipper console:

```text
BACKUP_GITHUB
```

The macro invokes:

`/usr/data/printer_data/config/git_backup.sh`

The backup script stages eligible changes, attempts to create a commit with a timestamp, and pushes the `main` branch to GitHub. A failed push results in an error message.

## ⏱️ Optional: Back up after every print

You can add `BACKUP_GITHUB` to your existing `PRINT_END` macro.

For example, add the command at an appropriate point in your existing macro:

```ini
# Add this command inside your existing PRINT_END gcode:
BACKUP_GITHUB
```

Do not create a second `[gcode_macro PRINT_END]` section if one already exists. Make a local copy of your configuration before editing it.

## 🔄 Optional: Back up after Klipper starts

If you want to trigger a backup after Klipper starts, you can add this optional delayed G-code configuration:

```ini
[delayed_gcode backup_on_startup]
initial_duration: 10.0
gcode:
    BACKUP_GITHUB
```

This is an optional manual configuration, not something the installer adds automatically. It triggers after Klipper initializes the delayed G-code, not necessarily immediately after the printer receives power. Network availability and GitHub connectivity can affect whether the backup succeeds.

## 🔐 Security

**Protect your GitHub Personal Access Token.**

The installer configures the Git remote using an HTTPS URL containing the supplied token. Git can store this URL in the local repository configuration, making the token accessible to users who can read that configuration.

* Use a dedicated token with only the permissions required for the backup repository.
* Never share your token in screenshots, logs, or public documentation.
* Restrict access to the printer and its configuration directory.
* Revoke and replace the token if it is exposed.
* Use a dedicated backup repository to avoid accidentally overwriting unrelated files or history.

The installer also runs `chmod -R 777 .git`, granting all local users read, write, and execute permissions on the Git metadata directory. This is permissive and has security implications on systems with multiple users.

## ⚠️ Important limitations

* The installer requires `/usr/data/printer_data/config` to exist.
* Git installation through Entware is attempted only when Git is missing.
* The installer does not install the `gcode_shell_command` extension.
* If `printer.cfg` is missing, the macro must be configured manually.
* If `BACKUP_GITHUB` is already present, the installer does not add another copy.
* Existing Git repositories are reused; the installer does not automatically merge their history with the remote.
* The initial push uses `--force` and may overwrite the remote `main` branch.
* The backup script stages eligible files in the configuration directory; it does not create a separate archive of the entire printer.
* A successful push does not independently verify that every desired file was backed up.

## 🧹 Clean up or reinstall

If you need to remove the local Git setup before reinstalling, the following commands remove the local repository metadata, backup script, and `.gitignore`:

```sh
cd /usr/data/printer_data/config
rm -rf .git git_backup.sh .gitignore
```

**Warning:** removing `.git` deletes the local Git history and remote configuration. It does not remove the macro from `printer.cfg`, and it does not delete your remote GitHub repository. Back up any important local data before running these commands.

After cleanup, rerunning the installer will initialize a new local Git repository and attempt another initial push. Because that push uses `--force`, make sure the target remote branch contains nothing you need to preserve.

## ⚖️ Disclaimer

This project is provided **"as is"**, without warranty of any kind, express or implied. Use it at your own risk. The author and contributors are not responsible for data loss, overwritten remote history, exposed credentials, printer issues, or other damage resulting from use of this software.

---

<div align="center">

**Made for the Creality K1C community** 🧡

</div>
