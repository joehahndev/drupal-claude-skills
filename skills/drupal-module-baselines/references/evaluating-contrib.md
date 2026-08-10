# Vetting a contributed module

Before recommending or installing anything not in the baselines, check these.
State what you found — "Metatag, 800k+ sites, security covered, 11/12 compatible"
is a recommendation; "install Metatag" is a guess.

## The checks, in order of how often they matter

1. **Security team coverage.** The project page shows a green shield if a stable
   release is covered. **Uncovered modules should not run in production** on a
   public or internal site. An `-alpha`/`-beta`/`-rc` release is *never* covered,
   even on a covered project — this catches people out constantly.
2. **Core compatibility.** Read the actual `core_version_requirement` on the
   release, not the project page summary. `composer why-not drupal/core-recommended ^12`
   tells you the truth for the whole dependency tree.
3. **Maintenance status.** Project pages carry explicit flags: *Actively
   maintained*, *Minimally maintained*, *Maintenance fixes only*, *Seeking
   co-maintainers*, *Unsupported*, *Obsolete*. "Maintenance fixes only" can be
   fine (feature-complete), "Unsupported" or "Seeking new maintainer" on a
   load-bearing dependency is a risk to name out loud.
4. **Usage statistics.** Reported installs on the project page. Rough reading:
   >50k = safe and well-trodden; 5–50k = fine, expect to file the occasional
   issue; <1k = you are effectively a co-maintainer now. Low usage isn't
   disqualifying, but say so.
5. **Issue queue health.** Open criticals? Last commit date? A queue with recent
   maintainer replies beats one with 400 open issues and silence since 2023.
6. **Last release date** vs. the last core minor. A module with no release since
   two core minors ago will probably need a compatibility patch.
7. **Dependency weight.** Does it pull in five other modules? Each is another
   upgrade blocker. `composer require --dry-run` shows the real cost.
8. **License.** Must be GPL-2.0-or-later compatible. Bundled assets included —
   no "free for personal use" fonts or icon sets.

## Red flags

- No stable release and no activity for a year.
- The functionality is one view and a token pattern.
- It's a "kitchen sink" module where you want one feature — check whether the
  feature is separable.
- It patches core, or its README tells you to.
- It's a D7 backport with a `-dev` D11 branch.
- **It duplicates core.** Check `drupal-modern-core` → `version-status.md` for the
  absorbed-into-core list first.

## Patching contrib

Sometimes required. The rules:

- Every patch in `composer.json` `extra.patches` gets a **comment with the
  drupal.org issue URL**. A patch with no upstream issue is technical debt with
  no exit.
- Push the patch upstream as a merge request. If you're patching, someone else
  hits the same bug.
- Re-check patches at every minor core update — a silently-still-applying patch
  against changed code is a subtle bug source.
- Prefer a decorator, event subscriber, or hook over a patch when the extension
  points exist.

## Never hack core

If you're editing a file under `web/core`, stop. Composer will overwrite it on
the next update and the site will break at the worst time. The alternatives, in
order of preference: config → hook/event subscriber → service decorator →
composer patch with an upstream issue.
