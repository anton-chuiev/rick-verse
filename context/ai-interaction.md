# AI Interaction Guidelines

## Communication

- Be concise and direct
- Explain non-obvious decisions briefly
- Ask before large refactors or architectural changes
- Don't add features not in the project spec
- Never delete files without clarification

## Workflow

This is the common workflow that we will use for every single feature/fix:

1. **Document** - Document the feature in @context/current-feature.md.
2. **Branch** - Create new branch for feature, fix, etc
3. **Implement** - Implement the feature/fix that I create in @context/current-feature.md
4. **Test** - Verify it works by building the project and fix any errors, then cover the feature's logic with unit tests (see Testing below).
5. **Iterate** - Iterate and change things if needed
6. **Commit** - Only after build passes and everything works
7. **Merge** - Merge to main
8. **Delete Branch** - Delete branch after merge
9. **Review** - Review AI-generated code periodically and on demand.
10. Mark as completed in @context/current-feature.md and add to history — keep the entry short (one sentence + max 2–3 bullets + a `Details:` link to the spec, per the format comment in that file's History section); full detail goes in `context/features/<name>-spec.md`, not the history.

Do NOT commit without permission and until the build passes. If build fails, fix the issues first.

## Branching

We will create a new branch for every feature/fix. Name branch **feature/[feature]** or **fix/[fix]**, etc. Ask to delete the branch once merged.

## Commits

- Ask before committing (don't auto-commit)
- Use conventional commit messages (feat:, fix:, chore:, etc.)
- Keep commits focused (one feature/fix per commit)
- Never put "Generated With Claude" in the commit messages

## Testing

Unit tests are part of a feature, not a follow-up. A feature isn't done until its logic is covered.

**What to test — logic, not wiring.** Cover view models (state transitions, race guarding, debounce, cancellation-vs-error), DTO → domain mapping, and repositories (especially where they absorb an API quirk, like a 404 meaning "no results"). Skip anything with no logic to protect: SwiftUI views, design tokens, coordinators without routing logic, and pass-through use cases. A test that only restates a constant or a one-line forward is noise.

**Mock at the protocol seam.** View models depend on repository (or use case) protocols; repositories depend on the `APIClient` protocol — mock those, never the network. Stub the API client with real wire JSON so DTO decoding is exercised too, rather than hand-building DTOs. If a seam doesn't exist yet, say so before adding one — don't reshape production code to suit a test without asking.

**Determinism is non-negotiable.** No network, no dependence on the wall clock. Drive timing through injected values (e.g. the debounce interval) and by releasing mocked calls explicitly — never by sleeping and hoping.

**Conventions.** Swift Testing (`@Test`, `#expect`). Tests mirror the app's layer-first structure under `Tests/`, with shared mocks in `Tests/Mocks/`. One behavior per test, named for the behavior rather than the method. Assert on observable state and recorded calls, never private internals.

**A test that resists being written cleanly is a finding about the production code.** Report it — don't contort the test around it, and don't silently "fix" the code.

## When Stuck

- If something isn't working after 2-3 attempts, stop and explain the issue
- Don't keep trying random fixes
- Ask for clarification if requirements are unclear

## Code Changes

- Make minimal changes to accomplish the task
- Don't refactor unrelated code unless asked
- Don't add "nice to have" features
- Preserve existing patterns in the codebase

## Code Review

Review AI-generated code periodically, especially for:

- Security (auth checks, input validation)
- Performance (unnecessary re-renders, N+1 queries)
- Logic errors (edge cases)
- Patterns (matches existing codebase?)



# General Rules

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.
