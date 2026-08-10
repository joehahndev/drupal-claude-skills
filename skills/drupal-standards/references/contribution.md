# drupal.org project and contribution standards

What a project must look like to be accepted, and how to behave in the issue queue.

## Module / theme file layout

```
example/
  example.info.yml            required
  example.module               only if you still have procedural hooks
  example.install              schema + update hooks
  example.routing.yml
  example.services.yml
  example.links.menu.yml       .links.task.yml, .links.action.yml
  example.permissions.yml
  example.libraries.yml
  composer.json                required for drupal.org packaging
  README.md                    required
  LICENSE.txt                  do NOT commit — drupal.org adds it
  config/
    install/                   config shipped on install
    schema/example.schema.yml  required if you ship config
  src/
    Controller/ Form/ Plugin/ Service/ EventSubscriber/ Hook/
  templates/
  components/                  SDC
  tests/src/{Unit,Kernel,Functional,FunctionalJavascript}/
```

## `.info.yml`

```yaml
name: Example
type: module
description: 'One sentence, sentence case, no trailing period issues.'
package: Custom
core_version_requirement: ^11 || ^12
dependencies:
  - drupal:node
  - example_helper:example_helper
configure: example.settings
```

- **Never** hand-write `version:` or `project:` — the drupal.org packager injects
  them. A committed `version:` line is a review failure.
- `core_version_requirement` uses a Composer constraint. Support the current
  major and the next when you can.
- Dependencies are `project:module` format. Core modules are `drupal:name`.
- `package:` should be a real, existing package name — check the module list
  before inventing one. `Custom` for site-specific modules.

## `composer.json`

```json
{
  "name": "drupal/example",
  "type": "drupal-module",
  "description": "One sentence, matching .info.yml.",
  "license": "GPL-2.0-or-later",
  "require": {
    "drupal/core": "^11 || ^12"
  }
}
```

No `version` key — the packager handles it. License is GPL-2.0-or-later, always;
drupal.org will not accept anything else for the code itself.

## README.md

drupal.org has a required template. Sections, in this order:

```markdown
# Example

## Table of contents
## Introduction
## Requirements
## Recommended modules (optional)
## Installation
## Configuration
## Troubleshooting (optional)
## FAQ (optional)
## Maintainers
```

Introduction says what problem it solves and who it's for — not "This module
provides functionality."

## Semantic versioning

drupal.org projects use `{core}-{major}.{minor}.{patch}` for legacy branches and
plain semver (`2.1.3`) for Composer-era ones. Rules:

- Breaking API change → major bump. "API" includes services, hook signatures,
  plugin base classes, config schema, and anything documented in the README.
- New feature, backward compatible → minor.
- Bug fix only → patch.
- Deprecate for one full major before removing. Add `@deprecated in
  example:2.3.0 and is removed from example:3.0.0. Use Foo::bar() instead.` plus
  `@see` a change-record URL, and `trigger_error(..., E_USER_DEPRECATED)`.

## Security

- A stable release (no `-alpha`/`-beta`/`-rc`) with an opted-in maintainer gets
  Security Team coverage. Users should only run covered releases in production.
- Never disclose a suspected vulnerability in a public issue. Report it via
  the security team's private process.
- Security releases are always announced with an SA number — reference it.

## Issue scope — the rule new contributors break most

Drupal enforces **atomic contribution**: one issue and its merge request address
exactly one *concept*. This is the single most common reason a well-intentioned
MR stalls for months.

- Fixing a bug and noticing coding-standards violations in the same file? File a
  separate issue for the standards. Bundling them means the reviewer can't see
  the functional change through the whitespace diff, the MR can't be tested
  cleanly, and a critical fix gets blocked behind cosmetic churn.
- **Scoping by file group is also wrong.** "Fix all standards in module A" is not
  a concept — if it stalls halfway, the codebase is left inconsistent. Scope by
  the change: "Convert all annotation plugins to attributes."
- If you genuinely can't split it, say so in the issue summary and explain why.

## Issue queue etiquette

- Search before filing. Duplicates get closed and it costs a maintainer time.
- Reproduce against the **latest development branch**, not your site's version,
  before reporting. Half of filed bugs are already fixed in HEAD.
- Use the issue summary template. Specific reproduction steps, expected vs actual.
- One issue = one problem. "Also while I was in there…" needs its own issue.
- Issue title: imperative, describes the change, not the symptom. "Fix broken
  cache tag on the promo block" beats "Block doesn't update".
- Set the correct **Version** (the branch, not your site's version), **Component**,
  **Category** (Bug/Feature/Support/Task/Plan), and **Priority**. Don't set
  Critical on your own issue unless it's data loss or a security hole.
- Status flow: Active → Needs work ⇄ Needs review → RTBC → Fixed. Set **Needs
  review** when you post a merge request. Only set **RTBC** if you reviewed
  someone *else's* work and tested it — never your own.
- Say what you tested and how. "Tested on 11.4 with the standard profile, steps
  X/Y/Z, screenshot attached" is what moves an issue.
- **Merge requests are the only tested path.** DrupalCI and all patch testing
  were switched off **2024-07-01** — a patch file attached to an issue gets no
  CI and will usually be ignored. Always use the issue-fork MR workflow below.
- Credit: add everyone who contributed, including reviewers and issue reporters.
  This is a real community norm, not a formality. Equally, don't farm it —
  claiming credit for a "+1" comment is noticed and held against you.
- Be patient and specific. Maintainers are volunteers. "Any update?" adds noise;
  "I tested MR!12 on 11.4, works, here's a screenshot" adds signal.

## The merge-request workflow (issue forks)

1. Find or create the issue on drupal.org.
2. Click **Create issue fork** on the issue — a fork + branch appear on
   `git.drupalcode.org`.
3. Branch naming: `{issue-number}-{short-description}` (e.g.
   `3456789-fix-cache-tag`). Work on the issue branch; for a simple solo fix,
   committing directly to it is fine.
4. Clone/add the fork as a remote, commit, push.
5. On the issue: **Compare** → **Create merge request**. Source = issue branch,
   target = the correct dev branch (`11.x`, or the module's current dev branch).
6. **One MR per issue.** To update against upstream, rebase (preferred — cleaner
   for reviewers) or merge upstream into the same branch; never open a second
   MR. New commits auto-update the MR and re-trigger CI.
7. Set the issue status as you go (Needs review after pushing; respond to
   review; keep the issue summary current).

## Credit and the marketplace (why etiquette matters commercially)

Issue credits are granted by **maintainers** when an issue is fixed, can name
multiple people plus their organizations, and feed drupal.org's marketplace
ranking — weighted by project usage, so one credited fix on a million-site
module outweighs many on a tiny one. Creditable work includes code, review,
triage, docs, mentoring, and event work, not just commits. For an agency or
solo shop, maintaining a widely-used module is the single highest-leverage
reputation move; review work (the RTBC queue) is the fastest way to start.

## Security advisory coverage (opt-in process)

Coverage requires a **vetted** account, obtained once: submit one full
(non-sandbox) project to the security-coverage application queue
(`drupal.org/project/projectapplications`) — no known security issues, ~10-day
minimum wait, and the backlog can run months. The **review bonus** (review three
other applications and cite them) fast-tracks yours. Once vetted you can opt any
of your projects in. Only **stable releases** get the shield, and opting in is
one-way — only the Security Team can reverse it.

## GitLab CI

The old DrupalCI platform was retired in 2023 and replaced with GitLab CI across
git.drupalcode.org — core test runs went from ~an hour to ~5 minutes. Projects
inherit a centrally-maintained template, so the Association updates the PHP and
core version matrix for you; you do not pin versions yourself.

Three stages run: **Build** (composer install the environment), **Validate**
(phpcs, phpstan, eslint, stylelint, cspell), **Test** (PHPUnit + Nightwatch
across the matrix).

Minimum `.gitlab-ci.yml`:

```yaml
include:
  - project: $_GITLAB_TEMPLATES_REPO
    ref: $_GITLAB_TEMPLATES_REF
    file:
      - '/includes/include.drupalci.main.yml'
      - '/includes/include.drupalci.variables.yml'
      - '/includes/include.drupalci.workflows.yml'

variables:
  OPT_IN_TEST_NEXT_MAJOR: 1
  OPT_IN_TEST_PREVIOUS_MINOR: 1
```

Create it through the GitLab UI on the project — the file-template dropdown emits
the correct `include` block, which is safer than hand-copying.

Useful opt-in variables:

| Variable | Effect |
|---|---|
| `OPT_IN_TEST_NEXT_MAJOR: 1` | Test against the upcoming core major. Turn this on early in a major cycle. |
| `OPT_IN_TEST_PREVIOUS_MAJOR: 1` | Verify backward compatibility with the older major. |
| `OPT_IN_TEST_PREVIOUS_MINOR: 1` | Catch regressions against the prior minor. |
| `OPT_IN_TEST_MAX_PHP: 1` | Bleeding-edge PHP. |

To make lint failures actually block, override `allow_failure: false` on the
phpcs/phpstan jobs — by default some validate jobs are advisory, which is how
projects drift out of compliance without noticing.

Green CI before requesting review — a red pipeline reads as "not ready".

## Getting started as a contributor — phased

If the user is building a community footprint rather than fixing one thing,
suggest this progression. Each phase builds standing for the next.

1. **Triage and verification.** Find issues tagged *Needs review*, pull the MR
   locally, follow the reproduction steps, report what you saw, set RTBC if it
   holds. Requires no code authorship and is genuinely scarce labour — maintainers
   remember it.
2. **Code quality and tooling.** Run phpcs/phpstan against popular contrib
   modules, submit small tightly-scoped MRs for real infractions and
   deprecations. Teaches you the GitLab CI pipeline on low stakes.
3. **Architectural modernization.** Convert procedural hooks to `#[Hook]`,
   annotations to attributes, loose templates to SDCs with proper
   `*.component.yml` schemas. High-value, widely needed, and maintainers of older
   modules usually welcome it.
4. **Accessibility auditing.** `#accessibility` on Drupal Slack. Automated scan
   plus manual NVDA/VoiceOver verification of contrib modules, working with the
   Accessibility Topic Maintainers on semantic DOM fixes.

## Accessibility and licensing gates

- Any bundled third-party asset must be GPL-compatible. No CC-BY-NC, no
  proprietary fonts, no "free for personal use" anything.
- Don't commit compiled/minified vendor libraries; declare them as external
  libraries or Composer dependencies.
- Images and icons need a stated license in the README.
