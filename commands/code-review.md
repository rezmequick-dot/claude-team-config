---
description: Run a senior-level code review against changed or specified files using the senior-code-reviewer agent. Checks for correctness, TypeScript strictness, architecture, test coverage, performance, security, and linting standards.
argument-hint: Files, feature, or PR to review (optional — defaults to current git changes)
---

# Code Review

You are orchestrating a thorough code review using the `senior-code-reviewer` agent. This command can target specific files, a feature branch, or default to all current uncommitted changes. The user is the **Product Stakeholder and owner** — the review validates that the code matches their agreed requirements, not just that it is technically correct.

Use TodoWrite to track progress.

---

## Step 1: Identify What to Review

**Goal**: Determine the exact set of files and context to pass to the reviewer.

Review target: $ARGUMENTS

**Actions**:
1. Create a todo list for this review run
2. Determine the scope:
   - If $ARGUMENTS specifies files or a feature — use those
   - If $ARGUMENTS is empty — run `git diff HEAD --name-only` to get all changed files
   - If no git changes exist — ask the Stakeholder which files or directories to review
3. Read each file in scope to build your own understanding before launching the agent
4. Gather requirements context for the reviewer:
   - Check for an existing requirements spec (from `project-manager`) for this feature
   - If no spec exists and the feature is non-trivial, ask the Stakeholder to describe the intent and acceptance criteria so the reviewer can validate correctness against them
   - Note any known concerns the Stakeholder wants specifically examined
5. Ask the Stakeholder if there is anything specific they want the reviewer to focus on

---

## Step 2: Launch the Code Reviewer

**Goal**: Run a comprehensive review across all dimensions.

**Actions**:
1. Launch the `senior-code-reviewer` agent with a detailed prompt including:
   - The full list of files to review (with paths)
   - Feature context: what this code is supposed to do
   - Any specific focus areas or concerns raised by the user
   - Prompt: "Review the following files for: correctness against the requirements spec, TypeScript strictness, architectural integrity, code reusability, test coverage, performance, security, and linting standards. Flag any implementation that goes beyond the agreed spec scope. Reference the CLAUDE.md Core Principles. Deliver a structured review report with verdict."
2. Wait for the full review report

---

## Step 3: Present Findings

**Goal**: Surface issues clearly and agree on next steps.

**Actions**:
1. Present the review report structured by severity:
   - **Critical** — bugs, security vulnerabilities, data loss risks (must fix)
   - **Standard violations** — TypeScript, testing, architecture, linting failures (should fix)
   - **Suggestions** — non-blocking improvements (optional)
   - **Approved** — what was done well

2. Based on the verdict:
   - **Approved** — confirm the code is production-ready, mark todos complete
   - **Approved with suggestions** — present optional improvements, ask if the user wants any addressed
   - **Changes requested** — list all required fixes clearly, ask the user how to proceed:
     - Fix now (hand off to `fullstack-engineer` with specific issues)
     - Fix manually
     - Defer with a documented decision

3. If fixes are requested:
   - Launch the `fullstack-engineer` agent with the exact list of issues to address
   - Once complete, re-launch the `senior-code-reviewer` targeting only the changed files
   - Repeat until verdict is Approved or Approved with suggestions

---

## Step 4: Summary

**Goal**: Close out the review with a clear record.

**Actions**:
1. Mark all todos complete
2. Deliver a final summary:
   - Files reviewed (with paths)
   - Issues found by severity: X critical, Y standard violations, Z suggestions
   - Final verdict
   - What was fixed during this session
   - Any deferred decisions or known accepted trade-offs
