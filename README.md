# Superharness

An autonomous engineering lead plugin for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Describe the outcome you want — Superharness manages the entire development process: brainstorming, planning, building, testing, reviewing, and maintaining your codebase.

**You don't need to be an engineer.** Superharness proactively introduces engineering best practices — testing, QA, code review, CI, maintenance — adapted to each project. A throwaway prototype gets zero overhead. A production app with payments gets the full treatment. You never need to ask.

Inspired by [harness engineering research](https://openai.com/index/building-with-codex/) from OpenAI, Google DeepMind, and UC Berkeley, and built on patterns learned from the [Superpowers](https://github.com/superpowers-ai/superpowers) plugin.

## Installation

```bash
claude plugin add /path/to/superharness
```

## How It Works

Superharness follows a structured lifecycle driven by hooks and skills:

1. **SessionStart hook** injects the orchestrator, which assesses the current project state and decides what to do next.
2. **New projects:** The `kickoff` skill brainstorms the idea with you, then produces a product spec and an adaptive engineering plan (`.superharness/engineering-plan.json`).
3. **Existing projects:** The `build` skill picks up where you left off, implementing features according to the engineering plan.
4. **Pre-commit gate** enforces engineering plan checks before any commit is accepted.
5. **Completion gate** captures learnings and marks a clean session exit.
6. **Specialized skills** — `debug`, `qa`, `review`, and `maintain` — handle their respective concerns as needed.

## Key Features

- **Adaptive engineering** — assesses each project individually (type, scale, risk, stage) and determines appropriate practices. No fixed playbook.
- **Mechanical enforcement** — hooks enforce quality gates the agent can't bypass. Pre-commit checks, JSON validation, completion checklists.
- **Autonomous QA** — browser testing (Playwright), API testing, CLI testing, smoke testing — selected per project.
- **Codebase maintenance** — detects drift over time, dispatches audits, auto-fixes trivial issues, reports significant ones.
- **Cross-project memory** — learns from every project and surfaces relevant patterns when starting new ones.
- **Crash recovery** — tracks session state and detects unclean exits, prompting recovery on next session.

## Skills

| Skill | Purpose |
|---|---|
| `orchestrator` | Assesses project state, routes to the appropriate skill |
| `kickoff` | Brainstorms ideas, produces spec + adaptive engineering plan |
| `build` | Implements features following the engineering plan |
| `debug` | Systematic root cause analysis for bugs |
| `qa` | Adaptive QA testing (browser, API, CLI, smoke) |
| `review` | Self-review, agent review, human review, branch management |
| `maintain` | Codebase health audits, drift detection, garbage collection |

## Agents

| Agent | Purpose |
|---|---|
| `engineer` | Implements specific tasks following the engineering plan |
| `qa-agent` | Tests from the user's perspective — does not fix, only reports |
| `code-reviewer` | Reviews code quality, security, and patterns |
| `auditor` | Scans for drift, dead code, and codebase health issues |

## Configuration

The engineering plan at `.superharness/engineering-plan.json` is the main configuration file. It's created during `kickoff` and controls all downstream behavior — testing strategy, QA approach, commit conventions, code review requirements, and quality gates. You never need to write it manually.

## License

MIT
