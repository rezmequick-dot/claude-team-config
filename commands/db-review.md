---
description: Run a database architecture review using the database-architect agent — schema design, indexing strategy, query optimisation, migration safety, and data integrity. Invoke before running migrations, when experiencing slow queries, or when designing a new data model.
argument-hint: What to review — specific schema, migration, feature, or full database audit
---

# Database Review

You are orchestrating a database architecture review using the `database-architect` agent. The user is the **Product Stakeholder and owner** — findings include business risk context (data loss, availability, performance impact).

Use TodoWrite to track progress.

---

## Step 1: Define Scope

Review target: $ARGUMENTS

**Actions**:
1. Create a todo list
2. Determine scope:
   - Specific schema or migration if named in $ARGUMENTS
   - Full database audit if empty
3. Classify the review type:
   - **New schema design** — reviewing a proposed data model before implementation
   - **Migration safety** — reviewing migration files before they run
   - **Query optimisation** — investigating slow queries or N+1 patterns
   - **Full audit** — comprehensive review of schema, indexes, and queries
4. Read schema files (Prisma schema, TypeORM entities, migration files, raw SQL)
5. Check for slow query logs or performance concerns to give the agent

---

## Step 2: Launch Database Architect

**Actions**:
1. Launch the `database-architect` agent with a prompt tailored to the review type:

   **New schema design**:
   > "Review this proposed schema for [feature]. Evaluate: normalisation, data types, constraints, naming conventions, indexing strategy for the expected access patterns, and migration safety. Recommend improvements before implementation begins."

   **Migration safety**:
   > "Review the migration files in [path] before they are executed. Identify: destructive operations, zero-downtime risks, lock acquisition concerns, backwards compatibility with the current application code, and whether each migration has a safe rollback. Flag anything that must be changed before running."

   **Query optimisation**:
   > "Analyse the queries in [files/feature] for performance issues. Identify N+1 patterns, missing indexes, unbounded result sets, and inefficient JOINs. Propose specific index additions and query rewrites with before/after examples."

   **Full audit**:
   > "Perform a comprehensive database audit. Review: schema design and normalisation, data types and constraints, indexing strategy vs actual query access patterns, any pending or recent migrations for safety, query patterns for N+1 or performance issues, connection pool configuration, and data integrity. Produce findings ranked by severity."

2. Wait for the full report

---

## Step 3: Review & Act

**Actions**:
1. Present findings to the Stakeholder:
   - **Critical** — data loss risk, unsafe migration, missing integrity constraint
   - **High** — significant performance issue, N+1 on hot path, unsafe migration step
   - **Medium** — suboptimal but not immediately harmful
   - **Low** — naming, minor optimisation
2. For migrations specifically — confirm with Stakeholder before any migration is executed
3. If schema or query changes are approved:
   - Hand off to `fullstack-engineer` for implementation
   - Re-run `database-architect` on changed files to confirm

---

## Step 4: Summary

**Actions**:
1. Mark todos complete
2. Deliver a database review report:
   - Scope reviewed
   - Schema assessment
   - Migration safety verdict (if applicable) — safe to run / blocked / conditional
   - Index recommendations with CREATE INDEX statements
   - Query optimisations with before/after
   - Data integrity findings
   - Outstanding items and next steps
