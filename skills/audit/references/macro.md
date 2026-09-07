# Macro lens
Structure before history: agent-built repos are young and history lenses need ≥8 weeks of stable commits. Seven questions, in order; each yields leads, and a lead becomes a finding only with a micro confirmation row.

1. **Surface and obligations.** Entry points, exports, routes, registrations, documented contracts (step-3 inventory). Fixes what "unused" cannot mean.
2. **Seams that don't pay.** Single-consumer abstractions, single-implementation interfaces, one concept modelled two ways. Evidence: `ripwire --callers=file:name` when installed, else `rg -n '\bname\b'` for callers; rg `implements|extends`; a diff of the two models. Deletion test: would removing it concentrate complexity or move it. One adapter is a hypothetical seam, two is a real one.
3. **Import graph vs implied layering.** Cycles, direction against the folder structure, import hubs (dependency-cruiser, pydeps; PHP via composer namespaces and `use` direction). Rule engines need a config: `--deep`.
4. **Surface growth vs behaviour growth.** trend.sh ratios (exports/fns, imports/file, dup%, t/s), never absolutes. Growth is a project existing; the finding is what the drill-down shows (tests clustered on pass-throughs, test duplication above source, assertion-free tests). "Distribution healthy, no action" is a sentence worth writing.
5. **Hotspots.** hotspots.sh top 3 get the judge's attention first.
6. **Co-change without an import edge.** cochange.sh joined to the graph from 3; ≥50% of the smaller file's revisions with no import between them is a seam never cut.
7. **Test-mass placement.** Tests relative to hotspots and seams: test-file → module via imports, jscpd on test dirs, assertion shapes from test-hygiene.md.

## Finding contract
Direction statement with window → evidence rows with the producing command → mechanism, labelled inference → micro confirmation → smallest reversing action → falsifier (what would dissolve it, e.g. "that is the roadmap").

## Honest stops
Repo-derivable: N consumers in this repo, no import edge, co-change in k of n commits, a cycle, a path that can run an unbounded query, an option written without autoload, no cleanup path. Never claimed: used in production, slow, wrong, drift vs roadmap, AI-authored. Roadmap vs drift is asked, one question per current.

## Never a defect by itself
Cyclomatic complexity · impl/interface LOC ratio · coverage % · raw churn or LOC delta · test-count delta or t/s alone · export, file, function, hook or registration counts · dup % without a scope line · full-history coupling · co-change without the commit-size filter · a cycle without its consequence · a hotspot in a repo under 8 weeks · author concentration in a solo-plus-agents repo · doc inconsistency · any aggregate score · any "AI-written" attribution.

## `--deep`
deptrac / phparkitect / phpat / import-linter with authored rules · code-maat · git-of-theseus · api-extractor (TS) · static tools re-run at N commits · mutation on hotspots.
