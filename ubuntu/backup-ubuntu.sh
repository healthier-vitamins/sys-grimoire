#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="$HOME/ubuntu-settings-backup"
ARCHIVE="$HOME/ubuntu-settings-backup.tar.gz"

echo "Removing old backup folder..."
rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"/{config,lists,logs}

echo "Backing up GNOME / Ubuntu / Tweaks settings..."
if command -v dconf >/dev/null 2>&1; then
  dconf dump /org/gnome/ > "$BACKUP_DIR/config/gnome-settings.ini"
fi

echo "Backing up APT package list..."
if command -v apt-mark >/dev/null 2>&1; then
  apt-mark showmanual > "$BACKUP_DIR/lists/apt-manual-packages.txt"
fi

echo "Backing up full dpkg package selections..."
if command -v dpkg >/dev/null 2>&1; then
  dpkg --get-selections > "$BACKUP_DIR/lists/dpkg-selections.txt"
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

echo "Backing up VS Code extensions..."
if command -v code >/dev/null 2>&1; then
  code --list-extensions > "$BACKUP_DIR/lists/vscode-extensions.txt" || true
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

# VS Code config
if [ -d "$HOME/.config/Code" ]; then
  cp -a "$HOME/.config/Code" "$BACKUP_DIR/config/vscode-config"
fi

# VS Code extensions folder
if [ -d "$HOME/.vscode" ]; then
  cp -a "$HOME/.vscode" "$BACKUP_DIR/config/vscode-folder"
fi

# Ghostty config
if [ -d "$HOME/.config/ghostty" ]; then
  cp -a "$HOME/.config/ghostty" "$BACKUP_DIR/config/ghostty"
fi

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
- Snap app list
- Flatpak app list
- VS Code settings and extensions
- Ghostty config
- nvm folder and Node/npm info
- shell configs
- GNOME extensions folders/settings
EOF

echo "Creating archive..."
tar -czf "$ARCHIVE" -C "$HOME" ubuntu-settings-backup

echo
echo "Backup complete:"
echo "$ARCHIVE"