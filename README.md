# claude-drupal-config

Source of truth for Claude Code's Drupal knowledge, across machines.
Remote: `git@gitlab.com:joehahn/claude-drupal-config.git` (private).

Three skills live in `skills/`. They are linked into `~/.claude/skills/` by the
install script so every project on a machine can invoke them on demand —
editing a file here edits the live skill.

## Install on a machine

```bash
# Windows (PowerShell)
git clone git@gitlab.com:joehahn/claude-drupal-config.git C:\dev\claude-drupal-config
powershell -File C:\dev\claude-drupal-config\install.ps1

# Linux / macOS / a fresh machine like deadpixel
git clone git@gitlab.com:joehahn/claude-drupal-config.git ~/dev/claude-drupal-config
~/dev/claude-drupal-config/install.sh

# WSL on a machine that already has the Windows clone — reuse it, don't re-clone
bash /mnt/c/dev/claude-drupal-config/install.sh
```

The installers are idempotent — re-run after any `git pull` (they also repoint
links if the clone moved). They link the skills and insert/refresh a
marker-managed "Drupal work" section in that environment's `~/.claude/CLAUDE.md`
with the local clone path. Windows and WSL are **two separate Claude Code
environments** — each needs its own install run, but on one machine they can
share the single Windows clone.

To pick up upstream edits made on another machine: `git pull` (links point into
the clone, so nothing else to do).

| Skill | Invoke when |
|---|---|
| `drupal-standards` | Writing or reviewing any Drupal PHP/JS/CSS/Twig/YAML. Coding standards, docblocks, naming, drupal.org contribution rules. |
| `drupal-modern-core` | Deciding *how* to implement something. Current core version status, OOP hooks, SDC, recipes, attribute plugins — the "don't write it the 2019 way" skill. |
| `drupal-module-baselines` | Standing up a new site, or auditing an existing one's module list. Four site-type profiles. |

`configs/` holds runnable, copy-in tooling: `phpcs.xml.dist`, `phpstan.neon.dist`,
`rector.php`, plus `CLAUDE.md.template` for new Drupal repos. `drupal-standards`
points at these.

## How enforcement works (three layers)

1. **Global CLAUDE.md** (`~\.claude\CLAUDE.md`, "Drupal work — any repo" section)
   — always in context, tells every session to invoke the skills before Drupal
   work and how to bootstrap a new project. This is the deterministic layer.
2. **Skills** (junctioned globally) — the actual knowledge, loaded on demand.
3. **Per-repo CLAUDE.md + lint configs** — from `configs\CLAUDE.md.template`;
   pins the site profile and makes phpcs/phpstan runnable so "done" means
   "checks pass", not "looks right".

New Drupal project checklist: copy the template in as `CLAUDE.md`, fill the
placeholders (site type matters most — it selects the module baseline), copy the
three lint configs, run the composer require-dev line from the template.

## Refresh cadence

Drupal moves. Anything version-pinned in these skills is stamped with a date and
lives in `skills/drupal-modern-core/references/version-status.md` — that's the one
file to re-verify. Everything else (standards, API patterns) is stable across years.

Last verified: **2026-08-10**.

On Windows the script uses junctions (`mklink /J`), not symlinks — junctions
don't need admin or Developer Mode. On Linux/WSL it uses plain symlinks.
