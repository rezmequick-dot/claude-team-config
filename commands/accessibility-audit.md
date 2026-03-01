---
description: Run a WCAG 2.1 AA accessibility audit using the accessibility-engineer agent — automated axe-core scanning, keyboard navigation, colour contrast, ARIA correctness, and screen reader compatibility. Always tests against the locally running application.
argument-hint: Pages or components to audit (default: full application)
---

# Accessibility Audit

You are orchestrating a WCAG 2.1 AA accessibility audit using the `accessibility-engineer` agent. The user is the **Product Stakeholder and owner** — findings include user impact context, not just compliance codes.

Use TodoWrite to track progress.

---

## Step 1: Define Scope

Audit target: $ARGUMENTS

**Actions**:
1. Create a todo list
2. Determine scope:
   - Specific pages or components if named in $ARGUMENTS
   - Full application audit if empty
3. Collect context:
   - Local dev server start command and port
   - Key user flows to test (login, checkout, form submission, etc.)
   - Any known accessibility concerns the Stakeholder wants checked
   - Whether the application must meet a specific compliance level (AA is default)
4. Read frontend component files and page routes to understand the UI structure

---

## Step 2: Launch Accessibility Engineer

**Actions**:
1. Launch the `accessibility-engineer` agent:
   - Prompt: "Perform a WCAG 2.1 AA accessibility audit of [scope] running at [local URL]. Run automated axe-core checks via Playwright on all major pages and interactive states (modal open, form with errors, logged-in and logged-out states). Then perform a manual audit of: keyboard navigation across all interactive elements, focus indicator visibility, colour contrast for text and UI components, form label associations and error announcement, ARIA role and attribute correctness, and page title updates on route changes. Deliver a full report with violations ranked by severity and specific remediation code."
2. Wait for full audit report

---

## Step 3: Triage Findings

**Actions**:
1. Present findings to the Stakeholder:
   - **Critical** — users cannot complete a task (keyboard trap, unlabelled form, inaccessible interactive element)
   - **High** — significantly degrades screen reader or keyboard experience
   - **Medium** — WCAG violation with moderate impact
   - **Low** — best practice or AAA recommendation
2. For Critical and High findings, ask whether to fix now or defer
3. If fixes are approved:
   - Hand off to `fullstack-engineer` with specific remediation instructions
   - Re-run `accessibility-engineer` on changed components to confirm compliance

---

## Step 4: Summary

**Actions**:
1. Mark todos complete
2. Deliver an accessibility report:
   - WCAG 2.1 AA compliance status: PASS / PARTIAL / FAIL
   - Violations by severity count
   - Automated scan results (axe-core pass/fail)
   - Keyboard navigation status
   - Colour contrast status
   - Fixes applied during this session
   - Outstanding deferred items
   - Recommended re-audit trigger (next UI release, quarterly)
