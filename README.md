# circade

**A codebase audit skill for coding agents that finds the currents, not just the crumbs.**

Most "cleanup" passes list dead functions and duplicate helpers and call it a day. That is a QA pass. circade asks a harder question first: *which way is this codebase moving, and what will the next change cost because of it?* Then it breaks each current into work orders an agent can execute, and ends with a rule that fails if the current re-forms. It runs on the repository and its git history alone: no analytics, no production traces, no running site, nothing you have to ask the owner for.

Built for repos that coding agents write into every day, where the failure mode is not one bad function but a slope: four files absorbing every change, a predicate hand-copied into forty call sites, a hundred new tests that assert nothing, a folder structure making a promise the imports do not keep.

## What it stands on

circade composes methods and tools that each have a track record, and adds the judgement layer that turns their output into a decision.

**Behavioural code analysis** (Adam Tornhill). Hotspots are churn times size over a recent window, never complexity alone. Change coupling is file pairs that commit together without importing each other, which is a seam nobody cut. Both come from `git log` with two guards Tornhill's own tooling lacks: bulk commits are dropped so an agent touching 40 files does not make everything co-change, and a restructure inside the window is detected and old paths are aliased to new, because plain `git log` reads a moved file as brand new.

**Deep modules and the deletion test** (John Ousterhout, as sharpened by Matt Pocock's codebase-design vocabulary). Would deleting this module concentrate complexity or just move it? One adapter is a hypothetical seam, two is a real one. Depth is leverage, not the implementation-to-interface line ratio, which rewards padding.

**Architectural fitness functions** (Ford, Parsons, Kua). Every macro finding terminates in either a confirmed action or an executable rule: a `dependency-cruiser` boundary with today's violations allowlisted so it fails on the next one, a size ratchet on the files that absorb growth, a test-shape line in the agent's instruction file. The rule is the deliverable when a current is real but no cleanup is safe today.

**Trend over snapshot.** `trend.sh` archives the tree at four commits across the window and measures the same shape metrics at each: source and test lines, functions, exports, imports, duplication. The slope is the lead. A repo growing 15x in ten weeks is a project existing; tests outgrowing source 2.6x is a question worth a drill-down.

**Deterministic scanners, with their known failure modes written down.** `tsc --noUnusedLocals --noUnusedParameters` as the highest-signal JavaScript lens, with a scan-directory `jsconfig.json` bootstrap for plain CommonJS repos that have no type layer. `knip` with a shipped config, because bare knip lists untracked build output as unused, and with a second own-file count so an unused *export* is not confused with a dead *function*. `jscpd` per scope with a JSON reporter and a pair aggregator, because its console output truncates and an aggregate over mixed kinds reads as a quality score. `dependency-cruiser` zero-config for cycles and import hubs (the glob form; a bare directory returns nothing). [`ripwire`](https://github.com/redhat-et/ripwire) for call graphs and type-2/3 clones when installed, with its one-line XML tabulated so no group is skipped. PHPStan via a downloaded phar when the repo has none. Mutation testing only as an occasional hotspot scorecard, never a gate, because survivors handed to an agent become the next hundred tests.

**A WordPress semantic inventory, static.** Hooks (listeners against emitters, dynamic names), registrations (post types, REST routes and which lack a permission callback, blocks, CLI, Abilities), storage (options against site options, autoload share, raw `$wpdb`), cron (schedules against unschedules and guards), multisite switches, lifecycle hooks. It is what makes "this plugin schedules four recurring events and clears none, and has no deactivation hook" a finding a grep cannot produce. Point checks (unbounded queries, remote HTTP, nonces, escaping) are adopted from Plugin Check and the VIP coding standards rather than rebuilt.

**Three guards before any PHP symbol is called dead**, learned from a regression a code review caught: a string-registered callback check across PHP and JavaScript (`add_action`, REST callbacks, cron, shortcodes, `wp.hooks`, `[$this, 'method']`), a parent-chain walk through `vendor/` for abstract and template methods, and the knowledge that `WP_List_Table`, `WP_Widget` and `WP_REST_Controller` overrides are called by core and never appear as in-repo references.

## The rules that keep it honest

- **Evidence or drop.** No `file:line`, no finding. Every evidence row carries the command that produced it.
- **Trend numbers are leads, never findings.** A macro observation earns a slot only when a micro drill-down confirms it. "Distribution healthy, no action" is a sentence the report is allowed to write.
- **Read the whole file.** Scan output is read entire or tabulated first. Sampled evidence is never stated as a whole-family verdict.
- **The report describes the repository, never the machine the scan ran on.** A red baseline caused by the auditor's stale `node_modules` is fixed silently.
- **Honest stops.** Repo-derivable: N consumers in this repo, no import edge, a cycle, a path that can run an unbounded query. Never claimed: used in production, slow, wrong, drift versus roadmap. Roadmap versus drift is asked, one question per current.
- **Never a defect by itself:** cyclomatic complexity, coverage percentage, raw churn, export or function counts, duplication without a scope line, any aggregate score, any "AI-written" attribution.
- **Scope before anything.** A preflight compares tracked files with the disk tree and refuses to scan when gitignored archives dominate. The first field run reported 83 percent duplication from an evidence folder; the real figure was 5.

## What a run produces

One markdown report, at most five findings in total, worst current first:

- **Claim** in one sentence.
- **Currents** rated 1 to 5, where 5 compounds with every change, is unguarded and has already caused a defect, and 1 is cosmetic. The rating is about the current, not any item under it.
- Per current: direction with its window, evidence rows with commands, the mechanism labelled as inference, the shape of the fix as a diff, tactical items with tier (SAFE / CAREFUL / RISKY), owner, effort and done-when, a fitness rule, and a **falsifier**: the one thing the owner could say that dissolves the finding.
- **Residue**, **watch list** with why each lead did not earn a slot, ordered **actions**, and a **findings diff** against the previous audit of the same repo.

## Install

```bash
git clone https://github.com/noeltock/circade ~/circade
ln -s ~/circade/skills/audit ~/.claude/skills/audit      # Claude Code; or copy into a project's .claude/skills/
ln -s ~/circade/skills/audit ~/.codex/skills/audit       # Codex CLI; same frontmatter works for both
```

Requirements: `git`, `rg`, `python3`, `jq`, `node` with `npx`. Optional and worth having: `ripwire` (call graph, clones, hotspots across languages), PHPStan, Rector and composer-unused for PHP, `ruff` and `vulture` for Python. Anything missing degrades to a documented fallback and the report's coverage line says which evidence is consequently unavailable.

## Use

```
/audit                    # macro + micro, report only; scope to a subsystem on a first run
/audit src/analytics
/audit --focus tests
/audit --harness          # agent-readiness: instructions, bootstrap, self-check, worktree safety, debug access, gates
/audit --deep             # tools that need a repo-specific config or a rerun at past commits
/audit --apply            # execute the picks from a report, by tier
```

## Scripts

All in `skills/audit/scripts/`, repo-only, tested on TypeScript, CommonJS, PHP and WordPress codebases.

| Script | Does |
|---|---|
| `scope.sh` | Tracked vs on-disk files, exclude list in three tool formats, library-mode detection, tracked secret-shaped files (paths and key names only), scope trap |
| `renames.sh` | Restructure detection inside the history window |
| `trend.sh` | Shape metrics at N commits via `git archive`, pre-rename paths included |
| `hotspots.sh` | Churn times size, bulk commits dropped, renames aliased, refuses repos under eight weeks |
| `cochange.sh` | Co-change pairs with a commit-size filter |
| `detect-wp.sh`, `wp-inventory.sh` | WordPress detection and static semantic inventory |
| `wp-refs.sh`, `php-parent-chain.sh`, `php-unref.sh` | The three PHP dead-code guards and a zero-install define-vs-reference sweep |
| `jscpd-pairs.sh`, `ripwire-clones.sh` | Tabulate output that truncates or arrives as one line |

## Field notes

Four repositories audited while building this, and every rule above traces to something one of those runs got wrong: a scanner walking an untracked archive, a scout returning verdicts instead of evidence, an abstract override deleted because `vendor/` was not walked, a trend table read as a finding, a one-line XML read with `head -c` that hid the actual divergence. The skill is the accumulated set of those corrections. Contributions in the same spirit, a rule with the failure that motivated it, are welcome.

## Licence

MIT.
