---
description: Run a visual design conformance audit using the ui-ux-engineer agent — spacing, typography, colour tokens, responsive layout, and component alignment against the established design patterns. Always tests against the locally running application.
argument-hint: Pages or components to audit (default: all changed UI files)
---

# UI/UX Design Conformance Review

You are orchestrating a visual design conformance audit using the `ui-ux-engineer` agent. The user is the **Product Stakeholder and owner** — findings are communicated with clear visual context, not just technical detail.

Use TodoWrite to track progress.

---

## Step 1: Gather Context

**Goal**: Give the agent everything it needs to audit effectively.

Audit target: $ARGUMENTS

**Actions**:
1. Create a todo list for this audit run
2. Identify the scope:
   - If $ARGUMENTS specifies pages or components — target those
   - If $ARGUMENTS is empty — audit all recently changed UI files (`git diff --name-only` filtered to `.tsx`/`.jsx`/`.css`)
3. Collect context:
   - Local start command and port (default: `npm run dev`, port 3000)
   - Any auth credentials needed to reach the pages under audit
   - The Tailwind config path (`tailwind.config.js` or `tailwind.config.ts`) — this is the design baseline
   - Any Figma links or design spec documents the Stakeholder has provided
4. Read the Tailwind config and a representative sample of existing components to establish the spacing/typography/colour baseline before launching the agent

---

## Step 2: Launch UI/UX Engineer

**Goal**: Capture screenshots and audit visual conformance at all breakpoints.

**Actions**:
1. Confirm the dev server is running and returning HTTP 200
2. Launch the `ui-ux-engineer` agent with:
   - Pages/components to audit
   - Local URL and any required auth cookies or credentials
   - Tailwind config summary (spacing scale, colour palette, font sizes)
   - Breakpoints to test: mobile (375px), tablet (768px), desktop (1280px)
   - Prompt: "Audit the following pages/components for visual design conformance: [scope]. Using Playwright, navigate to each page and capture screenshots at 375px, 768px, and 1280px viewport widths. Check each screenshot against the Tailwind design baseline for: (1) spacing and padding consistency — flag any element that lacks expected margin/padding relative to adjacent elements or the viewport edge; (2) typography — font sizes, weights, and line heights consistent with the scale; (3) colour — all colours drawn from the defined palette, no hardcoded hex values outside the config; (4) alignment — elements aligned to the grid, no unexpected overflow or clipping; (5) responsive behaviour — layout adapts correctly at each breakpoint, no content overlap or hidden elements. Report findings by severity: Critical (broken layout, missing padding visible to users), High (inconsistent spacing, wrong colour), Medium (minor alignment, typography scale deviation), Low (cosmetic). Include the viewport width and page path for each finding."
3. Wait for the full report

---

## Step 3: Review Results

**Goal**: Triage findings and drive fixes.

**Actions**:
1. Present findings to the Stakeholder by severity with screenshot references
2. Based on findings:
   - **Critical/High** — hand to `fullstack-engineer` with exact element, page, and expected vs actual value. Re-run audit on fixed components.
   - **Medium/Low** — present to Stakeholder, ask whether to fix now or log as a known cosmetic issue
3. Fix loop:
   - `fullstack-engineer` applies CSS/Tailwind fix
   - Re-launch `ui-ux-engineer` targeting only the fixed components to confirm resolution

---

## Step 4: Summary

**Actions**:
1. Mark all todos complete
2. Deliver a final summary:
   - Pages/components audited
   - Breakpoints tested
   - Findings by severity: X critical, Y high, Z medium, W low
   - Fixes applied during this session
   - Known accepted cosmetic issues (with Stakeholder sign-off noted)
   - Design baseline used (Tailwind config version / Figma spec link if provided)
