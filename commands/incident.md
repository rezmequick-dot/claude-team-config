---
description: Manage a production incident using the incident-responder agent — rapid diagnosis, service restoration, rollback coordination, and post-mortem. Invoke immediately when something is broken in production.
argument-hint: Describe what is broken and in which environment
---

# Incident Response

You are orchestrating a production incident response using the `incident-responder` agent. The user is the **Product Stakeholder and owner** — they receive clear, jargon-free status updates throughout. Speed matters but accuracy matters more — diagnose before acting.

Use TodoWrite to track all phases.

---

## Step 1: Immediate Assessment

Incident description: $ARGUMENTS

**Actions**:
1. Create a todo list: Assess → Diagnose → Restore → Post-mortem
2. Classify severity immediately based on $ARGUMENTS:
   - **SEV-1** — complete outage, all users affected
   - **SEV-2** — major degradation, core feature broken for many users
   - **SEV-3** — partial degradation, non-critical feature affected
   - **SEV-4** — minor issue, low impact
3. Send an immediate status message to the Stakeholder:
   > "🔴 Incident active. Severity: SEV-X. [What is broken]. Investigating now. Next update in [5/10] minutes."
4. Collect everything needed for the incident responder:
   - What is broken and how it was detected
   - Environment affected (staging / production)
   - When it started (exact time if known)
   - Any recent deployments, config changes, or traffic spikes
   - Access to logs, monitoring, and deployment history

---

## Step 2: Diagnose & Restore

**Actions**:
1. Launch the `incident-responder` agent immediately:
   - Prompt: "Production incident in progress. SEV-[X]. [Description of what is broken]. Environment: [env]. Started: [time]. Recent changes: [deployments/changes]. Diagnose the root cause by reading logs, checking system resources, and reviewing recent changes. Do not make changes until root cause is confirmed. Once identified, choose the fastest safe restoration path: rollback, hotfix, or infrastructure mitigation. Coordinate with devops-engineer for rollback if needed. Restore service, then document the full timeline and root cause."
2. Provide status updates to the Stakeholder every 10 minutes (SEV-1) or 30 minutes (SEV-2/3) until resolved:
   > "🟡 Update: [What was found]. [Action being taken]. ETA [time]."
3. If the agent determines a rollback is needed:
   - Launch `devops-engineer` in parallel:
     - Prompt: "Incident in progress. Roll back [service/deployment] to the last known-good version. Confirm service is restored after rollback."
4. If the agent determines a hotfix is needed:
   - Launch `fullstack-engineer` with the exact minimal fix
   - Have `senior-code-reviewer` review the hotfix — even under pressure
   - Deploy via `devops-engineer`

---

## Step 3: Confirm Resolution

**Actions**:
1. Verify the application is healthy:
   - Health check endpoints responding
   - Error rate returned to baseline
   - Core user flows functional
2. Send resolution notification to Stakeholder:
   > "🟢 Resolved. Service restored at [time]. Root cause: [one sentence]. Users affected for approximately [duration]. Post-mortem to follow within 24 hours."
3. Update todos: Assess ✓ → Diagnose ✓ → Restore ✓ → Post-mortem pending

---

## Step 4: Post-Mortem

**Actions**:
1. Launch `incident-responder` for post-mortem:
   - Prompt: "Incident resolved. Write a blameless post-mortem covering: summary, full timeline, root cause, contributing factors, user impact, resolution steps, and action items to prevent recurrence. Action items should be specific, assigned to the relevant agent or owner, and prioritised."
2. Present the post-mortem to the Stakeholder for review
3. Create follow-up tasks from the action items:
   - Code fixes → `fullstack-engineer`
   - Monitoring improvements → `devops-engineer`
   - Process improvements → `project-manager`
   - Security gaps → `security-engineer`

---

## Step 5: Summary

**Actions**:
1. Mark all todos complete
2. Deliver final incident record:
   - Incident title and severity
   - Total duration (detection to resolution)
   - Root cause (one sentence)
   - Users/features affected
   - Resolution method (rollback / hotfix / infrastructure)
   - Post-mortem location
   - Action items count and owners
