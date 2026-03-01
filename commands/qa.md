---
description: Run QA validation against a locally running application — validates acceptance criteria and negative testing using Playwright for frontend and cURL for APIs
argument-hint: Describe what to test and any acceptance criteria
---

# QA Validation

You are orchestrating a targeted QA validation run using the `qa-engineer` agent. This command can be used independently at any point — not just inside the feature development pipeline. The user is the **Product Stakeholder and owner** — their acceptance criteria are the definition of done.

Use TodoWrite to track progress.

---

## Step 1: Gather Context

**Goal**: Give the QA agent everything it needs to test effectively.

Test request: $ARGUMENTS

**Actions**:
1. Create a todo list for this QA run
2. If acceptance criteria are not provided in $ARGUMENTS, launch the `project-manager` agent to gather them:
   - Prompt: "The Stakeholder wants to run QA on the following: $ARGUMENTS. Ask any clarifying questions needed and produce a clear list of testable acceptance criteria and negative test scenarios."
   - Present the criteria to the Stakeholder for confirmation before proceeding
3. If acceptance criteria are already provided, confirm with the Stakeholder that they are complete and correct
4. Collect any additional context needed:
   - Is this a frontend app, backend API, or both?
   - What is the local start command and expected port?
   - Are there any auth tokens, environment variables, or seed data required?
5. Read relevant files to understand the feature being tested:
   - Route definitions, controllers, or page components
   - Any recent changes (check git diff if available)

---

## Step 2: Launch QA Agent

**Goal**: Run acceptance and negative testing against the locally running application.

**Actions**:
1. Launch the `qa-engineer` agent with a detailed prompt including:
   - Application type: frontend (Playwright) / API (cURL) / both
   - Local start command and expected port
   - Full list of acceptance criteria to validate
   - Any auth requirements, environment variables, or preconditions
   - Any specific negative scenarios the user wants covered
   - Prompt: "Start the application locally, validate all acceptance criteria, run full negative testing, and deliver a structured test report with a final verdict."
2. Wait for the full test report

---

## Step 3: Review Results

**Goal**: Interpret results and determine next steps.

**Actions**:
1. Present the QA report to the user clearly:
   - Acceptance criteria: pass/fail per criterion
   - Negative tests: pass/fail per scenario
   - Issues found ranked by severity
   - Final verdict: PASS / CONDITIONAL PASS / FAIL

2. Based on verdict:
   - **PASS** — confirm everything is working, mark todos complete
   - **CONDITIONAL PASS** — present the minor issues, ask the user if they want them fixed or acknowledged
   - **FAIL** — clearly list the failing criteria and blocking issues, ask the user how to proceed:
     - Fix now (hand off to `fullstack-engineer`)
     - Investigate further
     - Accept known failure and document it

3. If the user wants fixes applied:
   - Hand failing scenarios to the `fullstack-engineer` agent with specific reproduction steps
   - Once fixed, re-launch the `qa-engineer` agent targeting only the affected areas
   - Repeat until verdict is PASS or CONDITIONAL PASS

---

## Step 4: Summary

**Goal**: Close out the QA run with a clear record.

**Actions**:
1. Mark all todos complete
2. Deliver a final summary:
   - Feature tested
   - Test coverage: how many acceptance criteria, how many negative scenarios
   - Final verdict
   - Issues found and their resolution status
   - Any recommended follow-up testing or known gaps
