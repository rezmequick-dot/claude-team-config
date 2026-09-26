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
- A PR is required for every feature delivery. ADO work items must not be closed until the feature is confirmed live in production. The **deploy pipeline owns that close** — it transitions the item once the commit carrying its `AB#NNN` is live — so an item closed by hand means the automation did not see it, not that the rule needs a human.
- **Merging to `main` IS the production deploy** on any repo whose pipeline triggers on merge. The pipeline ships with no further prompt, so the merge click is the approval and there is no second gate behind it. Stating the rule as "no deploy without approval" describes a checkpoint that does not exist; state it where the decision is actually made:
  - **No agent may merge to `main` without explicit Stakeholder approval in that session.** Prior session approval does not carry over. This is the old no-deploy-without-approval rule, relocated to the point where it bites.
  - Automation may merge only within a class the Stakeholder approved in advance, and only on evidence that actually ran. Anything touching auth, payments, PII, schema, or migrations is never in an auto-merge class, regardless of how a reviewer scored it.
  - A production-migrations environment approval stays a human gate. It is the one step a merge does not already imply.
- **Check whether branch protection is actually available** before trusting PR checks to gate anything. On a private repo on a free plan the protection API returns 403, GitHub does not enforce the checks, a red PR is mergeable, and merging it deploys it. Any automation that merges must assert the check rollup itself rather than assume the platform blocked it.

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

## Token and Secret Handling

Credentials have had to be rotated repeatedly because they keep landing in files written by
tooling — not because they expired. Rotation resets the clock; it never touches the writer.
These rules target the writer.

**1. One store. Config files hold references, never values.**
Secrets live in the login keychain. A LaunchAgent plist, `.env`, or shell profile may name a
credential; it must never contain one. Known-good today: the ADO PAT at keychain service
`copilot-ado-loop-ado-pat`, and Claude Code's own credentials at `Claude Code-credentials`.
Retrieve the GitHub bot token with `gh auth token --user <login>` — **not** by reading the
keychain directly, which returns a 74-char `go-k…` wrapper that is not the token and will
401. Always verify a credential against its API before concluding an identity is broken.

**2. Every file-writing path is a leak path.**
The real vectors have been backups, log rotation, and serializers — never the original
config. When adding code that writes a file, ask what could be in it:
- Serialize **named fields**, never a whole config object. `config.ado` spread into a log
  record leaked a PAT on every daemon start; the same object printed by a CLI command
  bypassed logger redaction entirely. Redact at the serialization boundary, not in the logger.
- Set the mode **at creation**. `createWriteStream`/`writeFile` without `mode` yields
  `0666 & ~umask` = 0644. Log rotation did this and produced a world-readable archive beside
  0600 logs.
- Backups inherit whatever the original held. If a file could contain a secret, its `.bak`
  does too.

**3. Detect by shape, never by key name.**
A sweep for one variable name (`grep AZURE_DEVOPS_EXT_PAT …`) missed a live
`CLAUDE_CODE_OAUTH_TOKEN` sitting world-readable for seven weeks, in the same directory.
Match **patterns** — `sk-ant-`, `gh[pousr]_`, `github_pat_`, and any env key ending
`TOKEN|PAT|PASSWORD|SECRET` whose value is non-empty and not a placeholder — across **every**
file, including ones that fail to parse. A parser-only scan skips malformed files silently;
fall back to raw text. Beware `grep -c … || echo 0`, which emits `"0\n0"` and compares
unequal to `"0"`, reporting every file as a leak.

**4. Scope and lifetime over rotation cadence.**
Prefer the narrowest scope that works — the ADO auth preflight deliberately probes work items
so a Work-Items-only PAT passes startup. Rotate on **exposure**, not on a calendar; if
exposure stops, the cadence drops on its own.

**5. Never print a secret while investigating one.**
Report length, prefix, and a hash prefix — never the value. `copilot-ado-loop status` prints
the ADO PAT to stdout, so running it during diagnosis puts the secret in your own transcript.

**6. Never grep a credential-bearing file by structure. Select named keys.**
Rule 5 is not enough, because the worst case is not an agent handling a secret — it is one
that has no idea a secret is nearby. On 2026-07-28 a session tracing which repo the loop
targeted ran, against the live LaunchAgent plist:

```bash
grep -iE "workspace/turnoverly|TARGET|REPO|ProgramArguments|<string>" "$PL"
```

`<string>` matches **every value in a plist**. The plist held `CLAUDE_CODE_OAUTH_TOKEN`, so
the token printed, and Claude Code persisted the tool result to `~/.claude/projects/…jsonl`,
where it sat for eight weeks. The same day, a *different* session had been scrupulous with
that token — it refused to touch it and reported only prefix and length. One broad pattern
undid that.

So: when reading any file that could hold a credential (plists, `.env`, config, logs), match
**named keys you actually want**, never structure — no `<string>`, no bare `.*`, no
whole-line, no "dump it and eyeball it". Prefer a typed reader over grep:
`plutil -extract EnvironmentVariables.FOO raw`, `jq '.foo'`. Pipe through a redactor if the
output could be wide. And assume **tool output is persisted**: anything printed lands in a
transcript on disk and outlives the session that printed it.

## Claude Config Repo Sync
Canonical config source: https://github.com/rezmequick-dot/claude-team-config (Mac: `~/Documents/workspace/claude-team-config`).

Covers: `~/.claude/CLAUDE.md`, `~/.claude/agents/*.md`, `~/.claude/commands/*.md`,
`~/.claude/hooks/*.sh`.

Hooks additionally need registering in `~/.claude/settings.json` under `hooks.PreToolUse`;
that file is NOT vendored here (it holds machine-specific MCP config and permissions), so
copying a hook script across is not enough on its own — see `hooks/README.md`.

**The two copies diverge on purpose. Never blind-copy in either direction.**
`~/.claude` is the machine- and project-specific working copy; the repo holds the **sanitised,
portable** version of the same file. Verified 2026-09-23: the repo's `nr.md` reads
`NEW_RELIC_ACCOUNT_ID` and `$APP_NAME` from the environment where the local one hardcodes a
real account id and application name; the repo's `epic-dev.md` carries no org/project URLs at
all where the local one has concrete ones in four API paths; `deploy.md` and
`observability-engineer.md` differ the same way. Every differing file has content on **both**
sides, so `cp` in either direction destroys work — copying repo→local would replace your
project configuration with placeholders while "following the rules".

Port changes **field by field**, keeping each side in its own idiom: concrete values locally,
`{ADO_ORG}`/`{ADO_PROJECT}`/env-var placeholders in the repo. Before touching a vendored file,
`diff` it against its local twin and read what diverges — the difference is usually deliberate.
Never vendor a real account id, org, project or hostname.

When a file is modified locally: port the change (not the file) to the repo, branch
`improve/<description>` or `fix/<description>`, commit, push, open a PR via `gh pr create`.
When the repo is updated: port back the same way, and copy wholesale **only** for files that
are genuinely identical — `CLAUDE.md` is the one that reliably is. Do this at the end of any
session where config changed.

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
