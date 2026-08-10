# Lint and static-analysis tooling

Ready-made config files live in the claude-drupal-config repo's `configs/`
folder — from this reference file that's `../../../configs/` (the skill is
linked from inside that repo), and the local clone path is recorded in the
global CLAUDE.md Drupal section. Copy them into the project root rather than
authoring new ones.

## Install

```bash
composer require --dev \
  drupal/coder:^9.0 \
  phpstan/phpstan \
  mglaman/phpstan-drupal \
  phpstan/phpstan-deprecation-rules \
  palantirnet/drupal-rector \
  phpunit/phpunit
```

`drupal/coder` pulls in PHP_CodeSniffer and registers the `Drupal` and
`DrupalPractice` standards. If phpcs can't find them:

```bash
vendor/bin/phpcs --config-set installed_paths vendor/drupal/coder/coder_sniffer
```

Alternative: on a full site build, `composer require --dev drupal/core-dev`
pulls the whole official dev stack (coder, phpstan + phpstan-drupal +
phpstan-phpunit, phpunit, prophecy, Mink) at core-tested versions in one line.
Note core-dev may pin an older coder major than the standalone latest — either
is fine; don't fight the resolver.

`drupal-check` (mglaman) still exists as a quick deprecation-scan wrapper, but
plain phpstan with the deprecation rules gives the same answer with more
control — prefer phpstan directly.

For Twig style, **Twig CS Fixer** is the emerging standard tool; core also ships
`core/scripts/dev/commit-code-check.sh`, which runs the whole validate suite
(phpcs, phpstan, eslint, stylelint, cspell) the way core CI does.

### Optional: the PreviousNext overlay

`previousnext/coding-standard` is a widely-used agency ruleset layered on top of
`Drupal`/`DrupalPractice`. It relaxes Coder's most pedantic auto-generated-docblock
requirements in exchange for enforcing strict native type hints via PHPStan and
`@phpstan-param` / `@phpstan-return` annotations. Net effect: less boilerplate
comment, more actual type safety.

Reasonable for **client/agency projects**. Do **not** use it for code destined
for drupal.org — the project's own CI runs stock `Drupal`, and docblocks the
overlay let you skip will come back as review comments.

## What each tool is for

| Tool | Catches |
|---|---|
| `phpcs` (Drupal) | Formatting, naming, docblock grammar. Mechanical. |
| `phpcs` (DrupalPractice) | Anti-patterns: `t()` misuse, missing DI, hardcoded config, `\Drupal::` in classes. This is the one reviewers care about. |
| `phpstan` + `phpstan-drupal` | Type errors, undefined services, wrong entity API usage. |
| `phpstan-deprecation-rules` | Calls to deprecated core APIs — your major-version upgrade checklist. |
| `drupal-rector` | Auto-fixes many of those deprecations. |
| `eslint` / `stylelint` | JS and CSS. Core ships configs; extend them. |

## Running

```bash
# Format check + auto-fix. Run phpcbf first, it fixes most of it.
vendor/bin/phpcbf
vendor/bin/phpcs

# Static analysis. Start at level 1 on legacy code, aim for 6+.
vendor/bin/phpstan analyse

# Deprecation report only
vendor/bin/phpstan analyse --error-format=table | grep -i deprecat

# Auto-fix deprecations
vendor/bin/rector process --dry-run   # always dry-run first
vendor/bin/rector process
```

## PHPStan levels — realistic targets

- **Level 0–1**: legacy site you just inherited. Get it green, then raise.
  (Context: Drupal core itself runs level 1 with a large baseline; level 2 is
  core's stated goal. Your greenfield custom code has no such excuse.)
- **Level 2**: reasonable floor for a custom module in a client site.
- **Level 5–6**: what a well-maintained contrib project holds.
- **Level 8+**: possible but you'll fight Drupal's loosely-typed entity API.

Raise the level one notch at a time and fix, rather than setting 8 and
generating a 400-line baseline. If you must baseline:
`vendor/bin/phpstan analyse --generate-baseline`, and treat the baseline as debt
with an issue attached, not as a solution.

## Front-end linting

Core's configs are in the core directory — extend, don't fork:

```json
// .eslintrc.json
{ "extends": ["./web/core/.eslintrc.json"] }
```

```json
// .stylelintrc.json
{ "extends": "./web/core/.stylelintrc.json" }
```

```bash
npx eslint web/themes/custom
npx stylelint "web/themes/custom/**/*.css"
npx prettier --write "web/themes/custom/**/*.{js,css,yml}"
```

## Editor config

Drupal ships `.editorconfig` in core. Make sure the project root has one, or
2-space indent won't survive contact with a new machine.

## What to do before saying "done"

1. `phpcbf` then `phpcs` — clean.
2. `phpstan analyse` — clean or no *new* errors.
3. Relevant PHPUnit group passes.
4. If front-end changed: eslint + stylelint clean.

Report actual output. If something fails and you can't fix it, say which check
failed and paste the error.
