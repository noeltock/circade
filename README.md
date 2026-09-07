# circade

**Codebase audits for agent-written repos. Finds the currents, not just the crumbs.**

A cleanup pass lists dead functions. circade asks which way the codebase is moving, what the next change will cost because of it, and which rule would stop it. Repo and git history only. No analytics, no production data, no running site.

```
/audit                # macro + micro, report only
/audit src/billing    # one subsystem
/audit --harness      # how agent-ready is this repo
/audit --apply        # execute the picks, by tier
```

## Stands on

| Method | From | What circade adds |
|---|---|---|
| Hotspots and change coupling | Adam Tornhill | Bulk-commit filter, rename aliasing across restructures, refuses repos under 8 weeks |
| Deep modules, the deletion test | John Ousterhout, Matt Pocock | Applied to every seam with one consumer or one implementation |
| Fitness functions | Ford, Parsons, Kua | Every macro finding ends in a rule that fails if the current continues |
| Trend over snapshot | `git archive` at N commits | Slope of source, tests, exports, imports, duplication |
| Falsifiers | | Each current names the sentence that would dissolve it |

## Runs

| Tool | Job | Guard circade ships |
|---|---|---|
| [`tsc`](https://www.typescriptlang.org/) `--noUnusedLocals` | Highest-signal JS lens | `jsconfig.json` bootstrap for plain CommonJS |
| [`knip`](https://knip.dev/) | Unused exports, files, deps | Shipped config; own-file count so an unused export is not a dead function |
| [`jscpd`](https://github.com/kucherenko/jscpd) | Duplication | Per scope, JSON reporter, pair aggregator; splits any scope over 10% |
| [`dependency-cruiser`](https://github.com/sverweij/dependency-cruiser) | Cycles, hubs, layering rules | Glob form (a bare dir returns nothing); allowlist today, fail tomorrow |
| [`ripwire`](https://github.com/redhat-et/ripwire) | Call graph, type-2/3 clones, hotspots | Optional. One-line XML tabulated so no group is skipped |
| [`PHPStan`](https://phpstan.org/) · [`Rector`](https://getrector.com/) | PHP types, dead code | Phar download when the repo has none; Rector dry-run only |
| [Plugin Check](https://github.com/WordPress/plugin-check) · [VIPCS](https://github.com/Automattic/VIP-Coding-Standards) | WordPress point checks | Adopted, not rebuilt |
| [`ruff`](https://docs.astral.sh/ruff/) · [`vulture`](https://github.com/jendrikseipp/vulture) | Python | |
| [`stryker`](https://stryker-mutator.io/) · [`mutmut`](https://github.com/boxed/mutmut) | Mutation | Hotspot scorecard only, never a gate |

## Ships

Thirteen repo-only scripts in `skills/audit/scripts/`:

- `scope.sh` tracked vs on-disk files, exclude list in three tool formats, library mode, tracked secrets by path, scope trap
- `trend.sh` `hotspots.sh` `cochange.sh` `renames.sh` the history lenses
- `wp-inventory.sh` static WordPress inventory: hooks, registrations, storage, cron, multisite, lifecycle
- `wp-refs.sh` `php-parent-chain.sh` `php-unref.sh` the three guards before a PHP symbol is called dead
- `jscpd-pairs.sh` `ripwire-clones.sh` tabulate output that truncates or arrives as one line

## Reports

One markdown file, at most five findings, worst current first.

| Severity | Meaning |
|---|---|
| 5 | Compounds with every change, unguarded, has already caused a defect |
| 4 | Compounds with every change, unguarded |
| 3 | Costs on a named upcoming change, or breaks an operational expectation |
| 2 | Local, one owner |
| 1 | Cosmetic |

Each current has: direction with its window, evidence rows with the producing command, mechanism labelled as inference, the fix as a diff, work orders with tier (SAFE / CAREFUL / RISKY), owner, effort and done-when, a fitness rule, a falsifier. Then residue, a watch list, ordered actions, and a diff against the previous audit.

## Rules

- Evidence or drop. No `file:line`, no finding.
- Trend numbers are leads. A macro observation needs a micro confirmation row.
- Scan files are read whole or tabulated. Sampled evidence is never a whole-family verdict.
- The report describes the repository, never the machine the scan ran on.
- Never a defect by itself: cyclomatic complexity, coverage %, raw churn, export counts, any aggregate score, any "AI-written" claim.
- Roadmap vs drift is asked, one question per current, never inferred.

## Install

```bash
git clone https://github.com/noeltock/circade ~/circade
ln -s ~/circade/skills/audit ~/.claude/skills/audit   # Claude Code
ln -s ~/circade/skills/audit ~/.codex/skills/audit    # Codex CLI
```

Needs `git`, `rg`, `python3`, `jq`, `node`. Everything else is optional and degrades to a documented fallback; the report says which evidence is missing.

## Field notes

Four repos audited while building this. Every rule traces to a run that got it wrong: a scanner walking an untracked archive (83% duplication reported, 5% real), a scout returning verdicts instead of evidence, an abstract override deleted because `vendor/` was not walked, a trend table read as a finding, a one-line XML read with `head -c`. Contributions in that spirit, a rule plus the failure behind it, are welcome.

MIT.
