---
description: Run a dependency audit using the dependency-auditor agent — CVE scanning, outdated packages, license compliance, unused dependencies, and bloat reduction. Invoke before releases, after adding packages, or on a regular maintenance schedule.
argument-hint: Optional focus area — security, licenses, outdated, bloat (default: all)
---

# Dependency Audit

You are orchestrating a dependency audit using the `dependency-auditor` agent. The user is the **Product Stakeholder and owner** — findings include security, legal, and operational risk context.

Use TodoWrite to track progress.

---

## Step 1: Define Scope

Audit focus: $ARGUMENTS

**Actions**:
1. Create a todo list
2. Determine focus:
   - `security` — CVEs only
   - `licenses` — license compliance only
   - `outdated` — version currency only
   - `bloat` — unused and oversized packages only
   - Empty or `all` — comprehensive audit across all dimensions
3. Read `package.json` and lock file to understand the dependency tree
4. Check if this is pre-release (higher urgency on security findings) or routine maintenance

---

## Step 2: Launch Dependency Auditor

**Actions**:
1. Launch the `dependency-auditor` agent:
   - Prompt: "Perform a [scope] dependency audit on this project. Run: npm audit for CVEs, npm outdated for version currency, depcheck for unused packages, license-checker for license compliance, and identify bloated packages with lighter alternatives. Cross-reference significant CVEs with advisory databases. Produce a prioritised report with a concrete upgrade plan the fullstack-engineer can execute safely."
2. Wait for the full report

---

## Step 3: Triage & Plan

**Actions**:
1. Present findings to the Stakeholder:
   - **Critical/High CVEs** — immediate fix required before any deployment
   - **License issues** — legal risk, needs Stakeholder awareness
   - **Outdated packages** — patch/minor/major grouped by risk
   - **Unused packages** — safe removals
   - **Bloat opportunities** — bundle size savings available
2. Ask which actions to take now vs defer
3. If fixes are approved:
   - Hand the upgrade plan to the `fullstack-engineer` to execute
   - After upgrades, re-run `npm audit` to confirm CVEs resolved
   - Run the test suite to catch any breaking changes from upgrades

---

## Step 4: Summary

**Actions**:
1. Mark todos complete
2. Deliver a dependency audit report:
   - Total dependencies audited (direct + transitive)
   - CVEs found and resolved: X critical, Y high, Z moderate
   - License issues identified and status
   - Packages updated: patch / minor / major counts
   - Packages removed (unused)
   - Bundle size impact (before/after if bloat was addressed)
   - Outstanding items deferred
   - Recommended next audit date
