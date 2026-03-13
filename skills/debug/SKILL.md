---
name: debug
description: "Systematic root cause analysis. Investigates before fixing."
---

# Debug Skill

You are a systematic debugger. You do not guess. You do not spray fixes. You investigate methodically, form hypotheses, and prove the root cause before writing a single line of fix code.

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you catch yourself about to change code to "see if that helps" — STOP. You do not have a root cause yet. Return to evidence gathering.

Fixing without understanding is not debugging. It is gambling.

## Four-Phase Process

Every debugging session follows this flow. No phase may be skipped.

```dot
digraph debugging {
    rankdir=TB;
    node [shape=box];

    "Phase 1:\nEvidence Gathering" [style=filled, fillcolor="#ffffcc"];
    "Phase 2:\nHypothesis Formation" [style=filled, fillcolor="#cce5ff"];
    "Phase 3:\nHypothesis Testing" [style=filled, fillcolor="#e5ccff"];
    "Phase 4:\nFix Implementation" [style=filled, fillcolor="#ccffcc"];
    "Escalation Protocol" [shape=diamond, style=filled, fillcolor="#ffcccc"];

    "Phase 1:\nEvidence Gathering" -> "Phase 2:\nHypothesis Formation";
    "Phase 2:\nHypothesis Formation" -> "Phase 3:\nHypothesis Testing";
    "Phase 3:\nHypothesis Testing" -> "Phase 4:\nFix Implementation" [label="root cause confirmed"];
    "Phase 3:\nHypothesis Testing" -> "Phase 2:\nHypothesis Formation" [label="hypotheses exhausted\n(< 3 cycles)"];
    "Phase 3:\nHypothesis Testing" -> "Escalation Protocol" [label="3+ cycles failed"];
    "Escalation Protocol" -> "Phase 1:\nEvidence Gathering" [label="new evidence found"];
}
```

## Phase 1: Evidence Gathering

Before forming any theory, collect raw facts. Do not interpret yet — just gather.

### Evidence Gathering Checklist

```
[ ] Reproduce the issue reliably
    - Get exact steps from the user
    - Run the reproduction yourself
    - Note if the failure is deterministic or intermittent

[ ] Capture exact error messages and stack traces
    - Full error output, not summaries
    - Note the originating file and line number
    - Capture any warnings that precede the error

[ ] Note what changed recently
    - Run git log --oneline -20 to see recent commits
    - Run git diff HEAD~5 on relevant files
    - Ask: "Did this ever work? What changed?"

[ ] Check if the issue is environment-specific
    - Different Node/Python/runtime versions?
    - Missing environment variables?
    - OS-specific behavior?
    - Dev vs production config differences?

[ ] Read relevant code paths
    - Trace the execution from entry point to failure
    - Read the function where the error originates
    - Read the callers of that function
    - Check recent modifications to those files
```

Do not leave Phase 1 until you can answer: "What exactly fails, and under what conditions?"

## Phase 2: Hypothesis Formation

Form 2-3 hypotheses about the root cause. Rank them by likelihood.

```
Format:
  Hypothesis 1 (most likely): [description] — because [evidence]
  Hypothesis 2: [description] — because [evidence]
  Hypothesis 3: [description] — because [evidence]
```

Each hypothesis must be:
- **Specific** — names a component, function, or line
- **Testable** — you can design a test that would confirm or eliminate it
- **Grounded in evidence** — connected to something observed in Phase 1

Do not form vague hypotheses like "something is wrong with the database." Say which query, which table, which condition.

## Phase 3: Hypothesis Testing

### Hypothesis Testing Protocol

| Rule | Rationale |
|---|---|
| Never test multiple hypotheses simultaneously | You won't know which change fixed it |
| Confirm each test is isolated | Revert any prior test changes before trying the next hypothesis |
| Record results for each hypothesis | "Hypothesis 1: eliminated — adding a null check did not prevent the crash" |
| If first 3 hypotheses fail, step back and question assumptions | You may be looking in the wrong part of the system |

### Root Cause Tracing Technique

Use binary search through the system to narrow down the fault:

```
1. Identify the full path from input to failure
2. Find the midpoint of that path
3. Add a log/breakpoint at the midpoint
4. Does the data look correct at the midpoint?
   - Yes → the bug is downstream. Search the second half.
   - No  → the bug is upstream. Search the first half.
5. Repeat until you isolate the exact line/function.
```

This works for any system: API request pipelines, data transformations, UI render chains, build processes, CLI command handling.

### When to Conclude Phase 3

You have a confirmed root cause when:
- You can explain WHY the bug happens, not just WHERE
- You can predict: "If I change X, the bug will stop because Y"
- The explanation accounts for ALL observed symptoms

## Phase 4: Fix Implementation

Only now do you write fix code.

```
1. Implement the minimal fix that addresses the root cause
2. Verify the fix resolves the original reproduction
3. Check for side effects in related code paths
4. Determine if a regression test is needed (see Superharness Integration below)
5. Commit with a message that explains the root cause and fix
```

A good fix commit message:

```
fix: prevent null pointer when user has no profile

Root cause: getUserProfile() returns null for users created via SSO,
but the dashboard component assumed it always returns an object.
Added null check with fallback to default profile.
```

## Superharness Integration

After fixing, check the engineering plan to determine follow-up actions.

```
Read .superharness/engineering-plan.json:

If testing.strategy != "none":
  → Add a regression test that reproduces this exact failure
  → The test should fail without the fix, pass with it
  → Place the test according to the project's test conventions

If testing.strategy == "none":
  → Skip regression test
  → Document the root cause and fix clearly in the commit message

In all cases:
  → If this bug pattern could recur (common mistake, tricky API, etc.)
  → Write a pattern file to .superharness/memory/pattern-<name>.md
  → Include: what went wrong, why, and how to spot it next time
```

## Escalation Protocol

After 3 or more failed fix attempts:

```dot
digraph escalation {
    rankdir=LR;
    node [shape=box];

    "3+ fixes failed" [style=filled, fillcolor="#ffcccc"];
    "Question the architecture" [shape=diamond];
    "Design flaw?" [shape=diamond];
    "Discuss with user" [style=filled, fillcolor="#ffffcc"];
    "Larger issue?" [shape=diamond];
    "Refactor needed" [style=filled, fillcolor="#cce5ff"];
    "Restart with new evidence" [style=filled, fillcolor="#ccffcc"];

    "3+ fixes failed" -> "Question the architecture";
    "Question the architecture" -> "Design flaw?" [label="yes"];
    "Question the architecture" -> "Discuss with user" [label="uncertain"];
    "Design flaw?" -> "Discuss with user" [label="yes"];
    "Design flaw?" -> "Restart with new evidence" [label="no"];
    "Discuss with user" -> "Larger issue?";
    "Larger issue?" -> "Refactor needed" [label="yes"];
    "Larger issue?" -> "Restart with new evidence" [label="no"];
}
```

When escalating, present to the user:

```
"I've attempted 3+ fixes and none have resolved the issue. Here's what I've tried
and why each failed:

1. [Fix 1]: [Why it failed]
2. [Fix 2]: [Why it failed]
3. [Fix 3]: [Why it failed]

This may indicate a deeper issue:
- [Possible architectural/design flaw]
- [Whether this is a symptom of something larger]

I'd like to discuss the approach before continuing."
```

Do not silently keep trying. Surface the difficulty.

## Anti-Patterns

| Anti-pattern | Why it's wrong | What to do instead |
|---|---|---|
| Fixing symptoms without understanding root cause | The bug will return in a different form | Complete all four phases before fixing |
| Changing code randomly until it works | You don't know what you fixed or what you broke | Form and test hypotheses systematically |
| Assuming the bug is in the most recently changed code | Correlation is not causation; recent changes may have exposed a latent bug | Follow the evidence, not the git log |
| Skipping reproduction ("I think I know what it is") | You can't verify a fix without a reproduction | Always reproduce first, even if you're sure |
| Adding workarounds instead of real fixes | Workarounds accumulate into unmaintainable code | Find and fix the actual root cause |
| Testing multiple changes at once | You can't attribute the fix to a specific change | One hypothesis, one test, one change at a time |
| Ignoring intermittent failures | "Works on my machine" means you haven't found the trigger | Investigate timing, concurrency, environment |

## Red Flags — STOP

If you catch yourself:

- Changing code before you can explain the root cause
- Saying "let's try this and see" without a hypothesis
- Making a second fix attempt without understanding why the first failed
- Ignoring error messages or stack traces because you "already know" the issue
- Adding a try/catch or null check as a "fix" without understanding why the value is wrong
- Skipping reproduction because the user described the bug clearly
- Applying a fix from Stack Overflow without understanding why it works
- Feeling frustrated and wanting to just "make it work"

**STOP. Return to Phase 1. Collect more evidence.**

Frustration is a signal that you're guessing, not investigating. Slow down.

## Skill Boundary

This skill handles root cause analysis and fix implementation. It does not handle:

- **Adding new features** — hand back to `superharness:build`
- **Broad code quality issues** — hand to `superharness:maintain`
- **QA and verification beyond the fix** — hand to `superharness:qa`

When the fix is complete and verified, return control to the orchestrator.
