# Global Claude Code Instructions

## Languages & Stack
- Primary language: TypeScript/JavaScript (Node.js, React, Next.js, etc.)

## Git Behavior
- **Batch all changes into a single commit at the very end of the feature — never commit mid-task.** The pre-commit hook is slow (full build + tests); committing once minimises the cost.
- Always ask before pushing to remote.
- Never force push unless explicitly requested.
- Never skip hooks (--no-verify) unless explicitly asked.
- Prefer creating new commits over amending existing ones.

## Code Style
- Add comments to explain non-obvious logic, edge cases, and intent.
- Do not add comments to self-evident code.
- Do not add docstrings or JSDoc to code I didn't change.
- Keep solutions simple — avoid over-engineering or premature abstraction.

## Response Style
- Provide detailed explanations and reasoning when making changes.
- Explain the "why" behind decisions, not just the "what".
- When referencing code, include file path and line number.

## Stakeholder
- The user is the **Product Stakeholder and owner** at all times. All agents treat requirements as final — no agent expands scope or overrides priorities without explicit approval.
- The `project-manager` must ask about **plan/tier gating** and **rate limits** for any new feature before engineering begins.
- The `devops-engineer` must present cost estimates and receive approval before provisioning any paid infrastructure.
- **Feature delivery pipeline order:** Performance → Security → UI/UX Review → QA → Accessibility → Observability → Documentation → PR → Address PR Comments → Deploy
- A PR is required for every feature delivery. ADO work items must not be closed until the feature is confirmed live in production.
- **No agent may deploy to production without explicit Stakeholder approval in that session.** Prior session approval does not carry over.

## Agent Action Attribution
Actions an agent takes on the Stakeholder's behalf must be **self-identifying**. Neither
platform distinguishes them automatically:

- **Azure DevOps** authenticates as the Stakeholder (AAD). `System.CreatedBy`, `ChangedBy`
  and `ActivatedBy` read "Jason Anthony" for agent writes too. There is no second ADO
  identity and no way to add one.
- **GitHub**: bare `gh` acts as `rezmequick-dot`. Only the commit trailer
  (`Co-authored-by: Claude Code`) and the commit author login reveal an agent wrote it.

**Never infer human action from ADO or GitHub attribution.** To establish who did something,
check commit authors and `Co-authored-by` trailers (`git log --format='%an|%ae'`,
`gh pr view N --json commits`). If those are unavailable, say the actor is indeterminate
rather than guessing. On 2026-09-13 an agent told the Stakeholder they had hand-authored
turnoverly spec PRs #767/#768 and moved two ADO tickets; the Stakeholder had touched none of
it — a prior agent session had, and platform attribution hid that.

Two of the three cases below are enforced by hooks in `hooks/` and need no effort. The third
cannot be automated and is a standing rule:

- **Structural ADO writes** — hyperlinks, state transitions, field and link changes — carry
  no comment and so leave no trace of the actor. Follow each with a short comment naming what
  changed and why. Backfilling the ADO-533/534 spec hyperlinks is the worked example: a
  silent structural write, indistinguishable from a Stakeholder edit.

Never run `gh auth switch`. The copilot-ado-loop daemon has no token of its own and resolves
the keyring's **active** account live on every spawn, so switching would silently change the
identity of automated work mid-cycle.

## Claude Config Repo Sync
Canonical config source: https://github.com/rezmequick-dot/claude-team-config (Mac: `~/Documents/workspace/claude-team-config`).

Covers: `~/.claude/CLAUDE.md`, `~/.claude/agents/*.md`, `~/.claude/commands/*.md`,
`~/.claude/hooks/*.sh`.

Hooks additionally need registering in `~/.claude/settings.json` under `hooks.PreToolUse`;
that file is NOT vendored here (it holds machine-specific MCP config and permissions), so
copying a hook script across is not enough on its own — see `hooks/README.md`.

When any of these are modified locally: copy to repo, create branch `improve/<description>`, commit, push, and open a PR via `gh pr create`. When the repo is updated: copy all files back to `~/.claude`. Do this at the end of any session where config changed.

## Semantic Code Search (CocoIndex MCP)
MCP server `cocoindex-search` provides: `index_project(path)`, `search_code(query, project_path?, limit?)`, `list_indexed_projects()`.
- Before using Glob or Grep on an indexed codebase, call `search_code` first. Fall back to Glob/Grep only if results are insufficient.
- If a new project directory is not yet indexed, offer to run `index_project`.
- Use `search_code` results to read only targeted file sections via `Read` with `offset`/`limit`.

## General Preferences
- Always read a file before editing it.
- Prefer editing existing files over creating new ones.
- Do not introduce features or refactors beyond what was asked.
- Do not use emojis unless explicitly requested.

## Session Start Behaviour
- At the start of every session, automatically check for CI/CD and infrastructure config files (.github/workflows/, Dockerfile, docker-compose.yml, terraform/, sst.config.ts, etc.)
- If any are found, invoke the `devops-engineer` agent to silently audit the pipeline and report findings ranked by severity
- This is an audit only — no changes are made without Stakeholder approval
- If no CI/CD files are present, skip silently

## Subagent Strategy
- Use subagents to keep the main context window clean; offload research, exploration, and parallel analysis
- One task per subagent for focused execution
- Never ask a subagent to install packages — do it at the main agent level with the Bash tool
- Playwright browser tests must use the Playwright MCP server (configured globally), not `@playwright/test` npm installs
- If a subagent reports a permission block on install commands, handle the install in the main thread and resume

## Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately — don't keep pushing
- Write detailed specs upfront to reduce ambiguity

### 2. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Review lessons at session start for relevant project

### 3. Verification Before Done
- Never mark a task complete without proving it works
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 4. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- Skip this for simple, obvious fixes — don't over-engineer

### 5. Autonomous Bug Fixing
- When given a bug report: just fix it. Point at logs, errors, failing tests — then resolve them.

## Task Management
1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

## Core Principles
- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
