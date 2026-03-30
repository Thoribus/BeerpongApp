#

## Workflow Orchestration

### 1. Plan Mode Defaults

- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy

- Use subagents liberally to keep main control window clean
- Offload research, exploration and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-improvement loop

- After ANY correction from the user: update tasks/lessons.md with the pattern
- Write rules for yourself that prevents the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done

- Never mark a task complete without proving it works
- Diff behaviour between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)

- For non-trivial changes: pause and ask "is there a move elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes -- don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing

- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests --  then resolve them
- Zeor context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

1. Plan First: Write plan to tasks/todo.md with chechable items
2. Verify Plan: Check in before starting implementation
3. Track Progress: Mark items complete as you go
4. Explain Changes: High-level summary at each step
5. Document Results: Add review section to tasks/todo.md
6. Capture Lessons: Update tasks/lessons.md after corrections

## Commit Workflow

Each bug fix, suggestion, or feature gets its **own separate commit** immediately after it is complete and verified.

- Commit granularity: one logical change = one commit
- Commit message format: `<type>: <short description>`
  - `fix:` for bug fixes
  - `feat:` for new features or suggestions
  - `refactor:` for code restructuring without behaviour change
- Commit **as soon as** the change works — do not batch multiple changes into one commit
- This enables a clean per-item changelog when cutting a release

## Core Principles

- Simplicity First: Make every change as simple as possible. Impact minimal code.
- No Laziness: Find root causes. No temporary fixes. Senior developer standards.
- Minimal Impact: Only touch what's necessary. No side effects with new bugs.
