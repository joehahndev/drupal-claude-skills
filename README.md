# claude-drupal-config

Source of truth for Claude Code's Drupal knowledge on this machine.

Three skills live in `skills/`. They are **junctioned** into
`C:\Users\joehahn\.claude\skills\` so every project on this machine can invoke
them on demand — editing a file here edits the live skill.

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

## Install / reinstall the junctions

```powershell
cmd /c mklink /J "C:\Users\joehahn\.claude\skills\drupal-standards"        "C:\dev\claude-drupal-config\skills\drupal-standards"
cmd /c mklink /J "C:\Users\joehahn\.claude\skills\drupal-modern-core"      "C:\dev\claude-drupal-config\skills\drupal-modern-core"
cmd /c mklink /J "C:\Users\joehahn\.claude\skills\drupal-module-baselines" "C:\dev\claude-drupal-config\skills\drupal-module-baselines"
```

Junctions (`/J`), not symlinks (`/D`) — junctions don't need admin or Developer Mode.
