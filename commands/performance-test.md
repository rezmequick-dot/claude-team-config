---
description: Run performance profiling and load testing using the performance-engineer agent — API response times, Node.js profiling, database query performance, frontend bundle analysis, and Core Web Vitals. Always tests against a running application.
argument-hint: What to test — specific endpoint, feature, or full application (default)
---

# Performance Test

You are orchestrating performance testing using the `performance-engineer` agent. Always tests against the locally or staging-running application — never assumes performance from reading code alone.

Use TodoWrite to track progress.

---

## Step 1: Define Scope & Targets

Test target: $ARGUMENTS

**Actions**:
1. Create a todo list
2. Determine what to test:
   - Specific endpoint or feature if named in $ARGUMENTS
   - Full application benchmark if empty
3. Ask the Stakeholder for performance targets if not already defined:
   - API p95 response time target (default: 200ms)
   - Acceptable error rate under load (default: < 0.1%)
   - Expected concurrent users or requests/second
   - Any specific bottlenecks they suspect
4. Read package.json for local start command and port
5. Check for existing performance test files (k6, Artillery scripts)

---

## Step 2: Launch Performance Engineer

**Actions**:
1. Launch the `performance-engineer` agent:
   - Prompt: "Perform a full performance assessment of [scope] running at [local URL]. First establish a baseline with no load. Then run load tests simulating [target concurrency]. Profile: API response times (p50/p95/p99), event loop lag, memory growth under load, database query times on hot paths, and [if frontend] bundle size and Core Web Vitals. Identify the top bottlenecks by impact. Deliver findings with before measurements, root cause analysis, and specific optimisation recommendations ranked by impact/effort."
2. Wait for the full performance report

---

## Step 3: Review & Prioritise

**Actions**:
1. Present findings to the Stakeholder:
   - Baseline measurements vs targets
   - Load test results — throughput, latency percentiles, error rate
   - Top bottlenecks identified with user impact
   - Optimisation recommendations ranked by impact/effort ratio
2. Ask which optimisations to implement now vs defer
3. If optimisations are approved:
   - Hand off to `fullstack-engineer` and/or `database-architect` with specific changes
   - Re-run the `performance-engineer` on affected areas to confirm improvement
   - Report the delta — before and after measurements

---

## Step 4: Summary

**Actions**:
1. Mark todos complete
2. Deliver a performance report:
   - Baseline measurements established
   - Load test results: throughput, p95/p99 latency, error rate
   - Bottlenecks found and root causes
   - Optimisations applied and measured improvement
   - Outstanding items deferred (with rationale)
   - Performance budget targets — pass/fail status
