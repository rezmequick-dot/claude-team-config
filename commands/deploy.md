---
description: Plan, validate, and execute deployments using the devops-engineer agent. Handles new infrastructure setup, pipeline changes, secrets management, and deployments. For projects with auto-deploy on merge to main (e.g. Sarah Sweeps via Azure Pipelines), monitors the pipeline that was already triggered rather than running manual staging/production steps.
argument-hint: Describe what to deploy or the infrastructure task to perform
---

# Deployment Pipeline

You are orchestrating a deployment or infrastructure task using the `devops-engineer` agent. The user is the **Product Stakeholder and owner**. No paid cloud resources will be provisioned and no production deployment will occur without their explicit approval.

Use TodoWrite to track progress.

---

## Step 1: Classify the Task

**Goal**: Understand exactly what is being asked before doing anything.

Deployment request: $ARGUMENTS

**Actions**:
1. Create a todo list for this deployment run
2. Classify the request into one of the following:
   - **New application setup** — first-time infrastructure and pipeline for a new project
   - **New feature deployment** — deploying changes that passed QA to staging/production
   - **Infrastructure change** — modifying existing cloud resources, scaling, or adding services
   - **Pipeline change** — updating CI/CD config, adding stages, changing triggers
   - **Secrets change** — rotating, adding, or removing secrets
   - **Rollback** — reverting a deployment to a previous known-good state
   - **Audit/review** — reviewing existing infrastructure or pipeline without making changes
3. If the request is ambiguous, ask the Stakeholder to clarify before proceeding
4. Read relevant files to understand current state:
   - CI/CD config (`.github/workflows/`, `azure-pipelines.yml`, `Dockerfile`, `docker-compose.yml`)
   - Infrastructure-as-code (`terraform/`, `cdk/`, `pulumi/`, `sst.config.ts`)
   - Package.json for runtime and build commands
   - Any existing deployment runbook or README sections on deployment
5. **Detect auto-deploy pipelines**: Check whether this project deploys automatically on merge to main:
   - Look for `azure-pipelines.yml` with a `trigger: - main` or `trigger: branches: include: [main]` block
   - Look for `.github/workflows/` files with `on: push: branches: [main]`
   - If an auto-deploy pipeline is found, note it — **Steps 4 (Staging) and 7 (Production Deployment) are replaced by pipeline monitoring** for "New feature deployment" tasks. No manual deploy action is needed; the pipeline already fired on merge.

---

## Step 2: Engage DevOps Engineer

**Goal**: Hand off to the `devops-engineer` agent with full context.

**Actions**:
1. Launch the `devops-engineer` agent with a prompt tailored to the task type:

   **New application setup**:
   > "A new application needs its infrastructure and CI/CD pipeline set up. Here are the project requirements: [requirements from PM spec or Stakeholder]. Read the codebase to understand the runtime, dependencies, and structure. Propose at least two deployment architecture options with full cost estimates. Do not provision anything — present options to the Stakeholder for approval first. Once approved, build the pipeline and infrastructure-as-code, set up secrets management, and produce a deployment runbook."

   **New feature deployment (auto-deploy pipeline detected)**:
   > "A feature has been merged to main and the CI/CD pipeline has already triggered automatically. Pipeline: [pipeline name / URL]. Changed files: [list]. Check whether the pipeline run has completed successfully. Confirm the application is healthy post-deploy. Report the production URL and final deployment status. Do NOT attempt to re-deploy — the pipeline already handled it."

   **New feature deployment (no auto-deploy)**:
   > "The following feature has passed QA and is ready to deploy: [feature description]. Review the changes for any new environment variables, secrets, or infrastructure requirements. If anything paid needs to change, present a cost estimate for Stakeholder approval before acting. Validate the CI/CD pipeline, deploy to staging, run smoke tests, and report the result. Do not deploy to production without explicit Stakeholder approval."

   **Infrastructure change**:
   > "The following infrastructure change is required: [description]. Assess the current infrastructure state from config files, identify what needs to change, and present a cost impact estimate (increase, decrease, or neutral). If costs increase, wait for Stakeholder approval before making changes. Produce an execution plan before running anything destructive."

   **Pipeline change**:
   > "The CI/CD pipeline needs the following change: [description]. Review the current pipeline config, propose the change, and implement it. Trigger a test pipeline run to confirm it passes. Report the result."

   **Secrets change**:
   > "The following secrets change is needed: [description]. Follow the secrets management hierarchy — never store secrets in code or committed files. Document where the secrets now live and confirm injection is working in each affected environment."

   **Rollback**:
   > "A rollback is needed. [Describe what went wrong and what environment]. Identify the last known-good deployment, execute the rollback, confirm the application is healthy, and report what was rolled back and why."

   **Audit/review**:
   > "Review the current infrastructure and CI/CD pipeline. Identify any security concerns, cost optimisation opportunities, missing best practices (secrets in wrong places, no rollback, no smoke tests), and report findings with recommendations."

2. Wait for the full agent report before proceeding

---

## Step 3: Cost Approval Gate

**Goal**: Ensure the Stakeholder approves any cost implications before resources are provisioned.

**Actions**:
1. If the `devops-engineer` agent has identified any paid resources to be provisioned or changed:
   - Present the cost estimate to the Stakeholder in full
   - Include: services to be created/changed, monthly cost estimate, one-time costs, and free tier applicability
   - **Do not proceed until the Stakeholder gives explicit approval**
   - If the Stakeholder declines, ask whether to explore a lower-cost alternative or stop
2. If no paid resources are affected — proceed directly to Step 4

---

## Step 4: Staging Deployment

**Skip this step entirely if an auto-deploy pipeline was detected.** The pipeline handles both staging and production; proceed to Step 5 (Observability Gate).

**For projects without auto-deploy**:

**Goal**: Confirm the deployment works in staging before touching production.

**Actions**:
1. If deploying application changes, instruct the `devops-engineer` agent to:
   - Trigger the CI/CD pipeline for the staging environment
   - Confirm all pipeline stages pass (lint, test, build, deploy)
   - Run smoke tests against staging
   - Report staging URL and confirmation of healthy state
2. Present the staging result to the Stakeholder
3. If staging fails — report the failure in full, ask the Stakeholder how to proceed (fix and retry, or stop)

---

## Step 5: Observability Gate

**Goal**: Confirm the application is observable in production before deploying (or immediately after auto-deploy).

**Actions**:
1. Launch the `observability-engineer` agent:
   - Prompt: "Before this deployment goes to production, verify observability is in place. Check: are structured logs emitting with correlation IDs? Are RED metrics (rate, errors, duration) instrumented on all endpoints being deployed? Are traces flowing? Are alert rules configured for new failure modes introduced by this deployment? Is there a dashboard panel covering this feature? Report any gaps — do not approve deployment if critical observability is missing."
2. If gaps are found:
   - **Critical gaps** (no error tracking, no alerting on new endpoints) — block deployment, hand to `fullstack-engineer` to instrument, then re-verify
   - **Minor gaps** — present to Stakeholder and ask whether to fix now or log as a known gap
3. Once observability is confirmed — proceed

---

## Step 6: Production Approval Gate

**Skip this step if an auto-deploy pipeline was detected** — the pipeline already deployed to production on merge. Proceed to Step 7 to confirm the pipeline result.

**For projects without auto-deploy**:

**Goal**: Get explicit Stakeholder sign-off before deploying to production.

**Actions**:
1. Present a production deployment summary to the Stakeholder:
   - What is being deployed
   - Staging validation outcome
   - Observability confirmation — what is being monitored and alerted on
   - Any infrastructure changes that will take effect
   - Rollback plan if production deployment fails
2. **Ask for explicit Stakeholder approval to deploy to production**
3. Do not proceed without a clear "yes"
4. If the Stakeholder declines — confirm staging remains deployed and stop

---

## Step 7: Production Deployment / Pipeline Confirmation

**For projects with auto-deploy**: Confirm the pipeline that fired on merge completed successfully. Report the build number, completion status, and any smoke test results from the pipeline. Do not trigger a new deployment.

**For projects without auto-deploy**:

**Goal**: Deploy to production safely with rollback readiness.

**Actions**:
1. Instruct the `devops-engineer` agent to:
   - Trigger the production deployment pipeline
   - Monitor the deployment until complete
   - Run smoke tests against production
   - Confirm the application is healthy
   - Report the production URL and deployment status
2. If production deployment fails:
   - Immediately execute the rollback plan
   - Confirm rollback succeeded and application is back to healthy state
   - Report the failure cause in full
   - Ask the Stakeholder how to proceed

---

## Step 8: Summary

**Goal**: Close out the deployment with a clear record.

**Actions**:
1. Mark all todos complete
2. Deliver a final deployment report:
   - Task performed (setup / deploy / infrastructure change / rollback / audit)
   - Environments affected
   - Infrastructure provisioned or changed (with resource names and regions)
   - Secrets added or rotated (confirm stored correctly — never list secret values)
   - Pipeline changes made
   - Staging result (or "auto-deployed — no separate staging step")
   - Production result (pipeline build number if auto-deploy)
   - Monthly cost impact (new total if infrastructure changed)
   - Rollback procedure (how to revert this deployment if needed later)
   - Updated runbook location (if runbook was created or modified)
