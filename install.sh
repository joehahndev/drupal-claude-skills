#!/usr/bin/env bash
# Installs/updates the Drupal skills + global CLAUDE.md section on Linux/WSL/macOS.
# Idempotent — safe to re-run after every git pull.
#
#   ./install.sh
#
# What it does:
#   1. Symlinks skills/* into ~/.claude/skills/.
#   2. Inserts or refreshes the "Drupal work" section in ~/.claude/CLAUDE.md,
#      between the claude-drupal-config markers, with this clone's path.
#
# WSL note: run this INSIDE WSL. Either clone the repo in the Linux filesystem,
# or run it against the Windows clone via /mnt/c/dev/claude-drupal-config —
# symlinks into /mnt/c work fine and keep a single copy per machine.

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${HOME}/.claude"
SKILLS_DIR="${CLAUDE_HOME}/skills"

# --- 1. Skill symlinks ------------------------------------------------------
mkdir -p "$SKILLS_DIR"
for src in "$REPO_ROOT"/skills/*/; do
  name="$(basename "$src")"
  link="$SKILLS_DIR/$name"
  src="${src%/}"
  if [ -L "$link" ]; then
    if [ "$(readlink "$link")" != "$src" ]; then
      ln -sfn "$src" "$link"
      echo "repointed: $name"
    else
      echo "ok: $name"
    fi
  elif [ -e "$link" ]; then
    echo "WARNING: $link exists and is not a symlink - resolve by hand." >&2
  else
    ln -s "$src" "$link"
    echo "linked: $name"
  fi
done

# --- 2. Global CLAUDE.md section --------------------------------------------
CLAUDE_MD="${CLAUDE_HOME}/CLAUDE.md"
SECTION="$(sed "s|{{REPO}}|${REPO_ROOT}|g" "$REPO_ROOT/configs/global-claude-section.md")"
START='<!-- claude-drupal-config:start'
END='<!-- claude-drupal-config:end -->'

if [ -f "$CLAUDE_MD" ]; then
  if grep -qF "$START" "$CLAUDE_MD"; then
    # Replace everything between (and including) the markers.
    awk -v section="$SECTION" -v start="$START" -v end="$END" '
      index($0, start) { skip = 1; print section; next }
      index($0, end)   { skip = 0; next }
      !skip            { print }
    ' "$CLAUDE_MD" > "$CLAUDE_MD.tmp" && mv "$CLAUDE_MD.tmp" "$CLAUDE_MD"
    echo "CLAUDE.md: section refreshed"
  else
    printf '\n%s\n' "$SECTION" >> "$CLAUDE_MD"
    echo "CLAUDE.md: section appended"
  fi
else
  mkdir -p "$CLAUDE_HOME"
  printf '# Global rules\n\n%s\n' "$SECTION" > "$CLAUDE_MD"
  echo "CLAUDE.md: created"
fi

echo "Done. Repo: $REPO_ROOT"
