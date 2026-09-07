# circade

An agent skill that audits a codebase for the currents flowing the wrong way, not just the tactical residue.

Coding agents add and rarely delete. After a few months a repo carries another hundred tests that assert nothing, helpers written three times, a predicate hand-copied into forty files, and a plugin that schedules work it never clears. A cleanup pass finds the residue. This skill finds the *direction*: which four files absorb every change, which seam was never cut, where the folder structure makes a promise the imports do not keep. Then it breaks each current into delegable work orders and ends with a fitness rule that fails if the current re-forms.

It works from the repository and its git history alone. No analytics, no production data, no running site.

## What a run produces

One markdown report, at most five findings in total:

- **Claim** in one sentence: what the repo is doing and what is only residue.
- **Currents**, ranked 1 to 5 (5 is worst; it rates the current, not any item under it), each broken into tactical items with a tier (SAFE / CAREFUL / RISKY), an owner, an effort estimate and a done-when line.
- **Evidence rows** that each carry the command that produced them.
- **Falsifier** per current: the one thing the owner could say that dissolves it ("that is the roadmap").
- **Fitness rule** per current: the dependency rule, test-shape line or lint gate that would have stopped it.
- **Watch list**: leads that did not earn a slot, and why.
- **Findings diff** against the previous audit of the same repo.

The rules that keep it honest: evidence or drop; trend numbers are leads, never findings; sampled evidence is never a whole-family verdict; the report describes the repository, never the machine the scan ran on.

## Install

Claude Code:
```bash
git clone https://github.com/noeltock/circade ~/circade
ln -s ~/circade/skills/audit ~/.claude/skills/audit      # or copy into a project's .claude/skills/
```
Codex CLI: link or copy the same folder into `~/.codex/skills/audit`. The SKILL.md frontmatter works for both.

Requirements: `git`, `rg` (ripgrep), `python3`, `jq`, `node`/`npx` for the JavaScript tools. Optional: `ripwire` (call graph and clone detection), PHPStan / Rector / composer-unused for PHP, `ruff` / `vulture` for Python. Missing tools degrade to documented fallbacks and the report says which evidence is consequently unavailable.

## Use

```
/audit                    # macro + micro on the current repo, report only
/audit src/analytics      # scope to a subsystem (recommended for a first run)
/audit --focus tests
/audit --harness          # how agent-ready is this repo: instructions, bootstrap, self-check, worktree safety, debug access, gates
/audit --deep             # adds tools that need a repo-specific config or a rerun at past commits
/audit --apply            # execute the picks from a report, by tier
```

## Scripts

All in `skills/audit/scripts/`, all repo-only, tested on TypeScript, CommonJS, PHP and WordPress codebases.

| Script | What it does |
|---|---|
| `scope.sh` | Tracked vs on-disk files, ignored dirs to exclude, library-mode detection, tracked secret-shaped files (paths and key names only), and a scope trap that refuses to scan an archive-polluted tree |
| `renames.sh` | Detects a restructure inside the history window, because plain `git log` cannot see across it |
| `trend.sh` | The same shape metrics at N commits: files, source and test lines, functions, exports, imports, duplication. Slope, not snapshot |
| `hotspots.sh` | Churn times size over a recent window, with old paths aliased across renames; refuses repos under eight weeks old |
| `cochange.sh` | File pairs that change together without importing each other, with a commit-size filter so bulk agent commits do not make everything co-change |
| `detect-wp.sh`, `wp-inventory.sh` | Static WordPress semantic inventory: hooks, registrations, storage, cron, assets, capabilities, multisite, lifecycle |
| `wp-refs.sh`, `php-parent-chain.sh`, `php-unref.sh` | The three checks that stop a PHP symbol being called dead when a string-registered callback, a framework override or an abstract parent in `vendor/` still reaches it |
| `jscpd-pairs.sh`, `ripwire-clones.sh` | Turn tool output that truncates or arrives as one line into tables the judge can read whole |

## What it will not do

Claim anything the repo cannot show: that code is used in production, that something is slow, that a change is drift rather than roadmap. Those are questions, and the report asks them, one per current.

## Licence

MIT.
