#!/bin/bash

set -euo pipefail

log() {
  printf '%s\n' "$1"
}

warn() {
  printf 'WARN: %s\n' "$1" >&2
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)" ||
  die "Could not determine the repository root from $SCRIPT_DIR."

cd "$REPO_ROOT"

if ! git diff --quiet || ! git diff --cached --quiet || [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
  die "Working tree has uncommitted changes. Commit or stash them before running this script."
fi

CURRENT_BRANCH="$(git branch --show-current)"
UPSTREAM_BRANCH="$(git rev-parse --abbrev-ref --symbolic-full-name @{upstream} 2>/dev/null)" ||
  die "Current branch '${CURRENT_BRANCH:-HEAD}' does not have an upstream configured."

log "1. Updating the main sys-grimoire repo from $UPSTREAM_BRANCH..."
git pull --ff-only
log "Main repo is up to date."

declare -a configured_submodules=()
declare -a broken_gitlinks=()
declare -a updated_submodules=()

if [[ -f .gitmodules ]]; then
  while IFS= read -r path; do
    configured_submodules+=("$path")
  done < <(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{print $2}')
fi

while IFS= read -r path; do
  [[ -n "$path" ]] || continue
  if [[ ! " ${configured_submodules[*]} " =~ [[:space:]]${path}[[:space:]] ]]; then
    broken_gitlinks+=("$path")
  fi
done < <(git ls-files --stage | awk '$1 == 160000 { print $4 }')

if [[ ${#configured_submodules[@]} -eq 0 ]]; then
  log "2. No configured submodules found."
else
  log "2. Updating configured submodules..."
  for path in "${configured_submodules[@]}"; do
    if ! git ls-files --stage -- "$path" | awk 'NR == 1 { exit ($1 == 160000 ? 0 : 1) }'; then
      warn "Skipping $path because it is listed in .gitmodules but is not tracked as a gitlink."
      continue
    fi

    if git submodule update --init --remote -- "$path"; then
      git add "$path"
      updated_submodules+=("$path")
      log "Updated submodule: $path"
    else
      warn "Skipping $path because the submodule update failed."
    fi
  done
fi

if [[ ${#broken_gitlinks[@]} -gt 0 ]]; then
  for path in "${broken_gitlinks[@]}"; do
    warn "Skipping malformed gitlink with no .gitmodules entry: $path"
  done
fi

if git diff --cached --quiet; then
  log "3. No submodule pointer changes to commit."
else
  log "3. Committing updated submodule pointers..."
  git commit -m "chore: update submodules to latest remote commits"
  log "Created commit for submodule pointer updates."
fi

log "Done."
