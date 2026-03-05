#!/bin/bash

echo "1. Fetching the latest updates for all submodules..."
# This pulls the latest commit from the remote repository of each submodule
git submodule update --remote

echo "2. Staging the updated submodule folders..."
# This loops through all your submodules and safely stages only their specific folders
git submodule foreach --quiet 'git -C $toplevel add $path'

echo "3. Committing the new hash pointers to sys-grimoire..."
# This creates the commit with a standard message
git commit -m "chore: update submodules to latest remote commits"

echo "✅ Done! Your submodules are now up to date."
