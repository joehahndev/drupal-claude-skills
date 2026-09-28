# Drupal skills for Claude Code

Three [Claude Code skills](https://docs.claude.com/en/docs/claude-code/skills)
that keep an AI coding agent writing Drupal the way drupal.org expects it
written, plus the lint configs that make "done" mean "phpcs and phpstan pass".

They exist because an agent left to its own devices writes 2019 Drupal:
procedural hooks, annotation plugins, `\Drupal::service()` inside classes,
`drupal/media` as a contrib dependency. These skills are the correction, kept
in one repo so every machine and every project loads the same knowledge.

| Skill | Invoke when |
|---|---|
| `drupal-standards` | Writing or reviewing any Drupal PHP, JS, CSS, Twig or YAML. Coding standards, docblocks, naming, accessibility, and the drupal.org contribution rules (issue forks, merge requests, semver, security coverage). |
| `drupal-modern-core` | Deciding *how* to implement something. Current core version status, OOP `#[Hook]` classes, attribute plugins, SDC, recipes, config actions. The "don't write it the old way" skill. |
| `drupal-module-baselines` | Standing up a new site or auditing an existing one's module list. Four site-type profiles (public hosted, static, private, Drupal CMS) and a rubric for judging whether a contrib module is safe to depend on. |

`configs/` holds copy-in tooling: `phpcs.xml.dist`, `phpstan.neon.dist`,
`rector.php`, and a `CLAUDE.md.template` for new Drupal repos. `docs/` holds
the two long-form research documents the skills were distilled from.

## Install

The installers link `skills/*` into `~/.claude/skills/` and insert a
marker-managed "Drupal work" section into `~/.claude/CLAUDE.md` that tells
every session to invoke the skills before Drupal work. They are idempotent:
re-run after any `git pull`.

```bash
# Linux / macOS / WSL
git clone https://github.com/joehahndev/drupal-claude-skills.git ~/dev/drupal-claude-skills
~/dev/drupal-claude-skills/install.sh
```

```powershell
# Windows (PowerShell)
git clone https://github.com/joehahndev/drupal-claude-skills.git C:\dev\drupal-claude-skills
powershell -File C:\dev\drupal-claude-skills\install.ps1
```

Windows and WSL are two separate Claude Code environments. Each needs its own
install run, but on one machine they can share a single Windows clone: run
`bash /mnt/c/dev/drupal-claude-skills/install.sh` from inside WSL. On Windows
the installer uses directory junctions rather than symlinks, so it needs
neither admin rights nor Developer Mode.

## How enforcement works

1. **Global `CLAUDE.md`** section (written by the installer): always in
   context, tells every session to invoke the skills before Drupal work and
   how to bootstrap a new project. The deterministic layer.
2. **Skills**: the actual knowledge, loaded on demand.
3. **Per-repo `CLAUDE.md` and lint configs** from `configs/`: pins the site
   profile and makes phpcs and phpstan runnable, so the agent has to report
   real tool output before claiming compliance.

New Drupal project checklist: copy `configs/CLAUDE.md.template` in as
`CLAUDE.md` and fill the placeholders (site type matters most, it selects the
module baseline), copy the three lint configs, run the `composer require-dev`
line from the template.

## Keeping it current

Drupal moves. Anything version-pinned is stamped with a date and lives in
`skills/drupal-modern-core/references/version-status.md`. That is the one file
to re-verify; the standards and API patterns are stable across years.

Last verified against drupal.org: **2026-08-10**.

## License

MIT.
