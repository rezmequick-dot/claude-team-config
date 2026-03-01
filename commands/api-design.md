---
description: Design or review API contracts using the api-designer agent — REST endpoint design, GraphQL schema, versioning strategy, OpenAPI 3.1 spec authoring, and backwards compatibility analysis. Design is always approved before implementation begins.
argument-hint: Feature or API to design, or existing API to review
---

# API Design

You are orchestrating API design or review using the `api-designer` agent. The user is the **Product Stakeholder and owner** — the API contract is agreed before any implementation begins.

Use TodoWrite to track progress.

---

## Step 1: Define the Task

Design target: $ARGUMENTS

**Actions**:
1. Create a todo list
2. Classify the task:
   - **New API design** — designing endpoints for a new feature from scratch
   - **API review** — reviewing existing endpoints for design quality
   - **Breaking change assessment** — evaluating proposed changes for backwards compatibility
   - **OpenAPI spec** — generating or updating an OpenAPI spec from existing code
3. Gather context:
   - The `project-manager` spec if one exists (requirements drive API design)
   - Existing route definitions and controller files
   - Existing OpenAPI spec if one exists
   - Who will consume this API — internal only or external third parties?
   - Versioning strategy currently in use
4. Ask the Stakeholder if there are specific constraints: auth model, response format conventions, rate limiting requirements

---

## Step 2: Launch API Designer

**Actions**:
1. Launch the `api-designer` agent with a prompt tailored to the task:

   **New API design**:
   > "Design the API contract for [feature] based on this requirements spec: [spec]. Define: resource model, all endpoints (method, path, request/response schemas), error responses, auth requirements, pagination approach, and versioning. Produce a complete OpenAPI 3.1 spec. Present the design for Stakeholder approval before any implementation."

   **API review**:
   > "Review the existing API design in [files]. Evaluate against REST best practices: resource naming, correct HTTP method usage, appropriate status codes, consistent error response shape, pagination design, versioning strategy, and backwards compatibility. Deliver findings with specific recommendations."

   **Breaking change assessment**:
   > "Assess the proposed changes to [endpoint/feature] for backwards compatibility. Identify every breaking change — field removals, type changes, required field additions, endpoint removals — and their impact on existing consumers. Propose a migration strategy: versioning, deprecation timeline, and communication plan."

   **OpenAPI spec**:
   > "Read all route definitions, controllers, and validation schemas in this codebase. Produce a complete, valid OpenAPI 3.1 spec at docs/openapi.yaml. Every endpoint, parameter, request body, and response schema must be derived from the actual implementation. Include realistic examples."

2. Wait for the full output

---

## Step 3: Stakeholder Sign-off

**Actions**:
1. Present the API design or review to the Stakeholder:
   - For new design: full endpoint list with request/response examples
   - For reviews: findings by severity with recommendations
   - For breaking changes: impact assessment and migration plan
2. **For new API design — do not hand off to the `fullstack-engineer` until the Stakeholder approves the contract**
3. If changes are requested, loop back to `api-designer` with specific feedback
4. Once approved, hand the OpenAPI spec to the `fullstack-engineer` as the implementation contract and to the `technical-writer` for documentation

---

## Step 4: Summary

**Actions**:
1. Mark todos complete
2. Deliver an API design summary:
   - Endpoints designed or reviewed (method + path)
   - OpenAPI spec location (`docs/openapi.yaml`)
   - Breaking changes identified (if review)
   - Stakeholder approval status
   - Handoff to implementation: confirmed / pending approval
