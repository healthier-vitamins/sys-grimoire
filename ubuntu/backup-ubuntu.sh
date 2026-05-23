#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="$HOME/ubuntu-settings-backup"
ARCHIVE="$HOME/ubuntu-settings-backup.tar.gz"

APT_EXCLUDE_REGEX='^(linux-|libnvidia-|nvidia-|ubuntu-|language-pack-|grub-|init$|login$|dash$|bsdutils$|ncurses-|shim-signed$|snapd$|base-files$|base-passwd$|bash$|coreutils$|dpkg$|apt$|apt-utils$|systemd|udev$)'

echo "Removing old backup folder..."
rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"/{config,lists,logs}
mkdir -p "$BACKUP_DIR/config/apt"

echo "Backing up GNOME / Ubuntu / Tweaks settings..."
if command -v dconf >/dev/null 2>&1; then
  dconf dump /org/gnome/ > "$BACKUP_DIR/config/gnome-settings.ini"
fi

echo "Backing up APT package list..."
if command -v apt-mark >/dev/null 2>&1; then
  apt-mark showmanual > "$BACKUP_DIR/lists/apt-manual-packages.txt"

  grep -Ev "$APT_EXCLUDE_REGEX" \
    "$BACKUP_DIR/lists/apt-manual-packages.txt" \
    > "$BACKUP_DIR/lists/apt-user-packages.txt" || true
fi

echo "Backing up full dpkg package selections..."
if command -v dpkg >/dev/null 2>&1; then
  dpkg --get-selections > "$BACKUP_DIR/lists/dpkg-selections.txt"
fi

echo "Backing up installed APT package inventory..."
if command -v dpkg-query >/dev/null 2>&1; then
  dpkg-query -W -f='${Package}\t${Version}\t${Status}\n' \
    > "$BACKUP_DIR/lists/dpkg-installed-packages.tsv"
fi

echo "Backing up APT sources/keyrings..."
if [ -f /etc/apt/sources.list ]; then
  cp -a /etc/apt/sources.list "$BACKUP_DIR/config/apt/sources.list" || true
fi

if [ -d /etc/apt/sources.list.d ]; then
  cp -a /etc/apt/sources.list.d "$BACKUP_DIR/config/apt/sources.list.d" || true
fi

if [ -d /etc/apt/keyrings ]; then
  cp -a /etc/apt/keyrings "$BACKUP_DIR/config/apt/keyrings" || true
fi

echo "Backing up Snap apps..."
if command -v snap >/dev/null 2>&1; then
  snap list > "$BACKUP_DIR/lists/snap-list-full.txt"
  snap list | awk 'NR>1 {print $1}' > "$BACKUP_DIR/lists/snap-packages.txt"
fi

echo "Backing up Flatpak apps..."
if command -v flatpak >/dev/null 2>&1; then
  flatpak list --app --columns=application > "$BACKUP_DIR/lists/flatpak-apps.txt" || true
fi

echo "Backing up GNOME extensions..."
if command -v gnome-extensions >/dev/null 2>&1; then
  gnome-extensions list > "$BACKUP_DIR/lists/gnome-extensions.txt" || true
fi

echo "Backing up Node / npm / nvm info..."
if [ -d "$HOME/.nvm" ]; then
  cp -a "$HOME/.nvm" "$BACKUP_DIR/config/nvm" || true
fi

if command -v node >/dev/null 2>&1; then
  node -v > "$BACKUP_DIR/lists/node-version.txt" || true
fi

if command -v npm >/dev/null 2>&1; then
  npm list -g --depth=0 > "$BACKUP_DIR/lists/npm-global-packages.txt" || true
fi

echo "Backing up app config folders..."

# Autostart apps
if [ -d "$HOME/.config/autostart" ]; then
  cp -a "$HOME/.config/autostart" "$BACKUP_DIR/config/autostart"
fi

# Local GNOME extensions
if [ -d "$HOME/.local/share/gnome-shell/extensions" ]; then
  mkdir -p "$BACKUP_DIR/config/gnome-shell"
  cp -a "$HOME/.local/share/gnome-shell/extensions" "$BACKUP_DIR/config/gnome-shell/extensions"
fi

echo "Backing up shell config files..."
for file in .bashrc .zshrc .profile .bash_profile .gitconfig; do
  if [ -f "$HOME/$file" ]; then
    cp -a "$HOME/$file" "$BACKUP_DIR/config/$file"
  fi
done

echo "Writing restore notes..."
cat > "$BACKUP_DIR/README.txt" <<'EOF'
Ubuntu settings backup.

Main restore command:
  ~/ubuntu-settings-backup/restore-ubuntu-settings.sh

What is backed up:
- GNOME / Ubuntu / Tweaks settings via dconf
- APT manual package list
- Filtered APT user package list
- Full dpkg selections
- Installed APT package inventory for diagnostics
- APT sources/keyrings
- Snap app list
- Flatpak app list
- nvm folder and Node/npm info
- shell configs
- autostart apps
- GNOME extensions folders/settings

What is NOT backed up:
- VS Code settings/extensions
- Ghostty config

APT restore behaviour:
- By default, restore uses lists/apt-user-packages.txt
- APT installs are best-effort; one missing package does not stop the rest
- Failed APT package installs are logged to logs/apt-restore-failures.txt during restore
- Raw apt-mark output is still saved as lists/apt-manual-packages.txt
- Installed package inventory is saved as lists/dpkg-installed-packages.tsv for diagnostics
- Command names can differ from apt package names, for example: rg -> ripgrep
- Ubuntu's fd-find package usually installs the fdfind command instead of fd
- APT sources/keyrings are backed up but not restored automatically unless RESTORE_APT_SOURCES=1 is set
EOF

echo "Creating archive..."
tar -czf "$ARCHIVE" -C "$HOME" ubuntu-settings-backup

echo
echo "Backup complete:"
echo "$ARCHIVE"
