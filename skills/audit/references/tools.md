# Scan tools
Repo's configured tool first; stack defaults below. Output to `<run>/scan/<tool>.txt`, each file opening `scope: <files> files · <symbols> symbols · top dirs … · dup <n>%`. Liveness checked 2026-09-07.

## Macro (default, git-only or zero-config)
`scripts/renames.sh` (exit 3 = restructure in window: hotspots and cochange alias old paths to new, trend adds pre-rename paths; churn and co-change are weak evidence, and cochange is skipped, also when the window holds under four weeks) · `scripts/trend.sh --since 6.months --points 4 <paths>` · `scripts/hotspots.sh --since 10.weeks <paths>` (refuses repos under 8 weeks, drops commits touching >15 files and says how many) · `scripts/cochange.sh --since 3.months --min 4 <paths>` · `npx -y dependency-cruiser --no-config -T json -x node_modules --ts-config tsconfig.json 'src/**/*.ts'` (glob form; a bare dir returns 0 modules; required, madge is not a substitute; keep cycles, orphans and the top-ten imported-by counts) · `pydeps --show-cycles` · ripwire hotspots.

## Surface inventory
TS/JS: `exports`/`main`/`bin` in package.json, `export` at entry files, Next/Remix route files. Python: `entry_points`, `pyproject` scripts. WordPress: `scripts/wp-inventory.sh` (wordpress.md).

## Duplication
`npx -y jscpd --min-tokens 50 --reporters json --output <run>/scan/jscpd-<scope> --ignore "$JSCPD_IGNORE" <paths>` once per scope (source, scripts, tests), then `scripts/jscpd-pairs.sh <json>`. Never on fixtures, locks, docs or archives. A scope over 10% is split further before its number appears; an aggregate over mixed kinds reads as a quality score.

## Call graph: ripwire (optional, https://github.com/redhat-et/ripwire; skip this block when it is not installed)
Positional paths only; `--exclude=` is inert. Indexes 0 PHP symbols, so on PHP repos it covers JS/TS only; say so in the coverage line. Panel: two of four evidence families unavailable on TS ("partial panel"), empty on plain JS.
```bash
ripwire $SRC_PATHS --ignore-tests --clones                > scan/ripwire-clones.txt    # type 2/3 duplicate bodies; one XML line: `scripts/ripwire-clones.sh` tables every group
ripwire $SRC_PATHS --ignore-tests --quality-panel=strict  > scan/ripwire-panel.txt     # read fired= per row, never the rank
ripwire $SRC_PATHS --ignore-tests --hotspots              > scan/ripwire-hotspots.txt
ripwire $SRC_PATHS --callers=file:SYM · --impact=file:SYM   # judge step; file: prefix mandatory when a name has >1 definition, or bare names merge and dead code looks reachable
ripwire $SRC_PATHS --quality-baseline                     # before --apply; --quality-delta after each tier, exit 2 = stop
```
Counts are floors: dynamic dispatch and string callbacks are invisible; `--dead-code` is silent for PHP/TS.

## TS/JS/Node
`npx tsc --noEmit --noUnusedLocals --noUnusedParameters` first, highest signal · `npx knip --config <skill dir>/scripts/knip.json --reporter compact` (bare knip lists untracked build output; ts-prune, depcheck, unimported are dead). Each knip unused file gets `git grep -l '<basename>'`; each unused export gets a count of the name inside its own file: ESM more than one, CommonJS more than two (definition plus the `module.exports` entry), means "unused export, live function", action drop the export; exactly the definition-plus-export count and nothing in the unscoped grep means dead · wrappers: `sg -p 'function $F($$$A) { return $G($$$A) }' -l ts`, else `rg -U -n '(function\s+\w+|=>)\s*\([^)]*\)\s*(:\s*[^{]+)?\{\s*return\s+\w+(\.\w+)*\([^)]*\);?\s*\}' -g '*.ts' -g '*.tsx'` (one-statement bodies), else the lens is uncovered.

## PHP / WordPress
PHPStan, zero-install: `curl -sL https://github.com/phpstan/phpstan/releases/latest/download/phpstan.phar -o <run>/phpstan.phar; php <run>/phpstan.phar analyse --level 5 --memory-limit 1G $SRC_PATHS` (without `szepeviktor/phpstan-wordpress`, filter `rg -v 'Function (wp_|get_|add_|apply_|do_|is_|register_)'`) · `vendor/bin/rector process --dry-run` with `SetList::DEAD_CODE`, never writing · `vendor/bin/composer-unused` · `vendor/bin/phpmd <path> text unusedcode,codesize`. When none is installed: `scripts/php-unref.sh <paths>` (define-vs-reference sweep, prints the follow-up command per candidate).
Before any PHP/WP symbol is called dead: `scripts/wp-refs.sh <symbol> [paths]` (string-registered callbacks: hooks, REST, cron, shortcodes, blocks, `wp.hooks`, `[$this,'m']`); any hit → CAREFUL at best. Methods also need `scripts/php-parent-chain.sh <Class> <method>` through `vendor/`; an ancestor declaring it means override, never SAFE; `unresolved:` means WP core. Framework-called overrides (`WP_List_Table`, `WP_Widget`, `WP_REST_Controller`) never show as in-repo references. WP pass-through wrappers default CAREFUL: often the hook surface. sensez has no PHP.

## Python
`ruff check --select F401,F841,ARG,PLR --output-format concise .` · `vulture . --min-confidence 80` · jscpd `--format python`. `deadcode` on PyPI is dead.

## Mutation
Hotspot scorecard under `--deep`, never a gate; survivors are interpreted, not turned into tests. stryker-js, mutmut, Infection (liveness unverified). Cheap substitute: stub the body with an early return, run its tests, pass = theatre, restore from git.

## Bootstraps when a lens is uncovered (run in the scan dir, no source changes)
- No type layer on JS: `<run>/jsconfig.json` `{"compilerOptions":{"checkJs":true,"allowJs":true,"noEmit":true,"noUnusedLocals":true,"noUnusedParameters":true},"include":["<src>"]}`, `npx -y tsc -p <run>/jsconfig.json`; read only unused (6133) and unreachable (7027) classes.
- No lint: `npx -y eslint --no-config-lookup --rule '{"no-unreachable":2,"no-unused-vars":2,"no-constant-condition":2,"no-fallthrough":2}' <src>`; propose the config as a fitness patch.
- No coverage: `node --test --experimental-test-coverage`, `npx -y c8 <test cmd>`, `vitest run --coverage`, `phpunit --coverage-text`; read only hotspot files. An uncovered region inside a hotspot outranks churn.
- Layering inferred from folders: a ten-line `.dependency-cruiser.cjs` as the fitness patch; run it under `--deep`.
- Supply chain: `npm audit --omit=dev --json` / `composer audit` / `pip-audit`, one residue line.
- Runtime evidence stays out; in-repo usage logs or cost reports go on the watch list as the only answer to "is this used".

## Performance
Only when incidental, as Worth exploring: N+1 DB loops, `array_merge` in loops, unmemoised selectors, sync file reads in request paths, duplicate fetches for one key.
