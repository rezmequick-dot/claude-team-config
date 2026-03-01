---
description: Run a full security audit using the security-engineer agent — OWASP Top 10, CVE scanning, secrets detection, auth review, and security headers. Invoke before any production release or after changes to auth, APIs, or infrastructure.
argument-hint: Scope of audit — specific files, feature, or full codebase (default)
---

# Security Audit

You are orchestrating a security audit using the `security-engineer` agent. The user is the **Product Stakeholder and owner** — findings are communicated with business risk context, not just technical detail.

Use TodoWrite to track progress.

---

## Step 1: Define Scope

Audit target: $ARGUMENTS

**Actions**:
1. Create a todo list
2. Determine scope:
   - If $ARGUMENTS specifies files or a feature — target those
   - If $ARGUMENTS is empty — full codebase audit
3. Collect context to give the agent:
   - Application type (API / web app / both)
   - Authentication mechanism in use
   - Any known concerns the Stakeholder wants specifically checked
   - Recent changes (check `git diff HEAD --name-only` if not specified)
4. Read key files: auth middleware, route definitions, input validation, environment config

---

## Step 2: Launch Security Engineer

**Actions**:
1. Launch the `security-engineer` agent:
   - Prompt: "Perform a comprehensive security audit of [scope]. Cover: OWASP Top 10 across all affected code paths, authentication and authorisation correctness, input validation and sanitisation, secrets detection (hardcoded credentials, committed .env files), security header configuration, dependency CVEs, and rate limiting. Reference the approved requirements spec if available. Deliver a full audit report with findings ranked by severity and specific remediation steps."
2. Wait for the full report

---

## Step 3: Triage Findings

**Actions**:
1. Present findings to the Stakeholder by severity:
   - **Critical** — directly exploitable, must fix immediately before any deployment
   - **High** — significant risk, fix before next release
   - **Medium** — fix in next maintenance window
   - **Low** — defence-in-depth, schedule as time permits
2. For Critical and High findings, ask the Stakeholder how to proceed:
   - Fix now → hand off to `fullstack-engineer` with exact remediation steps
   - Accept risk with documentation → record as a known accepted risk
3. If fixes are applied:
   - Launch `fullstack-engineer` with specific remediation instructions
   - Re-launch `security-engineer` on the changed files only to confirm fixes are effective

---

## Step 4: Summary

**Actions**:
1. Mark todos complete
2. Deliver a final security report:
   - Audit scope and methodology
   - Findings by severity: X critical, Y high, Z medium, W low
   - Fixes applied during this session
   - Known accepted risks (with Stakeholder sign-off noted)
   - Dependency CVEs status
   - Secrets detected and remediated
   - Security headers status
   - Recommended next audit trigger (next release, 30 days, after auth changes)
