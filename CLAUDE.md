# Global Claude Code Instructions

## Languages & Stack
- Primary language: TypeScript/JavaScript (Node.js, React, Next.js, etc.)

## Git Behavior
- **Batch all changes into a single commit at the very end of the feature — never commit mid-task.** The pre-commit hook is slow (full build + tests); committing once minimises the cost.
- Always ask before pushing to remote.
- Never force push unless explicitly requested.
- Never skip hooks (--no-verify) unless explicitly asked.
- Prefer creating new commits over amending existing ones.

## GitHub PR Thread Resolution
- **Always use `gh api graphql` to resolve PR review threads — never Playwright or manual browser clicks.**
- Get unresolved thread node IDs (PRRT_...) via GraphQL query, then resolve each with the mutation:
  ```bash
  # Fetch unresolved thread IDs across all pages
  cursor=null
  unresolved='[]'

  while :; do
    page="$(
      gh api graphql \
        -F owner='<OWNER>' \
        -F repo='<REPO>' \
        -F number=<N> \
        -F cursor="$cursor" \
        -f query='
          query($owner: String!, $repo: String!, $number: Int!, $cursor: String) {
            repository(owner: $owner, name: $repo) {
              pullRequest(number: $number) {
                reviewThreads(first: 100, after: $cursor) {
                  nodes {
                    id
                    isResolved
                  }
                  pageInfo {
                    hasNextPage
                    endCursor
                  }
                }
              }
            }
          }'
    )"

    unresolved="$(
      jq -cn \
        --argjson existing "$unresolved" \
        --argjson page "$page" \
        '$existing + ($page.data.repository.pullRequest.reviewThreads.nodes | map(select(.isResolved == false) | .id))'
    )"

    has_next="$(jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage' <<<"$page")"
    if [ "$has_next" != "true" ]; then
      break
    fi

    cursor="$(jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor' <<<"$page")"
  done

  printf '%s\n' "$unresolved"
  # Resolve a thread
  gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "<THREAD_ID>"}) { thread { id isResolved } } }'
  ```
- Confirm each returns `isResolved: true`. Verify 0 unresolved threads remain before marking merge-ready.

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
- **Feature delivery pipeline order:** Performance → Security → UI/UX Review → QA → Accessibility → Observability → Documentation → PR → Deploy
- A PR is required for every feature delivery. Work items (ADO, Jira, Linear, GitHub Issues, etc.) must not be closed until the feature is confirmed live in production.
- **No agent may deploy to production without explicit Stakeholder approval in that session.** Prior session approval does not carry over.

## Claude Config Repo Sync
Canonical config source: https://github.com/<your-github-username>/claude-team-config (local clone: wherever you cloned it, e.g. `~/Documents/workspace/claude-team-config`).

Covers: `~/.claude/CLAUDE.md`, `~/.claude/agents/*.md`, `~/.claude/commands/*.md`.

When any of these are modified locally: copy to repo, create branch `improve/<description>`, commit, push, and open a PR via `gh pr create`. When the repo is updated: copy all files back to `~/.claude`. Do this at the end of any session where config changed.

## Semantic Code Search (Optional — CocoIndex MCP)
If the `cocoindex-search` MCP server is installed and configured, it provides: `index_project(path)`, `search_code(query, project_path?, limit?)`, `list_indexed_projects()`.
- Before using Glob or Grep on an indexed codebase, call `search_code` first. Fall back to Glob/Grep only if results are insufficient.
- If a new project directory is not yet indexed, offer to run `index_project`.
- Use `search_code` results to read only targeted file sections via `Read` with `offset`/`limit`.
- If `cocoindex-search` is not available, fall back to standard Glob/Grep/file reading tools.

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
