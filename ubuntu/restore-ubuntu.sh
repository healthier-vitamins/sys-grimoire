#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="$HOME/ubuntu-settings-backup"
ARCHIVE="$HOME/ubuntu-settings-backup.tar.gz"

if [ ! -d "$BACKUP_DIR" ]; then
  if [ -f "$ARCHIVE" ]; then
    echo "Extracting backup archive..."
    tar -xzf "$ARCHIVE" -C "$HOME"
  else
    echo "ERROR: Could not find:"
    echo "  $BACKUP_DIR"
    echo "or:"
    echo "  $ARCHIVE"
    exit 1
  fi
fi

echo "Updating APT..."
sudo apt update

echo "Restoring APT apps..."
if [ -f "$BACKUP_DIR/lists/apt-manual-packages.txt" ]; then
  while read -r pkg; do
    [ -z "$pkg" ] && continue
    sudo apt install -y "$pkg" || true
  done < "$BACKUP_DIR/lists/apt-manual-packages.txt"
fi

echo "Restoring Snap apps..."
if command -v snap >/dev/null 2>&1 && [ -f "$BACKUP_DIR/lists/snap-packages.txt" ]; then
  while read -r app; do
    [ -z "$app" ] && continue

    # Skip core/system snaps that usually already exist or are managed by snapd
    case "$app" in
      core|core18|core20|core22|core24|snapd|bare|gnome-*|gtk-common-themes)
        continue
        ;;
    esac

    sudo snap install "$app" || sudo snap install "$app" --classic || true
  done < "$BACKUP_DIR/lists/snap-packages.txt"
fi

echo "Restoring Flatpak apps..."
if command -v flatpak >/dev/null 2>&1 && [ -f "$BACKUP_DIR/lists/flatpak-apps.txt" ]; then
  while read -r app; do
    [ -z "$app" ] && continue
    flatpak install -y flathub "$app" || true
  done < "$BACKUP_DIR/lists/flatpak-apps.txt"
fi

echo "Restoring config folders..."
mkdir -p "$HOME/.config"

if [ -d "$BACKUP_DIR/config/vscode-config" ]; then
  rm -rf "$HOME/.config/Code"
  cp -a "$BACKUP_DIR/config/vscode-config" "$HOME/.config/Code"
fi

if [ -d "$BACKUP_DIR/config/vscode-folder" ]; then
  rm -rf "$HOME/.vscode"
  cp -a "$BACKUP_DIR/config/vscode-folder" "$HOME/.vscode"
fi

if [ -d "$BACKUP_DIR/config/ghostty" ]; then
  rm -rf "$HOME/.config/ghostty"
  cp -a "$BACKUP_DIR/config/ghostty" "$HOME/.config/ghostty"
fi

if [ -d "$BACKUP_DIR/config/autostart" ]; then
  rm -rf "$HOME/.config/autostart"
  cp -a "$BACKUP_DIR/config/autostart" "$HOME/.config/autostart"
fi

if [ -d "$BACKUP_DIR/config/gnome-shell/extensions" ]; then
  mkdir -p "$HOME/.local/share/gnome-shell"
  rm -rf "$HOME/.local/share/gnome-shell/extensions"
  cp -a "$BACKUP_DIR/config/gnome-shell/extensions" "$HOME/.local/share/gnome-shell/extensions"
fi

echo "Restoring shell config files..."
for file in .bashrc .zshrc .profile .bash_profile .gitconfig; do
  if [ -f "$BACKUP_DIR/config/$file" ]; then
    cp -a "$BACKUP_DIR/config/$file" "$HOME/$file"
  fi
done

echo "Restoring nvm folder..."
if [ -d "$BACKUP_DIR/config/nvm" ]; then
  rm -rf "$HOME/.nvm"
  cp -a "$BACKUP_DIR/config/nvm" "$HOME/.nvm"
fi

echo "Restoring VS Code extensions..."
if command -v code >/dev/null 2>&1 && [ -f "$BACKUP_DIR/lists/vscode-extensions.txt" ]; then
  while read -r ext; do
    [ -z "$ext" ] && continue
    code --install-extension "$ext" || true
  done < "$BACKUP_DIR/lists/vscode-extensions.txt"
fi

echo "Restoring GNOME settings..."
if command -v dconf >/dev/null 2>&1 && [ -f "$BACKUP_DIR/config/gnome-settings.ini" ]; then
  dconf load /org/gnome/ < "$BACKUP_DIR/config/gnome-settings.ini"
fi

echo
echo "Restore complete."
echo "Recommended next steps:"
echo "1. Log out and log back in."
echo "2. Reboot if GNOME extensions/dock settings look weird."
echo "3. Open VS Code once to verify extensions/settings."
echo "4. Run: smartctl --version"