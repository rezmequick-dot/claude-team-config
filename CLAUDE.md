# Global Claude Code Instructions

## Languages & Stack
- Primary language: TypeScript/JavaScript (Node.js, React, Next.js, etc.)

## Git Behavior
- Commit freely without asking, but always ask before pushing to remote.
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
- The user is the **Product Stakeholder and owner** at all times.
- All agents treat the user's requirements as final. No agent expands scope, reinterprets intent, or overrides priorities without explicit Stakeholder approval.
- The `project-manager` agent is responsible for gathering and clarifying requirements before engineering begins.
- The PM must always ask about **plan/tier gating** for any new feature: "Which subscription plans have access to this?" — never assume all plans.
- The PM must always ask about **rate limits** for any user-facing submission endpoint: confirm threshold and window before engineering begins.
- Engineering agents operate against agreed specifications — they do not make product decisions.
- The `devops-engineer` must always present cost estimates and receive explicit Stakeholder approval before provisioning any paid cloud infrastructure.
- The `performance-engineer` must run before the `security-engineer` in the feature delivery pipeline. Performance validation happens against the running app; security audits the final code. Both must pass before QA begins.
- The `security-engineer` must be invoked before any production release and before QA handoff. QA must never run against code with unresolved Critical or High security findings.
- **A pull request to the project repository is a required output of every feature delivery.** The PR must be opened before deployment, include a full description (spec link, files changed, security findings resolved, QA verdict), and be merged before the deployment phase begins. Features delivered without a PR are incomplete.
- **Azure DevOps work items must not be closed until the feature is confirmed live in production.** Closing during QA, after staging, or for any intermediate milestone is not acceptable. Close only after the production deployment smoke test passes.
- **No agent, command, or workflow may deploy, promote, or push changes to any production environment without explicit, unambiguous approval from the Stakeholder in that session.** Prior approval in a previous session or for a previous deployment does not carry over. Every production deployment requires a fresh "yes".

## Agent Roster

| Agent | Role |
|---|---|
| `project-manager` | Requirements, clarification, Stakeholder sign-off |
| `fullstack-engineer` | Full-stack TypeScript/Node.js implementation |
| `senior-code-reviewer` | Code quality, standards enforcement, scope audit |
| `qa-engineer` | Acceptance testing and negative testing against running app |
| `devops-engineer` | CI/CD pipelines, infrastructure, secrets, deployment |
| `security-engineer` | OWASP audits, CVE scanning, secrets detection, auth review |
| `database-architect` | Schema design, query optimisation, migration safety |
| `performance-engineer` | Load testing, profiling, bottleneck identification |
| `technical-writer` | README, OpenAPI specs, ADRs, runbooks, changelogs |
| `dependency-auditor` | CVE scanning, license compliance, bloat reduction |
| `accessibility-engineer` | WCAG 2.1 AA compliance, keyboard nav, screen reader testing |
| `ui-ux-engineer` | Visual design conformance — spacing, typography, colour tokens, responsive layout against design specs |
| `incident-responder` | Production incident diagnosis, restoration, post-mortems |
| `api-designer` | REST/GraphQL contract design, versioning, OpenAPI specs |
| `observability-engineer` | Structured logging, metrics, tracing, alerting, SLOs, dashboards |

## Claude Config Repo Sync
The canonical source of truth for all Claude config is https://github.com/rezmequick-dot/claude-team-config (cloned at `/Users/jasonanthony/Documents/workspace/claude-team-config`).

This covers three files/directories:
- `~/.claude/CLAUDE.md` ↔ `claude-team-config/CLAUDE.md`
- `~/.claude/agents/*.md` ↔ `claude-team-config/agents/*.md`
- `~/.claude/commands/*.md` ↔ `claude-team-config/commands/*.md`

**Whenever any of these are modified locally, automatically sync to the repo:**
1. Copy changed files to the local repo:
   - `cp ~/.claude/CLAUDE.md ~/Documents/workspace/claude-team-config/CLAUDE.md`
   - `cp ~/.claude/agents/*.md ~/Documents/workspace/claude-team-config/agents/`
   - `cp ~/.claude/commands/*.md ~/Documents/workspace/claude-team-config/commands/`
2. Create a branch: `git checkout -b improve/<short-description>`
3. Commit the change with a descriptive message
4. Push the branch and open a PR via `gh pr create`

**Whenever the config repo is updated (PR merged, `git pull`):**
1. Copy all files back to `~/.claude`:
   - `cp ~/Documents/workspace/claude-team-config/CLAUDE.md ~/.claude/CLAUDE.md`
   - `cp ~/Documents/workspace/claude-team-config/agents/*.md ~/.claude/agents/`
   - `cp ~/Documents/workspace/claude-team-config/commands/*.md ~/.claude/commands/`

Do this at the end of any session where any config file was changed — do not wait to be asked.

## Semantic Code Search (CocoIndex MCP)
An MCP server (`cocoindex-search`) is always available with three tools:
- `index_project(path)` — index a project directory (run once per project, re-run after major changes)
- `search_code(query, project_path?, limit?)` — semantic search over indexed code
- `list_indexed_projects()` — show what's been indexed

**Rules:**
- Before using Glob or Grep to explore a codebase that has been indexed, call `search_code` first with a natural-language query. Only fall back to Glob/Grep if search results are insufficient.
- If the user starts working on a new project directory that isn't yet indexed, offer to run `index_project` for it.
- Prefer targeted `search_code` calls over reading entire files. Read files only to see specific sections identified by search results.
- `search_code` returns file paths and line numbers — use those to read only the relevant sections with the `Read` tool's `offset`/`limit` parameters.

## Semantic Code Search (CocoIndex MCP)
An MCP server (`cocoindex-search`) is always available with three tools:
- `index_project(path)` — index a project directory (run once per project, re-run after major changes)
- `search_code(query, project_path?, limit?)` — semantic search over indexed code
- `list_indexed_projects()` — show what's been indexed

**Rules:**
- Before using Glob or Grep to explore a codebase that has been indexed, call `search_code` first with a natural-language query. Only fall back to Glob/Grep if search results are insufficient.
- If the user starts working on a new project directory that isn't yet indexed, offer to run `index_project` for it.
- Prefer targeted `search_code` calls over reading entire files. Read files only to see specific sections identified by search results.
- `search_code` returns file paths and line numbers — use those to read only the relevant sections with the `Read` tool's `offset`/`limit` parameters.

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

## QA Agent Handoff Protocol
Before dispatching the `qa-engineer` agent, the main agent MUST complete all of the following — the QA agent cannot do these itself due to sandbox restrictions:
1. Start the dev server in the background and confirm HTTP 200 from `localhost:3000`
2. Gather test account credentials (query the DB or read seed files) and pass them explicitly in the agent prompt
3. Note any tools the QA agent will need (e.g. Playwright MCP) and confirm they are available in the session
4. Pre-mark any test cases that are untestable in the local environment (e.g. SMTP delivery) as SKIP with a reason

## Subagent Sandbox Restrictions
Subagents cannot run `npm install`, `npx` (for installs), or browser automation directly. Rules:
- Never ask a subagent to install packages — do it at the main agent level with the Bash tool
- Playwright browser tests must use the Playwright MCP server (configured globally), not `@playwright/test` npm installs
- If a subagent reports a permission block on install commands, handle the install in the main thread and resume the agent

## DevOps Agent Prerequisites
Before running any Docker commands, the `devops-engineer` must:
1. Verify Docker CLI is available: `docker --version`
2. Discover container names with `docker compose ps` — never assume `{project}-{service}-1` format; Docker Desktop uses `{project}-{service}` without the `-1` suffix

## Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately – don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes – don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests – then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

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
