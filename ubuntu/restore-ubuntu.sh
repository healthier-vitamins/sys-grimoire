#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="$HOME/ubuntu-settings-backup"
ARCHIVE="$HOME/ubuntu-settings-backup.tar.gz"
APT_FAILURE_LOG="$BACKUP_DIR/logs/apt-restore-failures.txt"

APT_EXCLUDE_REGEX='^(linux-|libnvidia-|nvidia-|ubuntu-|language-pack-|grub-|init$|login$|dash$|bsdutils$|ncurses-|shim-signed$|snapd$|base-files$|base-passwd$|bash$|coreutils$|dpkg$|apt$|apt-utils$|systemd|udev$)'

restore_dir() {
  local src="$1"
  local dest="$2"
  local stamp

  stamp="$(date +%Y%m%d-%H%M%S)"

  if [ ! -d "$src" ]; then
    return 0
  fi

  mkdir -p "$(dirname "$dest")"

  if [ -e "$dest" ]; then
    mv "$dest" "${dest}.before-restore-${stamp}"
  fi

  cp -a "$src" "$dest"
}

restore_file() {
  local src="$1"
  local dest="$2"
  local stamp

  stamp="$(date +%Y%m%d-%H%M%S)"

  if [ ! -f "$src" ]; then
    return 0
  fi

  mkdir -p "$(dirname "$dest")"

  if [ -e "$dest" ]; then
    mv "$dest" "${dest}.before-restore-${stamp}"
  fi

  cp -a "$src" "$dest"
}

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

mkdir -p "$BACKUP_DIR/logs"

echo "Checking for root-owned files under common user config folders..."
find "$HOME/.config" "$HOME/.local/share" 2>/dev/null \
  ! -user "$USER" \
  -print > "$BACKUP_DIR/logs/root-owned-files-before-restore.txt" || true

if [ -s "$BACKUP_DIR/logs/root-owned-files-before-restore.txt" ]; then
  echo "WARNING: Some files under your user config folders are not owned by $USER."
  echo "See:"
  echo "  $BACKUP_DIR/logs/root-owned-files-before-restore.txt"
  echo
fi

echo "Optionally restoring APT sources/keyrings..."
if [ "${RESTORE_APT_SOURCES:-0}" = "1" ]; then
  echo "RESTORE_APT_SOURCES=1 detected. Restoring APT sources/keyrings."

  if [ -f "$BACKUP_DIR/config/apt/sources.list" ]; then
    sudo cp -a "$BACKUP_DIR/config/apt/sources.list" /etc/apt/sources.list
  fi

  if [ -d "$BACKUP_DIR/config/apt/sources.list.d" ]; then
    sudo mkdir -p /etc/apt
    sudo cp -a "$BACKUP_DIR/config/apt/sources.list.d" /etc/apt/sources.list.d
  fi

  if [ -d "$BACKUP_DIR/config/apt/keyrings" ]; then
    sudo mkdir -p /etc/apt
    sudo cp -a "$BACKUP_DIR/config/apt/keyrings" /etc/apt/keyrings
  fi
else
  echo "Skipping APT sources/keyrings restore."
  echo "To restore them, rerun with:"
  echo "  RESTORE_APT_SOURCES=1 ./restore-ubuntu.sh"
  echo "WARNING: Some backed up packages may depend on repos that are not enabled yet on this machine."
  echo "Examples include ripgrep, fd-find, and gnome-tweaks from Ubuntu's universe component."
  echo "If APT says a package cannot be located, enable the needed repos or rerun with RESTORE_APT_SOURCES=1."
fi

echo "Updating APT..."
sudo apt-get update

echo "Preparing APT package restore list..."
if [ ! -f "$BACKUP_DIR/lists/apt-user-packages.txt" ] && [ -f "$BACKUP_DIR/lists/apt-manual-packages.txt" ]; then
  grep -Ev "$APT_EXCLUDE_REGEX" \
    "$BACKUP_DIR/lists/apt-manual-packages.txt" \
    > "$BACKUP_DIR/lists/apt-user-packages.txt" || true
fi

echo "Restoring APT apps..."
if [ -f "$BACKUP_DIR/lists/apt-user-packages.txt" ]; then
  : > "$APT_FAILURE_LOG"

  while read -r package; do
    [ -z "$package" ] && continue

    if ! sudo apt-get install -y "$package"; then
      echo "$package" >> "$APT_FAILURE_LOG"
      echo "WARNING: Failed to install APT package: $package"
    fi
  done < <(grep -v '^[[:space:]]*$' "$BACKUP_DIR/lists/apt-user-packages.txt")

  if [ -s "$APT_FAILURE_LOG" ]; then
    echo
    echo "APT restore completed with some package failures."
    echo "Failed package list:"
    echo "  $APT_FAILURE_LOG"
    echo "Common cause: the target machine is missing repos/sources needed for packages such as ripgrep, fd-find, or gnome-tweaks."
  else
    rm -f "$APT_FAILURE_LOG"
  fi
fi

echo "Restoring Snap apps..."
if command -v snap >/dev/null 2>&1 && [ -f "$BACKUP_DIR/lists/snap-packages.txt" ]; then
  while read -r app; do
    [ -z "$app" ] && continue

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

restore_dir "$BACKUP_DIR/config/autostart" "$HOME/.config/autostart"
restore_dir "$BACKUP_DIR/config/gnome-shell/extensions" "$HOME/.local/share/gnome-shell/extensions"

echo "Restoring shell config files..."
for file in .bashrc .zshrc .profile .bash_profile .gitconfig; do
  restore_file "$BACKUP_DIR/config/$file" "$HOME/$file"
done

echo "Restoring nvm folder..."
restore_dir "$BACKUP_DIR/config/nvm" "$HOME/.nvm"

echo "Restoring GNOME settings..."
if command -v dconf >/dev/null 2>&1 && [ -f "$BACKUP_DIR/config/gnome-settings.ini" ]; then
  echo "Loading GNOME dconf settings. This may override dock, keyboard, theme, extension, and desktop behaviour."
  dconf load /org/gnome/ < "$BACKUP_DIR/config/gnome-settings.ini"
fi

echo
echo "Restore complete."
echo
echo "Recommended next steps:"
echo "1. Log out and log back in."
echo "2. Reboot if GNOME extensions/dock/settings look weird."
echo "3. If NVIDIA drivers were intentionally skipped, reinstall them using Ubuntu's driver tool."
echo "4. Run: smartctl --version"
echo
echo "Notes:"
echo "- Existing restored config targets were renamed with .before-restore-<timestamp> instead of deleted."
echo "- APT sources/keyrings were not restored unless RESTORE_APT_SOURCES=1 was set."
