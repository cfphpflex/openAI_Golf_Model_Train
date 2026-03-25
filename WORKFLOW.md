# Cursor Agent Workflow (gstack-style, Cursor-only)

Use this file as the operating process for feature delivery in any repo.

## How to use

At the start of each feature, tell the Cursor agent:

`Follow WORKFLOW.md strictly for this task.`

Then provide the project commands once:

- Build command: `<fill me>`
- Test command: `<fill me>`
- QA/E2E command (optional): `<fill me>`

## Phase 1: Ideation pass (no code)

Prompt:

```text
Act as product + staff engineer.
Goal: turn this request into the highest-value shippable version.
Output:
1) Problem framing
2) 2-3 scope options (small/medium/ambitious)
3) Recommended scope for this sprint
4) Acceptance criteria
5) Risks and unknowns
Do not write code yet.
```

## Phase 2: Design/architecture pass (no code)

Prompt:

```text
Given the accepted scope, design implementation plan:
- data flow
- modules/files to touch
- edge cases
- security/perf concerns
- test matrix (unit/integration/e2e)
Return a step-by-step implementation plan.
Do not code yet.
```

## Phase 3: Build pass (implementation)

Prompt:

```text
Implement the plan in small commits-in-spirit:
- make incremental code changes
- after each chunk, run project build/tests
- fix failures before moving on
- keep changes minimal and production-safe
```

## Phase 4: Review pass (bug/risk sweep)

Prompt:

```text
Do a strict code review of all changes:
- correctness bugs
- regressions
- missing tests
- risky assumptions
Fix high-confidence issues directly.
List remaining risks.
```

## Phase 5: QA pass (behavioral verification)

Prompt:

```text
Run QA checklist against acceptance criteria:
- happy path
- edge cases
- failure paths
- state recovery/retry
- performance sanity
For each failed check, fix + re-verify.
```

## Phase 6: Stabilization loop (repeat until stable)

Prompt:

```text
Stabilization cycle N:
1) run build/tests/qa checks
2) find top remaining defect
3) implement smallest safe fix
4) rerun checks
Stop only when all acceptance criteria pass and no known high/medium risks remain.
```

## Definition of Stable (all must be true)

- Build passes
- Full automated tests pass
- Acceptance criteria all verified
- No known high/medium severity defects
- Regression checks done for touched areas
- Logs/errors/console clean in core flows

## Low-cost, high-impact settings

- Use one implementation agent and one review agent (separate context reduces blind spots).
- Force short cycles: implement -> test -> fix.
- Ask for the smallest safe fix first.
- Require a residual risk list at the end of every cycle.
