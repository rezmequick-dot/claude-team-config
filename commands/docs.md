---
description: Generate or update project documentation using the technical-writer agent — README, OpenAPI specs, Architecture Decision Records, deployment runbooks, and API changelogs. Always reads the actual code before writing.
argument-hint: What to document — readme, openapi, adr, runbook, changelog, or all (default)
---

# Documentation

You are orchestrating documentation generation using the `technical-writer` agent. The user is the **Product Stakeholder and owner** — documentation reflects what was actually built, not what was assumed.

Use TodoWrite to track progress.

---

## Step 1: Define Scope

Documentation target: $ARGUMENTS

**Actions**:
1. Create a todo list
2. Determine what to produce:
   - `readme` — project README
   - `openapi` — OpenAPI 3.1 specification
   - `adr` — Architecture Decision Record for a specific decision
   - `runbook` — deployment and operations runbook
   - `changelog` — API changelog entry
   - Empty or `all` — assess what is missing and produce everything needed
3. Check what documentation already exists:
   - Read existing `README.md`, `docs/` directory, `CHANGELOG.md`
   - Identify what is stale, missing, or inaccurate
4. Collect context:
   - For ADRs: what decision was made and why?
   - For changelogs: what version and what changed?
   - For runbooks: what environments exist and what is the deploy process?
5. Ask the Stakeholder if there are specific sections they want prioritised

---

## Step 2: Launch Technical Writer

**Actions**:
1. Launch the `technical-writer` agent with a focused prompt:

   **README**:
   > "Read the codebase and produce or update the README. Include: project description, prerequisites with exact versions, step-by-step local setup with copy-pasteable commands, all environment variables in a table, available scripts, architecture overview, and links to API docs and runbook. Every command must be verified against the actual project."

   **OpenAPI**:
   > "Read all route definitions, controllers, and validation schemas. Produce a complete, valid OpenAPI 3.1 spec at docs/openapi.yaml. Document every endpoint: method, path, parameters, request body, all response schemas (including error responses), auth requirements, and realistic examples. Sync with the actual implementation — do not document routes that don't exist."

   **ADR**:
   > "Write an Architecture Decision Record for the following decision: [decision]. Include: context, the decision made, rationale, alternatives considered, and consequences. Save to docs/adr/ADR-XXX-[title].md."

   **Runbook**:
   > "Produce a deployment runbook. Read the CI/CD config, Dockerfile, infrastructure files, and environment config. Document: all environments with URLs and regions, the deploy process step by step, where each environment variable is set, secrets management, rollback procedure, health check locations, log locations, and common failure modes with resolutions."

   **All**:
   > "Audit all existing documentation for accuracy and completeness. Read the codebase, identify gaps between the code and the docs, and produce or update: README, OpenAPI spec, ADRs for any undocumented significant decisions, and deployment runbook. Flag anything you cannot verify from the code as [NEEDS VERIFICATION]."

2. Wait for the agent to complete and write files

---

## Step 3: Review & Verify

**Actions**:
1. Read the produced documentation files
2. Check for [NEEDS VERIFICATION] flags — present these to the Stakeholder for input
3. Confirm all commands in the README are accurate
4. Confirm OpenAPI spec matches the actual implementation (diff against routes if needed)
5. Ask the Stakeholder if anything is missing or incorrect

---

## Step 4: Summary

**Actions**:
1. Mark todos complete
2. Deliver a documentation summary:
   - Files written or updated (with paths)
   - [NEEDS VERIFICATION] items requiring Stakeholder input
   - Recommended documentation maintenance schedule
