---
name: audit
description: |
  Audits a repository for currents flowing the wrong way (seams that don't pay, co-change hubs,
  hotspots, surface outgrowing behaviour) and for agent residue (dead code, duplicates, pass-through
  wrappers, test bloat), from the repo and its git history alone. Deterministic scan, judgement by
  the lead, one pool of at most five findings ranked by severity, tiered apply, and a fitness rule
  that stops each current re-forming. `--harness` audits the repo's agent-readiness instead.
  WordPress repos get a static hook/registration/storage inventory.
  Triggers: "/audit", "audit this repo", "is this codebase drifting", "find dead code", "too many tests".
  NOT for reviewing a diff for bugs, cleaning up the change you just made, or UI evidence.
argument-hint: "[path] [--harness] [--focus macro|dead|dup|arch|tests] [--deep] [--apply]"
allowed-tools: Bash, Read, Grep, Glob, Write, Agent
---

Success is a repo where the next change is cheaper and behaviour protection did not weaken. A smaller number is not a criterion. Macro is mandatory work, not a finding quota.

## Usage
```
/audit [path]        # macro + micro, report only; scope to a subsystem on first runs
/audit --focus tests
/audit --deep        # tools that need a repo-specific config, a rerun at past commits, or minutes per file
/audit --harness     # agent-readiness lens
/audit --apply       # execute the picks from a report
```
Scripts live beside this file in `scripts/`; references in `references/`. Run output goes to `$AUDIT_OUT/<repo>-<date>/` (default `${TMPDIR:-/tmp}/audit`), never into the repository.

## Procedure
1. **Scope.** `scripts/scope.sh`: exit 4 names the real checkout, exit 5 means ask. Exit 3: `eval "$(scripts/scope.sh --format shell)"` and pass `$SRC_PATHS` positionally to every scanner, `${RG_X[@]}` to rg, `$JSCPD_IGNORE` to jscpd. A tracked secret-shaped file it lists is the first action, RISKY, paths and key names only. `git branch --list '*audit*' '*cleanup*' '*dead*'`: diff any hit and exclude what it already removes. Run snippets under `bash -c`. A scan file without its scope line is not evidence.
2. **Prior audit and baseline.** Find the last audit of this repo (the run directory, or wherever the user keeps them). Read it in full; the new report carries every evidence row it had or names the row and why it was dropped, in a required Findings diff (kept, dropped, new). Read the README and architecture doc; section 01 describes the product, not the scan. Then baseline: read the prior `Baseline needs:` line; check readiness (`docker compose ps`) before the timer. Concurrently: the primary suite (fresh; remove only the runner's own cache: `.phpunit.result.cache`, `.pytest_cache`, `node_modules/.cache/jest`, `node_modules/.vite/vitest`), lint, typecheck or `none`. Three minutes of suite time; over blocks `--apply`, not the report. Record runner, required-test discovery, source parity (does the container run this checkout), gate. A red caused by the repo is a blocker; one caused by this machine is fixed silently and noted only in `Baseline needs:`.
3. **Surface inventory.** What the repo exposes and registers, per stack in [references/tools.md](references/tools.md); WordPress (`scripts/detect-wp.sh`) via `scripts/wp-inventory.sh` and [references/wordpress.md](references/wordpress.md). Library mode makes single-consumer and unused-export findings CAREFUL with "external consumers unknown" in the text.
4. **Macro scan.** `scripts/renames.sh` (exit 3: history lenses are weak, skip cochange), `trend.sh`, `hotspots.sh`, `cochange.sh`, dependency-cruiser (required; madge answers cycles only and does not replace it; record the top-ten modules by require count) or pydeps, ripwire hotspots when installed. Output to files. The default names any deep tool a lead points at.
5. **Micro scan.** Language-native strict check first, then clones, jscpd per scope, configured tools, stack defaults. Any helper agent returns evidence tables only; its verdicts are discarded. PHP/WP symbols stay provisional until `wp-refs.sh` returns nothing and `php-parent-chain.sh` finds no ancestor. A missing tool gets its bootstrap from tools.md before a coverage line names the evidence that is unavailable.
6. **Judge**, the lead only, from scan files read whole: never `head`, `-c` or `| head` on a scan file; if one is too long, parse it into a table first (`scripts/ripwire-clones.sh` for clones). Sampled evidence is never stated as a whole-family verdict. Macro questions in the order in [references/macro.md](references/macro.md); a macro observation is a finding only with a micro confirmation row, otherwise a lead. Micro: deletion test, wrapper vs boundary, duplicate vs divergent policy, single consumer, altitude; tests per [references/test-hygiene.md](references/test-hygiene.md). Clone groups touching a hotspot: diff every member pair and blame the first line of every member; "identical" only after all pairs are diffed, and a younger member is checked for added predicates or guards. Boundary edges rank by what crosses (policy, authorisation, denied-tool sets outrank shape helpers), not by importer count; read the head comment of the imported module first. Any ad hoc classifier is validated on one known-live and one known-dead symbol before its output is used. `git blame` on removals. No `file:line`, no finding. Roadmap vs drift is asked, one question per current, never inferred.
7. **Report** per [references/report.md](references/report.md). Stop for picks. Restructures are proposals.
8. **Apply** (`--apply`). Closed vocabulary: delete symbol, inline wrapper, redirect callers to existing symbol, remove test, tighten assertion, add fitness rule. SAFE items can go to a cheap executor with named files, exact symbols and the test command; CAREFUL items need the judgement written into the brief or commit; RISKY items are proposals only. One commit per tier per batch; re-run the baseline after each, and any drop, new skip or runtime spike stops the run. Finish with an independent review of the diff.
9. **Fitness patch.** Every macro finding ends in a confirmed action or a rule that fails if the current continues (dependency rule, test-shape line in the agent instructions file, scope exclude, lint hook). Propose, never write silently.

## `--harness`
[references/harness-checks.md](references/harness-checks.md). Same report shape; instruction-file edits SAFE, new hooks CAREFUL, CI or secrets RISKY.

## Rules
- Evidence or drop. Trend numbers are leads. Qualify claims: "in this repo", "in the window", "reachable, not observed".
- Patch, never rewrite a file to remove a function. Never `rm`; move aside.
