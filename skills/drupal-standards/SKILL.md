---
name: drupal-standards
description: Drupal coding standards and drupal.org community conventions — PHP, JavaScript, CSS, Twig, YAML, naming, docblocks, file layout, and the rules a contributed project must meet to be accepted on drupal.org. Use whenever writing, reviewing, or refactoring code in a Drupal site, module, theme, recipe, or distribution; whenever setting up phpcs/phpstan/rector for a Drupal codebase; and whenever preparing a patch, merge request, or new project for drupal.org.
---

# Drupal coding standards

Drupal's standards are enforced by machine (`phpcs` with the `Drupal` and
`DrupalPractice` standards) and by human reviewers who apply conventions the
sniffs can't check. Both matter. Code that passes phpcs but reads like Symfony,
Laravel, or WordPress will get bounced in review.

## Non-negotiable rules

Load these into any Drupal file you write, without needing to open a reference:

- **Indent 2 spaces.** Never tabs. Line endings LF.
- **No closing `?>`** in files containing only PHP.
- **One blank line at end of file.** No trailing whitespace on any line.
- **80-char soft limit** on comments and docblocks; code lines have no hard cap
  but should stay readable. Never wrap a line just to hit 80 if it hurts clarity.
- **Control structures:** one space after the keyword, brace on the same line,
  `}` and `else` on the same line — `} else {`. Always use braces, even for
  one-line bodies.
- **Naming:** functions and procedural things `snake_case`; classes `PascalCase`;
  methods and properties `camelCase`; constants `UPPER_SNAKE_CASE`; class
  constants too. Module machine names `snake_case`, must not collide with core.
- **Strings:** prefer single quotes. Use double quotes only when interpolating or
  when the string contains single quotes. Concatenate with `.` surrounded by spaces.
- **Arrays:** short syntax `[]`. Trailing comma after the last element of a
  multi-line array — always.
- **Every function, method, class, interface, and file gets a docblock.** The
  summary line is one sentence, imperative mood, ends with a period, fits on one
  line. See `references/php.md` for the exact shape.
- **`t()` / `$this->t()` for every user-facing string.** Never concatenate
  translatable strings — use placeholders (`@var`, `%var`, `:url`).
- **Never `\Drupal::service()` inside a class that can take constructor
  injection.** Static calls are for procedural code and legacy shims only.

## Which reference to open

| Task | Read |
|---|---|
| PHP: docblocks, type hints, DI, services, plugins, forms, entities | `references/php.md` |
| JS, CSS, Twig, SDC, libraries, theming | `references/frontend.md` |
| Publishing to drupal.org: `.info.yml`, README, LICENSE, semver, GitLab CI, issue etiquette, security policy | `references/contribution.md` |
| Wiring up phpcs / phpstan / rector on this codebase | `references/tooling.md` and the ready-made files in the `configs/` folder of the claude-drupal-config repo (reachable at `<this skill's directory>/../../configs/` — the skill is linked from inside that repo; the local clone path is also in the global CLAUDE.md Drupal section) |

## Before claiming code is standards-compliant

Run the tools. Do not assert compliance from reading.

```bash
vendor/bin/phpcs --standard=phpcs.xml.dist web/modules/custom
vendor/bin/phpcbf --standard=phpcs.xml.dist web/modules/custom   # auto-fixes most of it
vendor/bin/phpstan analyse
```

If the project has no phpcs config, copy `configs/phpcs.xml.dist` in rather than
inventing one, and say that you added it.

## Community conventions the sniffs don't catch

These are the ones that get flagged in real drupal.org reviews:

- **Config, not code.** If a thing can be a view, a field, a text format, or a
  recipe, it should not be a custom module. Reviewers ask "why isn't this a view?"
- **Don't reinvent contrib.** Before writing a custom module, check drupal.org.
  Search the module name and the problem. Say what you found and why it doesn't fit.
- **Never hack core or contrib.** Patch through `composer-patches` with a link to
  the upstream issue, or override with a service decorator / event subscriber /
  hook. A patch with no upstream issue link is a red flag.
- **Config in code.** `drush cex` output belongs in git. Anything set through the
  UI that isn't exported doesn't exist. Use `config_ignore` or config splits
  deliberately, not as a way to avoid exporting.
- **Update hooks must be idempotent and safe to run on a large site.** Batch
  anything that touches entities. Never assume a service exists at update time —
  the container may be stale.
- **Prefer core APIs over direct database queries.** `\Drupal::database()` in new
  code needs a justification comment. Entity query, entity storage, or a Views
  display first.
- **Accessibility is a standard, not a nice-to-have.** WCAG 2.2 AA plus ATAG 2.0
  (the admin UI must be as accessible as the front end) is a hard **core gate** —
  core releases have been delayed over a11y regressions. Contributed projects are
  held to it too. Details in `references/frontend.md`.

## Style of the surrounding code wins

If you're editing an existing module that consistently does something
non-standard, match it and mention the divergence — don't silently reformat
unrelated lines. Standards apply fully to *new* files and *new* functions.
