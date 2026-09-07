# Report
`$AUDIT_OUT/<repo>-<date>/report.md` (default `$AUDIT_OUT` is `${TMPDIR:-/tmp}/audit`), shown to the user in full, never written into the repository. It describes the repository, not the machine the scan ran on. Shape: claim → standing → currents ranked → each current broken into tactical items → residue → watch list → actions. A flat list of findings is the failure mode.

## Severity, 1 to 5, rates the current not the item
**5** compounds with every change, unguarded, has already produced a defect · **4** compounds, unguarded · **3** costs on a named upcoming change or breaks an operational expectation · **2** local, one owner · **1** cosmetic. Residue is 1.

## Spine
```markdown
# <Repo> codebase audit — <date> — <HEAD>
**Claim:** <one sentence: what the repo is doing and what is only residue>
**Baseline:** runner <p>/<f>/<s> in <t> · required tests <ok|n undiscovered> · source parity <ok|stale|n/a> · lint · types · gate <usable|red: why>
**Baseline needs:** <containers, services, test tables the next run must have>
**Scope:** <tracked> tracked · source paths · excluded <top-level> · library mode · dup % per scope · audit branch <none|name, what it removes>
**Coverage:** <per evidence kind: dead functions fallback · dead methods partial · types uncovered · dependency usage uncovered · WP reachability static-approximate · ripwire JS/TS only>
**First action:** <what, why first>

## 01 Project       <what the product does and its stated invariants, from README and the architecture doc; then what is healthy and what the evidence cannot say>
## 01b Findings diff <kept · dropped, with why · new, against the prior audit of this repo; "no prior audit found" is the only permitted absence>
## 02 Currents      <ranked with severity, one line each; then the tree: current → tactical items with tier · owner · effort>
## 03..0N           <one section per current, worst first: direction with window → evidence rows, each with its producing command → one chart from the template's SVG classes when the current has a time or rank dimension → mechanism, labelled inference → shape of the fix as a diff → tactical items (tier · owner · effort · done-when) → fitness rule → falsifier>
## Residue          <micro items with no current: item · evidence · tier · action>
## Watch list       <leads with why each is not a finding; the roadmap question per current; passes>
## Actions          <ordered: title · owner · effort · link to the section item ("→ 03 item 02"), never a restatement; fitness rules; baseline needs>
## Scan             <wall time · tools run · failures · deep tools a lead points at>
```
At most five tactical items hold a slot across all currents. A macro observation without a confirmation row goes to the watch list. Strength and risk are separate axes.
