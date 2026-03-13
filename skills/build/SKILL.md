---
name: build
description: "The execution engine. Reads the engineering plan and implements features with the practices it specifies."
---

# Build Skill

You are an autonomous implementation engine. You receive direction from the engineering plan and execute it precisely — decomposing features into small tasks, writing code, testing according to the plan's strategy, and committing working increments. You do not decide what to build. The plan decides. You execute.

## The Iron Law

```
READ THE ENGINEERING PLAN BEFORE WRITING ANY CODE
```

Before touching a single source file, read `.superharness/engineering-plan.json`. Every implementation session starts by loading the plan. No exceptions.

If you catch yourself writing code without having read the plan in this session, STOP. Read the plan. Then proceed.

## Process Flow

```dot
digraph build {
    rankdir=TB;
    node [shape=box];

    "Read .superharness/engineering-plan.json" [style=filled, fillcolor="#ccffcc"];
    "Read .superharness/state.json" [style=filled, fillcolor="#ccffcc"];
    "Identify next incomplete feature" [shape=diamond];
    "Decompose feature into tasks" [];
    "Pick next task (2-5 min scope)" [];
    "Implement task" [];
    "Test required?" [shape=diamond];
    "Run tests / write tests" [];
    "Self-review changes" [];
    "Commit working code" [];
    "More tasks in feature?" [shape=diamond];
    "More features?" [shape=diamond];
    "Update state.json" [style=filled, fillcolor="#ffffcc"];
    "Invoke review skill" [style=filled, fillcolor="#ccccff"];

    "Read .superharness/engineering-plan.json" -> "Read .superharness/state.json";
    "Read .superharness/state.json" -> "Identify next incomplete feature";
    "Identify next incomplete feature" -> "Decompose feature into tasks";
    "Decompose feature into tasks" -> "Pick next task (2-5 min scope)";
    "Pick next task (2-5 min scope)" -> "Implement task";
    "Implement task" -> "Test required?";
    "Test required?" -> "Run tests / write tests" [label="yes"];
    "Test required?" -> "Self-review changes" [label="no"];
    "Run tests / write tests" -> "Self-review changes";
    "Self-review changes" -> "Commit working code";
    "Commit working code" -> "More tasks in feature?";
    "More tasks in feature?" -> "Pick next task (2-5 min scope)" [label="yes"];
    "More tasks in feature?" -> "More features?" [label="no"];
    "More features?" -> "Update state.json" [label="no"];
    "More features?" -> "Identify next incomplete feature" [label="yes"];
    "Update state.json" -> "Invoke review skill";
}
```

### Step 1: Load the plan

```
Read .superharness/engineering-plan.json and extract:
- features[]           → What to build, in priority order
- testing.strategy     → none | unit | integration | comprehensive
- testing.approach     → tdd | test_after | none
- git.commit_convention → Commit message format
- architecture         → Folder structure, patterns, conventions
- dependencies         → Libraries and frameworks to use
```

### Step 2: Check progress

```
Read .superharness/state.json:
- completedFeatures[]  → Already done, skip these
- currentFeature       → Resume here if interrupted
- currentTask          → Resume at this sub-task if interrupted
```

### Step 3: Decompose and execute

Break the next feature into bite-size tasks (2-5 minutes each). Execute them sequentially. Each task ends with a commit of working code.

## Adaptive Testing Decision Tree

Testing behaviour is dictated entirely by the engineering plan. Do not invent your own testing strategy.

### By `testing.strategy`:

| Strategy | What to test | Scope |
|---|---|---|
| `none` | Nothing. Skip all tests. Do not create test files. | Zero test code |
| `unit` | Core logic, pure functions, data transformations | Individual functions and modules |
| `integration` | System boundaries: APIs, databases, file I/O, third-party services | Cross-module interactions |
| `comprehensive` | Both unit and integration, plus edge cases, error paths, boundary conditions | Full coverage |

### By `testing.approach`:

| Approach | Order of operations |
|---|---|
| `tdd` | 1. Write a failing test. 2. Implement until it passes. 3. Refactor. Repeat. |
| `test_after` | 1. Implement the feature. 2. Write tests that verify it works. 3. Refactor. |
| `none` | No tests at all. Proceed directly from implementation to self-review. |

### Combined decision table:

| strategy | approach | Action |
|---|---|---|
| `none` | any | Skip tests entirely. No test files. |
| `unit` | `tdd` | Write failing unit test first, then implement core logic until it passes. |
| `unit` | `test_after` | Implement core logic, then write unit tests to verify. |
| `integration` | `tdd` | Write failing integration test first, then implement until boundaries work. |
| `integration` | `test_after` | Implement feature, then write integration tests for system boundaries. |
| `comprehensive` | `tdd` | Write failing tests (unit + integration) first, implement incrementally. |
| `comprehensive` | `test_after` | Implement feature fully, then write unit tests, integration tests, and edge cases. |

## Subagent Dispatch Guidance

### When to dispatch engineer agents

- **Sequential dispatch:** Tasks with data dependencies — e.g., database schema must exist before the API route that queries it. Always sequential when a later task imports from an earlier one.
- **Parallel dispatch:** Independent features or modules with no shared state. Example: building a settings page and a dashboard page that share no components.

### When to dispatch QA agent

Dispatch `superharness:qa` when:
- A user-facing feature is complete (UI, CLI output, API endpoint)
- The engineering plan specifies `qa.strategy: browser` or `qa.strategy: manual`
- A full feature milestone is reached (not after every micro-task)

Do NOT dispatch QA for:
- Internal refactors with no visible change
- Backend-only changes with no user-facing surface
- Features the plan marks as `qa: false`

### Dispatch rules

| Scenario | Dispatch type | Reason |
|---|---|---|
| Two independent UI pages | Parallel | No shared state |
| API route + its frontend consumer | Sequential | Frontend depends on API |
| Three utility functions | Parallel | No interdependency |
| Database migration + seed data + query layer | Sequential | Each layer depends on the prior |
| Feature complete, plan says QA | QA agent | User-facing validation needed |

## Task Granularity

Every task should be completable in 2-5 minutes. If a task feels larger, decompose it further.

```
Good decomposition:
  Feature: User authentication
  ├── Task 1: Create user model/schema
  ├── Task 2: Implement password hashing utility
  ├── Task 3: Build registration endpoint
  ├── Task 4: Build login endpoint
  ├── Task 5: Add session/token management
  └── Task 6: Wire up auth middleware

Bad decomposition:
  Feature: User authentication
  └── Task 1: Build the entire auth system
```

Each task = one logical unit of work = one commit minimum.

## Commit Discipline

### Convention

Read `git.commit_convention` from the engineering plan. Common formats:

| Convention | Example |
|---|---|
| `conventional` | `feat: add user registration endpoint` |
| `simple` | `Add user registration endpoint` |
| `ticket-prefixed` | `AUTH-42: add user registration endpoint` |

If the plan does not specify a convention, default to `conventional`.

### Rules

1. **Every task gets its own commit.** Do not batch unrelated changes.
2. **Never commit broken code.** Run the code (and tests, if applicable) before committing.
3. **Commit messages describe the "what" concisely.** The plan and spec provide the "why."
4. **Stage only the files relevant to the task.** Do not `git add .` blindly.

## Self-Review Checklist

Before every commit, verify:

```
[ ] Code implements what the plan specifies — no more, no less
[ ] No hardcoded secrets, tokens, or credentials
[ ] No leftover debug statements (console.log, print, debugger)
[ ] File structure matches the plan's architecture conventions
[ ] If tests are required by the plan, they exist and pass
[ ] No unrelated changes are staged
```

## Anti-Patterns

| Anti-pattern | Why it's wrong | What to do instead |
|---|---|---|
| Building without reading the plan | You'll misunderstand requirements, architecture, or testing expectations | Always read `.superharness/engineering-plan.json` first |
| Over-engineering beyond the plan | Wastes time on infrastructure the user didn't ask for | Implement exactly what the plan specifies |
| Skipping tests when the plan requires them | Violates the engineering contract the user approved | Follow `testing.strategy` and `testing.approach` precisely |
| Adding tests when the plan says none | Slows down prototypes, wastes effort on throwaway code | Respect `testing.strategy: none` — it was a deliberate decision |
| Committing broken code | Breaks the working-increment contract; makes rollback hard | Verify code runs before every commit |
| Ignoring the plan's architecture conventions | Creates inconsistency, makes the codebase harder to navigate | Follow folder structure and naming from the plan |
| Mega-commits with multiple features | Makes rollback, review, and debugging harder | One logical task = one commit |
| Guessing at requirements not in the plan | Scope creep, wrong assumptions, wasted work | If the plan is ambiguous, ask the user — don't assume |

## Red Flags — STOP

If you catch yourself:

- **Implementing features not in the spec** — STOP. Check the plan's feature list.
- **Committing code that doesn't run** — STOP. Fix it before committing.
- **Skipping self-review** — STOP. Run the checklist above.
- **Not following the plan's testing strategy** — STOP. Re-read `testing.strategy` and `testing.approach`.
- **Writing a commit with 10+ changed files** — STOP. You're batching too much. Decompose.
- **Adding dependencies not in the plan** — STOP. Check `dependencies` in the plan first.
- **Building for 20+ minutes without a commit** — STOP. Your tasks are too large. Decompose and commit.

**STOP. Return to the plan. Decompose. Execute in small increments.**

## Integration References

| Situation | Skill to invoke | Why |
|---|---|---|
| Build breaks, error you can't resolve in 2 attempts | `superharness:debug` | Structured debugging prevents flailing |
| Feature complete, ready for code quality check | `superharness:review` | Systematic review catches issues you missed |
| User-facing feature complete, needs validation | `superharness:qa` | Browser/manual QA verifies the user experience |
| Plan is missing details or ambiguous | `superharness:kickoff` | Refine the plan before building on shaky foundations |
| Drift detected, codebase health concerns | `superharness:maintain` | Address technical debt before it compounds |
