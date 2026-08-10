<!-- claude-drupal-config:start (managed by install script — do not hand-edit between markers) -->
## Drupal work — any repo

Before writing or reviewing any Drupal code, invoke the relevant skills; don't work from memory:

- `drupal-standards` — coding standards, docblocks, a11y, drupal.org contribution rules.
- `drupal-modern-core` — how to implement things the current way (OOP hooks, attributes, SDC, recipes) and version facts.
- `drupal-module-baselines` — which contrib modules a site should (and shouldn't) have, by site type.

Source of truth: `{{REPO}}` (git repo; `git pull` it if skills seem stale). **Starting a new Drupal project:** copy `{{REPO}}/configs/CLAUDE.md.template` into the new repo as `CLAUDE.md` (fill in the placeholders — site type matters most), copy in `phpcs.xml.dist`, `phpstan.neon.dist`, and `rector.php` from the same folder, and add the require-dev packages listed in the template. Before claiming Drupal code is done, run phpcs and phpstan — report actual output, don't assert compliance from reading.
<!-- claude-drupal-config:end -->
