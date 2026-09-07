# `--harness` checks
This repo, not the agent's global configuration. Trace one task as an agent would; mark each pass / fail / n/a with evidence.

1. **Instructions**: CLAUDE.md states verify commands in the first screen, as commands. If AGENTS.md exists too, they agree or one imports the other (Claude Code reads only CLAUDE.md, Codex only AGENTS.md). Do-not-touch boundaries stated. No shape-free "add tests for all changes". Over ~150 always-loaded lines is a finding: instructions that long get skimmed.
2. **Bootstrap**: one command from clean clone to running. `.env.example` present; the agent is told which values it may not invent. Dev server documented as background plus stop by PID.
3. **Self-check**: one command for lint, types and targeted tests, non-zero on failure, under two minutes (report the number). Full-suite runtime known.
4. **Worktree safety**: ports, DB names, caches, `.env` parameterised for two trees, or documented as impossible. Fast path for `node_modules`/`vendor`. No tooling step runs `git checkout .`, `reset --hard` or `clean`.
5. **Debug access**: log location and tail command. UI repos: an agent-drivable browser path with a screenshot location. WP: WP-CLI, `WP_DEBUG_LOG`, Docker service names. Services: a health or smoke command.
6. **Gates**: a hook or pre-commit runs the self-check with timeout handling (a check outliving the harness timeout makes agents assume success). Deterministic quality feedback in the loop. Destructive-command guards as hooks or permission rules, not prose.
7. **Hand-off**: commit and PR conventions, which reviews run, what "done" requires.

Findings are doc, script and hook patches; the fitness patch is the point of this lens.
