````markdown
# Dotfiles Symlink Setup Guide

Follow these steps to securely link the centralized configurations in the `sys-grimoire` repository to your system's native configuration directories.

## Step 1: Clear Existing Configurations

Before creating a symlink, the destination path must be completely clear. Ensure any unsaved changes in your system folders are already backed up to the repository.

```bash
rm -rf ~/.config/ghostty
rm -rf ~/.config/nvim
```
````

## Step 2: Create the Symbolic Links

Use the `ln -s` command to map the repository folders to your system. **Crucial:** Always use absolute paths (like `~` or `/Users/...`) to prevent broken links.

```bash
ln -s ~/sys-grimoire/ghostty ~/.config/ghostty
ln -s ~/sys-grimoire/nvim ~/.config/nvim

```

## Step 3: Verify the Setup

Confirm the links were established correctly. The output should show the system folder pointing (`->`) to your `sys-grimoire` repository.

```bash
ls -l ~/.config | grep -E "ghostty|nvim"

```
