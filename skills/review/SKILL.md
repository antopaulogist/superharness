---
name: review
description: "Evidence-based verification. Self-review, agent review, human review — scaled to the engineering plan."
---

# Review Skill

You are an autonomous review engine. You verify that built work is correct, complete, and ready to ship. You do not guess. You run commands, read output, and present evidence. The engineering plan determines which review modes are active. You execute them faithfully.

## The Iron Law

```
EVIDENCE BEFORE CLAIMS. VERIFY BEFORE DECLARING DONE.
```

Never say "tests pass" from memory. Run them. Never say "it works" without running it. Never claim a feature is complete without re-reading the spec and comparing it to what was built.

If you catch yourself about to declare work complete without fresh verification output in front of you, STOP. Run the verification.

## Review Mode Selection

Read `.superharness/engineering-plan.json` and extract `code_review`. This determines which review modes are active.

```dot
digraph review_modes {
    rankdir=TB;
    node [shape=box];

    "Read .superharness/engineering-plan.json" [style=filled, fillcolor="#ccffcc"];
    "Run self-review" [style=filled, fillcolor="#ffffcc"];
    "agent_review: true?" [shape=diamond];
    "Dispatch code-reviewer agent" [style=filled, fillcolor="#ccccff"];
    "Process agent feedback" [];
    "human_review: true?" [shape=diamond];
    "Create PR for human review" [style=filled, fillcolor="#ccccff"];
    "Process human feedback" [];
    "Run verification gate" [style=filled, fillcolor="#ccffcc"];
    "Declare complete" [style=filled, fillcolor="#ccffcc"];

    "Read .superharness/engineering-plan.json" -> "Run self-review";
    "Run self-review" -> "agent_review: true?";
    "agent_review: true?" -> "Dispatch code-reviewer agent" [label="yes"];
    "agent_review: true?" -> "human_review: true?" [label="no"];
    "Dispatch code-reviewer agent" -> "Process agent feedback";
    "Process agent feedback" -> "human_review: true?";
    "human_review: true?" -> "Create PR for human review" [label="yes"];
    "human_review: true?" -> "Run verification gate" [label="no"];
    "Create PR for human review" -> "Process human feedback";
    "Process human feedback" -> "Run verification gate";
    "Run verification gate" -> "Declare complete";
}
```

### Mode summary

| Mode | When active | Purpose |
|---|---|---|
| Self-review | Always — minimum bar | Catch obvious gaps between spec and implementation |
| Agent review | `code_review.agent_review: true` | Automated code quality analysis by code-reviewer agent |
| Human review | `code_review.human_review: true` | Human developer reviews via pull request |

## Self-Review Checklist

Self-review runs on every review invocation. No exceptions.

```
[ ] Does this do what was asked?
    → Re-read .superharness/spec.md. Compare each requirement to what was built.
[ ] Are there gaps between spec and implementation?
    → List every feature in the spec. Verify each one exists and works.
[ ] Run tests — do they pass?
    → Only if engineering plan has testing.strategy != none.
    → Run the ACTUAL test command. Paste the output.
[ ] Run the app — does it work?
    → Basic smoke check. Boot it. Try the primary flow.
[ ] Read the diff — anything surprising?
    → Run `git diff` on all changes. Look for debug statements,
      hardcoded secrets, TODO comments, leftover console.log.
[ ] Check for security issues
    → Only if risk_profile is medium or high.
    → Look for: exposed secrets, SQL injection, XSS, missing auth checks,
      insecure defaults, hardcoded credentials.
```

### Self-review decision table

| Check | Condition | Action if fails |
|---|---|---|
| Spec match | Feature missing or wrong | Fix before proceeding |
| Tests pass | `testing.strategy != none` | Fix failing tests |
| App runs | Always | Fix startup errors |
| Diff clean | Always | Remove debug artifacts |
| Security | `risk_profile: medium\|high` | Fix security issues before any external review |

## Agent Review Dispatch

When `code_review.agent_review: true` in the engineering plan, dispatch the code-reviewer agent.

### What to provide the agent

```
Context package for code-reviewer:
1. Changed files     → git diff --name-only against the base branch
2. Full diff         → git diff against the base branch
3. Engineering plan  → .superharness/engineering-plan.json (conventions, architecture, testing)
4. Spec requirements → .superharness/spec.md (what was supposed to be built)
5. Scope summary     → One paragraph: what changed and why
```

### Processing agent feedback

| Severity | Meaning | Action |
|---|---|---|
| Critical | Bug, security hole, data loss risk | Must fix before proceeding. No exceptions. |
| Important | Code smell, maintainability concern, missing edge case | Should fix. Skip only with documented justification. |
| Suggestion | Style preference, alternative approach, minor improvement | Optional. Apply if quick, skip if not. |

```
For each piece of feedback:
1. Read the feedback carefully
2. Classify: Critical / Important / Suggestion
3. If Critical or Important → make the fix, re-run tests
4. If Suggestion → apply if < 2 minutes, otherwise note and move on
5. After all fixes → re-run self-review checklist
```

## Human Review Workflow

When `code_review.human_review: true`, create a pull request for human review.

### PR description format

```
## What changed
[1-3 bullet points describing what was built or fixed]

## Why
[Link to the spec requirement or user request that motivated this]

## How to test
[Step-by-step instructions a reviewer can follow to verify the change]

## Evidence
[Paste actual test output, screenshot references, or smoke test results]
```

### Processing human feedback

Use the receiving-code-review approach:

```
1. Read every comment. Do not skim.
2. Assume the reviewer has context you lack.
3. For each comment:
   a. If it's a question → answer with evidence (code reference, test output)
   b. If it's a change request → make the change, commit, push
   c. If you disagree → explain your reasoning, but defer to the reviewer
4. After addressing all comments → re-run the verification gate
5. Request re-review
```

## Branch Management

Branch strategy is dictated by the engineering plan. Do not invent your own.

### By `git.branching_strategy`

| Strategy | Workflow |
|---|---|
| `feature_branches` | Create branch from main → commit on branch → PR → merge → delete branch |
| `trunk` | Commit directly to main. No branches. No PRs. |

### Feature branch workflow

```
1. Create branch:  git checkout -b feat/<feature-name>
2. Commit work on the branch (small, atomic commits)
3. Push:           git push -u origin feat/<feature-name>
4. Create PR (if human_review: true)
5. After merge:    git checkout main && git pull
6. Cleanup:        git branch -d feat/<feature-name>
```

### Trunk-based workflow

```
1. Commit directly to main
2. No branches, no PRs
3. Each commit must be a working increment — never commit broken code
```

### Worktree guidance

If `git.use_worktrees: true`: use git worktrees for parallel feature work. Each worktree gets its own directory but shares git history. Clean up after merge: `git worktree remove <path> && git branch -d <branch>`.

## Verification Gate

Before claiming ANY work is complete, run the verification gate. This is mandatory.

```
Step 1: Run ALL test commands fresh
        → Do not trust remembered output. Run them NOW.
        → Paste the actual output into your response.

Step 2: Run the application
        → Boot it. Verify the primary flow works.
        → If it's a CLI, run the main command.
        → If it's a web app, confirm it loads.

Step 3: Check for regressions
        → Did fixing one thing break another?
        → Run the full test suite, not just the tests you changed.

Step 4: Verify against the spec
        → Re-read .superharness/spec.md one final time.
        → Confirm every requirement is met.
```

### Evidence format

```
Always show evidence like this:

$ npm test
  PASS  src/auth.test.js (3 tests)
  PASS  src/api.test.js (7 tests)
  Test Suites: 2 passed, 2 total
  Tests:       10 passed, 10 total

Not like this:

"Tests pass." ← UNACCEPTABLE. No evidence. No trust.
```

### If tests fail

Do NOT declare done. Read the failure output. Fix the issue. Re-run the FULL test suite. Only proceed when ALL tests pass with fresh output.

## Anti-Patterns

| Anti-pattern | Why it's wrong | What to do instead |
|---|---|---|
| Claiming "done" without running tests | No evidence = no confidence. Tests may have regressed. | Run tests fresh. Paste the output. |
| Trusting remembered test results | Memory is unreliable. Code may have changed since last run. | Always run fresh. Always paste output. |
| Skipping review when the plan requires it | Violates the engineering contract the user approved. | Follow `code_review` settings precisely. |
| Creating PRs for trunk-based projects | Adds unnecessary process. The plan chose trunk for a reason. | Commit to main. No branches. No PRs. |
| Merging without all checks passing | Ships broken code. Breaks trust with the team. | Wait for green CI. Fix failures first. |
| Dismissing agent feedback without reading | Misses real bugs. Defeats the purpose of agent review. | Read every finding. Classify. Act on Critical/Important. |
| Self-reviewing by re-reading your own code | Confirmation bias — you'll see what you expect to see. | Use the checklist. Run commands. Compare to spec. |
| Skipping security review on high-risk projects | Exposes users to vulnerabilities. | Check security when risk_profile is medium or high. |

## Red Flags — STOP

If you catch yourself:

- **Saying "tests pass" without pasting test output** — STOP. Run them. Show the evidence.
- **Declaring a feature complete without re-reading the spec** — STOP. Spec is the source of truth.
- **Skipping agent review when the plan requires it** — STOP. Dispatch the code-reviewer agent.
- **Merging a PR with failing checks** — STOP. Fix the failures first.
- **Creating a branch on a trunk-based project** — STOP. Check `git.branching_strategy`.
- **Pushing directly to main on a feature-branch project** — STOP. Create a branch and PR.
- **Approving your own work without running the verification gate** — STOP. Evidence before claims.
- **Fixing code during human review without committing** — STOP. Every fix gets its own commit.

**STOP. Return to the verification gate. Run the commands. Show the evidence.**

## Integration References

| Situation | Skill to invoke | Why |
|---|---|---|
| Review reveals missing features | `superharness:build` | Build what's missing, then re-review |
| Review reveals bugs | `superharness:debug` | Structured debugging for issues review uncovered |
| Review passes, needs QA validation | `superharness:qa` | User-experience validation after code review |
| Spec is unclear during review | `superharness:kickoff` | Clarify requirements before verifying against them |
| Review complete, all gates pass | `superharness:orchestrator` | Return control to orchestrator for next action |
