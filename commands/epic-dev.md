---
description: Full-cycle Epic delivery — runs the complete feature-dev pipeline for every ticket in an ADO Epic, sequentially with Stakeholder approval between each
argument-hint: ADO Epic ID or comma-separated ticket IDs (e.g. "Epic #42" or "ADO #85, ADO #86, ADO #87")
---

# Epic Development Pipeline

You are orchestrating a full Epic delivery by running the complete feature-dev pipeline for each ticket in the Epic, one at a time, with Stakeholder approval between each. The user is the **Product Stakeholder and owner** — no phase proceeds without their approval.

Epic / tickets: $ARGUMENTS

---

## Phase E0: Epic Discovery & Planning

**Goal**: Establish the full ticket list, surface dependencies, and get Stakeholder approval on execution order before any engineering begins.

**Actions**:
1. Create a top-level todo list covering all Epic phases
2. **Fetch the ticket list**:
   - If $ARGUMENTS contains an Epic ID (e.g. "Epic #42"):
     - Query the ADO REST API to fetch all child work items of the Epic:
       - `GET https://dev.azure.com/applicationIngenuity/Sarah%20Sweeps/_apis/wit/workitems/{epicId}?$expand=relations&api-version=7.1`
       - For each child relation with `rel: "System.LinkTypes.Hierarchy-Forward"`, extract the work item ID
       - Fetch each child: `GET https://dev.azure.com/applicationIngenuity/Sarah%20Sweeps/_apis/wit/workitems/{id}?api-version=7.1`
       - Extract: ID, Title, State, Description, Acceptance Criteria (field `Microsoft.VSTS.Common.AcceptanceCriteria`)
     - Use the PAT from `.env` as `AZURE_DEVOPS_AUTH_TOKEN`, auth via `Buffer.from(':' + token).toString('base64')`
     - Use Node.js `https` module — do not shell out to curl
     - Log each HTTP status; if a fetch fails, warn and skip that ticket (do not block the whole Epic)
   - If $ARGUMENTS is a comma-separated list of ticket IDs (e.g. "ADO #85, ADO #86"):
     - Parse the IDs directly — no Epic fetch needed
     - Fetch each ticket's details as above to get Title, State, Description, Acceptance Criteria
3. **Present the full ticket list** to the Stakeholder:
   - Display: ID, Title, current State, one-line description
   - Flag any tickets already in state `Done` or `Closed` — ask the Stakeholder whether to skip them
   - Flag any tickets without Acceptance Criteria — these will require more PM work in Phase 0 of their feature-dev run
4. **Identify dependencies**:
   - Ask the Stakeholder: "Do any of these tickets depend on another being completed first? If so, which order should I use?"
   - Propose a default order (by priority field if available, otherwise by ID ascending)
5. **Confirm execution plan**:
   - Present the final ordered list with dependency notes
   - **Do not proceed until the Stakeholder explicitly approves the execution order**
6. Record the approved ordered list in the todo — this becomes the execution queue

---

## Phase E1–EN: Per-Ticket Feature Development

For each ticket in the approved execution queue, run the complete feature-dev pipeline. Execute tickets **sequentially** — do not start the next ticket until the current one is fully deployed and closed.

### For each ticket:

#### Step 1: Pre-flight check
- Confirm the previous ticket's production deployment smoke test passed (or this is the first ticket)
- Announce to the Stakeholder: "Starting ticket ADO #[ID]: [Title]. This is ticket [N] of [total]."
- Update the ticket state to `Active` in ADO:
  - `PATCH https://dev.azure.com/applicationIngenuity/Sarah%20Sweeps/_apis/wit/workitems/{id}?api-version=7.1`
  - Body: `[{"op":"add","path":"/fields/System.State","value":"Active"}]`
  - Content-Type: `application/json-patch+json`

#### Step 2: Run the full feature-dev pipeline (Phases 0–9)

Execute all phases as defined in the feature-dev command for this ticket:

**Phase 0 — Requirements & Contracts**
- Launch `project-manager` with the ticket's title, description, and acceptance criteria as the feature request
- If the feature introduces or changes API endpoints → launch `api-designer` in parallel
- If this is a new application → launch `devops-engineer` and `observability-engineer` in parallel
- Present all outputs to the Stakeholder for combined sign-off
- **Do not proceed until Stakeholder explicitly approves**

**Phase 1 — Codebase Exploration**
- Launch 2 `fullstack-engineer` agents in parallel:
  - Agent 1: Map architecture and identify 5–10 key files relevant to this ticket
  - Agent 2: Find similar existing features and trace their implementation end-to-end
- If the ticket involves data model changes → launch `database-architect` in parallel to review existing schema and migration patterns
- Read all identified files; present a findings summary

**Phase 2 — Architecture & Design**
- Launch 2 `fullstack-engineer` agents in parallel:
  - Agent 1: Minimal implementation design
  - Agent 2: Clean architecture design
- If data model changes → launch `database-architect` in parallel for schema design
- Present approaches, trade-offs, and recommendation to the Stakeholder
- **Do not begin implementation without explicit Stakeholder approval**

**Phase 3 — Implementation**
- Launch `fullstack-engineer` with: approved spec, API contract, architecture approach, schema design, key files, coding standards (strict TypeScript, tests for all new behaviour, ESLint-clean, no `any`, meaningful error handling)
- Read all modified files; update todos

**Phase 4 — Multi-Track Review**
- Launch in parallel:
  - Always: `senior-code-reviewer` — correctness, TypeScript strictness, architecture, test coverage, security surface, scope adherence
  - If new npm packages added: `dependency-auditor` — CVEs, license compatibility, correct dev/prod placement
  - If migrations written: `database-architect` — migration safety, zero-downtime, index strategy, rollback safety
- Consolidate findings by severity; present to Stakeholder
- Critical/standard violations → `fullstack-engineer` fixes → re-run affected reviewer(s) on changed files only

**Phase 5 — Security Audit**
- Launch `security-engineer`: OWASP Top 10, auth/authorisation correctness, input validation, secrets handling, new dependency CVEs, new API endpoints
- Critical/High → `fullstack-engineer` fixes → re-audit changed files
- Medium/Low → present to Stakeholder, ask fix-now or log as known issue
- **Do not proceed to QA with any unresolved Critical or High findings**

**Phase 6 — Specialised Validation**
- Launch in parallel as applicable:
  - Always: `qa-engineer`:
    - Gather test credentials with a single targeted DB query; pre-mark untestable criteria as SKIP
    - Prompt: "Start the dev server with `npm run dev` if not already responding at `http://localhost:3000`. Confirm HTTP 200 before any tests. Validate all acceptance criteria from the approved spec. Run full negative testing. Stop the dev server when done. Deliver PASS / FAIL / SKIP per criterion. Run Playwright tests using MCP tools directly — do NOT write spec files to disk. Use `page.evaluate()` for DOM/localStorage inspection. If a test fails, fix once and retry once — if it fails again mark FAIL and move on."
  - If UI changes: `accessibility-engineer` — WCAG 2.1 AA, axe-core via Playwright, keyboard navigation, focus management, ARIA
  - If performance-sensitive: `performance-engineer` — baseline, load test, bottleneck identification, budget comparison
- Fix loops: QA FAIL → `fullstack-engineer` fixes → `senior-code-reviewer` re-reviews → re-run failed QA checks
- **Do not proceed until QA verdict is PASS or CONDITIONAL PASS**

**Phase 7 — Observability**
- Launch `observability-engineer`: verify new endpoints have RED metrics, business events are logged, background jobs instrumented, external calls tracked, new failure modes have alerts
- Hand missing instrumentation to `fullstack-engineer`; confirm all code paths are observable

**Phase 8 — Documentation**
- Launch `technical-writer`: update/produce README (if setup changed), OpenAPI spec, ADR (if significant architectural decision), deployment runbook (if infra changed), API changelog (if public API changed)
- Review for accuracy; flag any [NEEDS VERIFICATION] items to the Stakeholder

**Phase 9 — Deployment**
- Open a Pull Request before deployment. PR must include: spec link, files changed, security findings resolved, QA verdict. The PR must be merged before deployment begins.
- Launch `devops-engineer`:
  - Prompt: "Feature has passed all reviews, QA, security, and documentation. Changed files: [list]. Review for new env vars, secrets, or infrastructure requirements. If paid resources are needed, present cost estimate to Stakeholder before acting. Deploy to staging, run smoke tests, report result. Do not deploy to production without explicit Stakeholder approval."
- If new infrastructure or secrets required: present cost estimate, **wait for explicit approval before provisioning**
- Confirm staging deployment is healthy; present result to Stakeholder
- **Request explicit production approval before deploying** — prior sessions do not carry over
- Confirm production deployment and smoke test result

#### Step 3: Post-ticket close-out
- **Only after production smoke test passes**: update ADO ticket state to `Done`
  - `PATCH https://dev.azure.com/applicationIngenuity/Sarah%20Sweeps/_apis/wit/workitems/{id}?api-version=7.1`
  - Body: `[{"op":"add","path":"/fields/System.State","value":"Done"}]`
- Record a one-line delivery summary for this ticket in the Epic summary table (ticket ID, title, files changed count, QA verdict, deployment status)
- Mark this ticket complete in the todo list
- **Ask the Stakeholder**: "Ticket ADO #[ID] is live in production. Ready to start the next ticket ([next ID]: [next title])? Or would you like to pause?"
- **Do not start the next ticket without explicit Stakeholder confirmation**

---

## Phase E-Final: Epic Summary

**Goal**: Deliver a complete Epic-level delivery record once all tickets are complete (or the Stakeholder has chosen to stop).

**Actions**:
1. Mark all todos complete
2. Deliver an Epic summary table:

| Ticket | Title | Status | Files Changed | QA | Deployed |
|--------|-------|--------|---------------|----|----------|
| #XX    | ...   | Done   | N             | PASS | Production |

3. Summarise:
   - **Total tickets delivered** vs planned
   - **Any tickets skipped** and why (pre-existing Done state, Stakeholder pause, etc.)
   - **Architectural decisions** made across the Epic (consolidated ADRs)
   - **New API surface** introduced
   - **Data model changes** (migrations run)
   - **Known deferred issues** logged across all tickets
   - **Monitoring recommendations** for the Epic as a whole
   - **Next steps** — follow-up Epics, backlog items surfaced during delivery
