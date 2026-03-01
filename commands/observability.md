---
description: Set up or audit application observability using the observability-engineer agent — structured logging, metrics, distributed tracing, alerting, SLOs, and dashboards. Invoke at the start of a new application, before a production launch, or to audit an existing application's visibility gaps.
argument-hint: What to do — setup, audit, feature (add observability for a specific feature), or slo (define service level objectives)
---

# Observability

You are orchestrating observability setup or auditing using the `observability-engineer` agent. The user is the **Product Stakeholder and owner** — observability findings are communicated in terms of production risk and what the team cannot currently see.

Use TodoWrite to track progress.

---

## Step 1: Classify the Task

Observability request: $ARGUMENTS

**Actions**:
1. Create a todo list
2. Classify the task:
   - **setup** — new application, establish full observability foundation from scratch
   - **audit** — existing application, identify blind spots and gaps
   - **feature** — new feature being shipped, ensure it is observable
   - **slo** — define or review Service Level Objectives
   - **alerts** — review or build out alerting rules
   - **dashboard** — create or improve operational/business dashboards
3. Gather context:
   - Application type (API / web app / background workers / combination)
   - Cloud provider and existing infrastructure
   - Any monitoring tools already in use
   - Known blind spots or recent incidents where observability was lacking
   - Scale and traffic expectations
4. For new setups: ask the Stakeholder if they have a budget or preferred tooling (DataDog, Grafana, CloudWatch, etc.)

---

## Step 2: Launch Observability Engineer

**Actions**:
1. Launch the `observability-engineer` agent with a prompt tailored to the task:

   **Setup (new application)**:
   > "Set up the full observability foundation for this new application. Read the codebase to understand the services, endpoints, external dependencies, and background jobs. Recommend an observability stack with cost estimates (present to Stakeholder before provisioning anything paid). Produce: structured logging setup with required fields and correlation ID middleware, metric catalogue with all metric names and labels, OpenTelemetry tracing config, alert rules with thresholds and runbook links, SLO definitions, and a dashboard layout. Provide an implementation checklist for the fullstack-engineer."

   **Audit (existing application)**:
   > "Audit the observability coverage of this existing application. Read the codebase to understand all services, endpoints, and dependencies. Identify: logging gaps (unstructured logs, missing correlation IDs, sensitive data in logs), metric gaps (endpoints without RED metrics, missing business metrics), tracing gaps, alert gaps (core flows without alerting), missing SLOs, and dashboard blind spots. Produce a gap report ranked by severity with specific remediation steps."

   **Feature observability**:
   > "Ensure the recently implemented feature [feature] is fully observable in production. Review the new code and identify: what needs to be logged (at what level and with what fields), what metrics need to be added (endpoints, business events, background jobs), what alerts need to cover new failure modes, and what dashboard panels need updating. Produce an instrumentation spec for the fullstack-engineer."

   **SLO definition**:
   > "Define Service Level Objectives for this application. Read the codebase and existing infrastructure to understand the services and their criticality. Propose: availability SLO (request success rate), latency SLO (p95/p99 targets), error budget calculation, and alert rules that fire before the error budget is exhausted. Present recommendations to the Stakeholder for approval."

   **Alerts review**:
   > "Review existing alerting configuration for quality and completeness. Check: are all critical endpoints covered? Are thresholds based on observed baselines or arbitrary values? Does every alert link to a runbook? Are there false positives causing alert fatigue? Are there gaps where incidents have occurred without an alert firing? Produce a prioritised list of alert improvements."

   **Dashboard**:
   > "Design or improve the operational and business dashboards. Read the metrics currently available and identify what should be visible. Produce: an operational dashboard layout for the engineering team (RED metrics, infrastructure, jobs, dependencies) and a business dashboard layout for the Stakeholder (user activity, key business events, availability). Describe the panels, queries, and layout."

2. If the stack recommendation involves paid services — present cost estimates to the Stakeholder and wait for approval before any provisioning

---

## Step 3: Review & Implement

**Actions**:
1. Present the observability plan or audit findings to the Stakeholder
2. For setup/feature tasks:
   - Hand the instrumentation spec to the `fullstack-engineer` to implement
   - Hand infrastructure requirements to the `devops-engineer` to provision
   - After implementation, re-run `observability-engineer` to verify the instrumentation is correct
3. For audit findings, prioritise by severity:
   - **Critical/High** — fix before next production deployment
   - **Medium** — schedule for next sprint
   - **Low** — backlog

---

## Step 4: Verify

**Actions**:
1. Once instrumentation is implemented, launch `observability-engineer` to verify:
   - Prompt: "Verify that the observability instrumentation has been correctly implemented. Check that: structured logs are emitting with required fields and correlation IDs, metrics are being collected and labelled correctly, traces are flowing through the system, alerts are configured and would fire on test conditions, and dashboards are populated with real data."
2. Confirm with Stakeholder that the team can now answer:
   - Is the application healthy right now?
   - What is the error rate over the last hour?
   - Which endpoint is the slowest at p95?
   - What happened to a specific user's request (trace)?
   - Will we be paged before users notice a problem?

---

## Step 5: Summary

**Actions**:
1. Mark todos complete
2. Deliver an observability summary:
   - Stack in use and monthly cost
   - Logging: format, fields, aggregation destination, retention
   - Metrics: catalogue of metrics instrumented, collection interval
   - Tracing: coverage, sampling rate, backend
   - Alerts: count by tier, runbook status
   - SLOs: defined objectives and error budgets
   - Dashboards: operational and business dashboard locations
   - Gaps remaining (if any) with scheduled resolution
