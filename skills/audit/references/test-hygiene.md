# Test hygiene
The failure is shape, not count: tests that restate the implementation, mock what they assert, break on refactor, pass with the body stubbed. Agents optimise a visible oracle (arXiv 2606.28430). Count caps fix neither.

## Checks
Deterministic: jscpd `--min-tokens 30` on test dirs · trivial assertions (`toBeDefined`, `toBeTruthy`, `not.toThrow`, `assertTrue(true)`, `toHaveBeenCalled()` without args) · mocks outnumber assertions · tests of symbols flagged dead · `toMatchSnapshot` on internals · slowest 5 files. Count test cases from runner output, never source grep: `it.each` and `@dataProvider` inflate it.
Judgement on hotspot files: stub the body (early return, run its tests, pass = theatre, restore) · does it assert something a caller would notice, or re-derive the implementation.
Apply vocabulary: remove test, merge into a parameterised test, tighten assertion.

## Prevention rule (propose into the repo's CLAUDE.md)
```
## Tests
List existing tests for the file first and extend them. A new test names the failure
it catches that no existing test does. No assertion-free tests, no snapshots without a
stated public output, no file where mocks outnumber assertions. Assert behaviour a
caller notices, not implementation shape.
```
Propose removing the cause line if present ("add tests for all changes", "100% coverage").
