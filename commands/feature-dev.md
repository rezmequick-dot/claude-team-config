---
description: Full-cycle feature development — requirements through production deployment using the full 14-agent team
argument-hint: Describe the feature to build
---

# Feature Development Pipeline

You are orchestrating a full-cycle feature development workflow using the complete agent team. The user is the **Product Stakeholder and owner** — no phase proceeds without their approval. No paid infrastructure is provisioned without explicit Stakeholder consent.

Agents involved: `project-manager`, `api-designer`, `fullstack-engineer`, `database-architect`, `senior-code-reviewer`, `dependency-auditor`, `security-engineer`, `qa-engineer`, `accessibility-engineer`, `performance-engineer`, `observability-engineer`, `technical-writer`, `devops-engineer`

Use TodoWrite to track all phases throughout.

---

## Phase 0: Requirements & Contracts

**Goal**: Produce a Stakeholder-approved spec and all technical contracts before any engineering begins.

Feature request: $ARGUMENTS

**Actions**:
1. Create a todo list covering all phases
2. Launch the `project-manager` agent:
   - Prompt: "The Stakeholder has requested: $ARGUMENTS. Explore the codebase for context, identify all ambiguities, ask clarifying questions, and produce a complete requirements spec with functional requirements and testable acceptance criteria."
3. From the approved spec, identify what contracts are needed. Launch in parallel as applicable:
   - **If the feature introduces or changes API endpoints** → launch `api-designer`:
     - Prompt: "Based on this spec: [spec], design the API contract. Produce endpoint definitions, request/response schemas, error responses, and a full OpenAPI 3.1 spec. Present for Stakeholder approval before implementation."
   - **If this is a new application** → launch `devops-engineer` and `observability-engineer` in parallel:
     - `devops-engineer`: "A new application is being planned. Requirements: [spec]. Propose deployment architecture options with cost estimates. Present only — do not provision anything."
     - `observability-engineer`: "A new application is being planned. Requirements: [spec]. Propose an observability stack (logging, metrics, tracing, alerting, dashboards) with cost estimates. Present options only — do not provision anything."
4. Present all outputs (PM spec + API contract + infra options + observability plan) to the Stakeholder for combined sign-off
5. **Do not proceed until the Stakeholder explicitly approves all contracts**

---

## Phase 1: Codebase Exploration

**Goal**: Build deep understanding of the existing codebase before touching anything.

**Actions**:
1. Launch 2 `fullstack-engineer` agents in parallel:
   - Agent 1: "Map the high-level architecture and identify patterns relevant to [feature]. Return a list of 5–10 key files."
   - Agent 2: "Find existing features similar to [feature] and trace their implementation end-to-end. Return a list of 5–10 key files."
2. If the feature involves data model changes, launch `database-architect` in parallel:
   - Prompt: "Review the existing schema and data access patterns relevant to [feature]. Identify current indexing strategy, existing migration patterns, and any constraints that affect the new feature's data design."
3. Read all files identified by agents
4. Present a summary of findings: architecture patterns, conventions, data model, integration points

---

## Phase 2: Architecture & Design

**Goal**: Produce a complete, agreed implementation design before writing any code.

**Actions**:
1. Launch 2 `fullstack-engineer` agents in parallel:
   - Agent 1: "Design a minimal implementation — smallest change, maximum reuse of existing patterns"
   - Agent 2: "Design a clean architecture — prioritise maintainability, proper separation of concerns, long-term extensibility"
2. If the feature involves data model changes, launch `database-architect` in parallel:
   - Prompt: "Design the schema changes required for [feature]. Include: table/column definitions, indexes, constraints, migration strategy, and zero-downtime considerations."
3. Review all designs against the approved spec
4. Present to the Stakeholder: approaches with trade-offs, recommendation with reasoning
5. **Do not begin implementation without explicit Stakeholder approval**

---

## Phase 3: Implementation

**Goal**: Build the feature to production standards on a dedicated feature branch.

**Actions**:
1. Create a feature branch: `git checkout -b feature/<short-description>` before any implementation begins
2. Launch the `fullstack-engineer` agent with:
   - The full approved spec (Phase 0)
   - The approved API contract / OpenAPI spec (Phase 0, if applicable)
   - The approved architecture approach (Phase 2)
   - The approved schema design (Phase 2, if applicable)
   - Key files and patterns from Phase 1
   - Standards: strict TypeScript, tests for all new behaviour, ESLint-clean, no `any`, meaningful error handling
3. Read all files modified by the agent
4. Update todos as implementation progresses

---

## Phase 4: Multi-Track Review

**Goal**: Audit the implementation across code quality, data, and dependencies in parallel.

**Actions**:
Launch the following agents in parallel, each with the list of changed files and the approved spec:

1. **Always** → `senior-code-reviewer`:
   - Prompt: "Review all changed files against the approved spec. Check: correctness, TypeScript strictness, architectural integrity, test coverage, performance issues, security surface, linting standards. Flag any implementation beyond the agreed spec scope."

2. **If new npm packages were added** → `dependency-auditor`:
   - Prompt: "Audit the newly added dependencies in package.json. Check for CVEs, license compatibility, whether lighter alternatives exist, and whether they are placed in the correct dependencies vs devDependencies."

3. **If database migrations or schema changes were written** → `database-architect`:
   - Prompt: "Review all migration files and schema changes. Check: migration safety, zero-downtime compatibility, index strategy, data integrity constraints, rollback safety."

Consolidate all findings by severity. Present to the Stakeholder. Fix loops:
- Critical/standard violations → `fullstack-engineer` fixes → re-run the relevant reviewer(s) on changed files only

---

## Phase 5: Performance Validation

**Goal**: Validate the feature under realistic load before security and QA — catching bottlenecks while the code is still easy to change.

**Actions**:
1. **If the feature is performance-sensitive** (high-traffic endpoint, data-heavy operation, new background job, new query path) → launch `performance-engineer`:
   - Prompt: "Profile the new feature under realistic load. Establish a baseline, run load tests against the locally running application, identify bottlenecks, and compare against the performance budget thresholds. Report any response time regressions or resource leaks."
2. Findings:
   - **Breach** — hand to `fullstack-engineer` or `database-architect` for optimisation, then re-test. Do not proceed until within budget.
   - **Pass** — proceed to security audit
3. If the feature is not performance-sensitive, skip this phase and proceed directly to Phase 6.

---

## Phase 6: Security Audit

**Goal**: Catch exploitable vulnerabilities before they reach QA or production.

**Actions**:
1. Launch the `security-engineer` agent:
   - Prompt: "Perform a security audit of all files changed in this feature. Check: OWASP Top 10 for the affected code paths, auth and authorisation correctness, input validation, secrets handling, new dependency CVEs, and any new API endpoints for injection or access control issues."
2. Findings by severity:
   - **Critical/High** — must be fixed before proceeding. Loop: `fullstack-engineer` fixes → re-audit changed files only.
   - **Medium/Low** — present to Stakeholder, ask whether to fix now or log as a known accepted risk
3. **Do not proceed to QA with any unresolved Critical or High findings**

---

## Phase 7: Specialised Validation

**Goal**: Validate the running application against acceptance criteria, accessibility requirements, and visual design conformance.

**Actions**:
Launch the following agents in parallel as applicable:

1. **Always** → `qa-engineer`:
   - Prompt: "Start the application locally. Validate all acceptance criteria from the approved spec. Run full negative testing. Deliver a structured test report with verdict."

2. **If the feature includes frontend/UI changes** → `accessibility-engineer`:
   - Prompt: "Audit the changed UI components and pages for WCAG 2.1 AA compliance. Run automated axe-core checks via Playwright. Check keyboard navigation, focus management, colour contrast, and ARIA usage."

3. **If the feature includes frontend/UI changes** → `ui-ux-engineer`:
   - Prompt: "Audit the changed pages and components for visual design conformance. Using Playwright, capture screenshots at mobile (375px), tablet (768px), and desktop (1280px) breakpoints. Check: spacing and padding consistency against established patterns in the codebase, typography scale, colour token usage, component alignment, and responsive layout behaviour. Reference the Tailwind config and existing components as the design baseline. Report deviations by severity with annotated screenshots where possible."

Consolidate all results. Fix loops:
- QA FAIL → `fullstack-engineer` fixes → `senior-code-reviewer` re-reviews changed files → `security-engineer` re-audits changed files → re-run failed QA checks
- Accessibility Critical → `fullstack-engineer` fixes → re-run accessibility audit on changed components
- UI/UX Critical (broken layout, missing spacing, wrong breakpoint behaviour) → `fullstack-engineer` fixes → re-run UI/UX audit on changed components

**Do not proceed to observability or deployment until QA verdict is PASS or CONDITIONAL PASS**

---

## Phase 8: Observability

**Goal**: Ensure the feature is fully visible in production before it ships.

**Actions**:
1. Launch the `observability-engineer` agent:
   - Prompt: "Review the feature implemented in [changed files]. Ensure it is fully observable in production. Check: are new endpoints covered by RED metrics? Are new business events logged at info level with required fields and correlation IDs? Are new background jobs instrumented? Are new external dependency calls tracked? Are new failure modes covered by alerts? Produce an instrumentation spec for anything missing and verify existing instrumentation is correct."
2. Hand any missing instrumentation to the `fullstack-engineer` to implement
3. Confirm all new code paths are observable before proceeding to documentation

---

## Phase 9: Documentation

**Goal**: Ensure the feature is fully documented before it ships.

**Actions**:
1. Launch the `technical-writer` agent:
   - Prompt: "Document the feature that was just implemented. Update or produce as applicable: README (if setup changed), OpenAPI spec (sync with implemented endpoints), ADR (if a significant architectural decision was made), deployment runbook (if infra changed), API changelog (if public API changed). Read the actual implementation — do not document assumptions."
2. Review documentation output for accuracy
3. Flag any [NEEDS VERIFICATION] items to the Stakeholder

---

## Phase 10: Deployment

**Goal**: Open a PR, merge it, and get the validated, documented feature deployed through the CI/CD pipeline.

**Actions**:
1. Create the pull request against the main branch:
   - Use `gh pr create` with a title and body that includes: what was built (linked to the Azure DevOps feature), files changed, API changes, data model changes, security findings resolved, QA verdict, and any known accepted risks
   - Assign reviewers if required by the project's merge policy
   - **The PR is a required output of every feature. Do not skip this step.**
2. Once the PR is approved and all CI checks pass, merge it
3. Launch the `devops-engineer` agent:
   - Prompt: "Feature has passed all reviews, performance validation, security audit, QA, and documentation. PR has been merged. Changed files: [list]. Review for new env vars, secrets, or infrastructure requirements. If paid resources are needed, present cost estimate to Stakeholder before acting. Deploy to staging, run smoke tests, report result. Do not deploy to production without explicit Stakeholder approval."
4. If new infrastructure or secrets are required:
   - Present cost estimate to the Stakeholder
   - **Wait for explicit approval before provisioning**
5. Confirm staging deployment is healthy
6. Present staging result to Stakeholder and ask for production approval
7. Confirm production deployment and smoke test result
8. **Only after confirmed production deployment**: update the corresponding Azure DevOps work items to Closed state. Do not close tickets during QA, after staging, or for any reason short of confirmed production deployment.

---

## Phase 11: Summary

**Goal**: Close out the workflow with a complete delivery record.

**Actions**:
1. Mark all todos complete
2. Deliver a final summary:
   - **What was built** — linked to approved spec
   - **Files changed** — created and modified with paths
   - **API changes** — new/changed endpoints, OpenAPI spec location
   - **Data model changes** — migrations run, schema changes
   - **Code review** — findings and resolutions
   - **Performance** — benchmark results (if tested), pass/breach status
   - **Security audit** — findings and resolutions
   - **QA verdict** — acceptance criteria results, negative test results
   - **Accessibility** — compliance status (if audited)
   - **Documentation** — what was written and where
   - **Pull request** — PR URL, merge status
   - **Deployment** — staging/production status, infrastructure changes, cost impact
   - **Azure DevOps** — work items closed (list IDs and titles)
   - **Next steps** — follow-up features, known deferred issues, monitoring recommendations
