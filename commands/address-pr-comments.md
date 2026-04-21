---
description: Ingest PR review comments (Copilot and human reviewers), classify each as fix / reply / defer, route fixes to the fullstack-engineer, reply + resolve review threads, and block merge until zero unresolved remain. Invoked as Phase 10.5 of /feature-dev.
argument-hint: PR number (e.g. 42) — or omit to resolve from the current branch
---

# Address PR Review Feedback

You are orchestrating the **post-PR review response step** for a feature delivery. The user is the **Product Stakeholder and owner** — you do not auto-merge and you do not dismiss a comment without either a fix or an explicit defer.

This command is a **hard gate** before merge: the next phase (merge + deploy) cannot proceed while review threads are unresolved, exactly like an unresolved High-severity security finding blocks release.

Use TodoWrite to track each review thread as its own task.

---

## Step 1: Locate the PR

**Actions**:
1. PR number: $ARGUMENTS
2. If empty, resolve from the current branch:
   ```bash
   gh pr view --json number,url,headRefName,state
   ```
   Abort with a clear message if no PR is open for the current branch.
3. Confirm the PR is in a reviewable state (not already merged or closed).

---

## Step 2: Collect All Review Comments

**Actions**:
1. Pull top-level reviews and timeline comments:
   ```bash
   gh pr view <num> --json reviews,comments,url,headRefOid
   ```
2. Pull inline (file-anchored) review comments:
   ```bash
   gh api repos/{owner}/{repo}/pulls/<num>/comments --paginate
   ```
3. Pull review threads with resolution state (needed for the resolve mutation in Step 5):
   ```bash
   gh api graphql -f query='
     query($owner:String!,$repo:String!,$num:Int!) {
       repository(owner:$owner, name:$repo) {
         pullRequest(number:$num) {
           reviewThreads(first:100) {
             nodes {
               id
               isResolved
               isOutdated
               comments(first:20) {
                 nodes { id databaseId author { login } path line body }
               }
             }
           }
         }
       }
     }' -F owner=<owner> -F repo=<repo> -F num=<num>
   ```
4. Build a working list of every **unresolved** thread with: thread id, latest comment id, author login, file path, line, and body.

---

## Step 3: Classify Each Unresolved Thread

For every unresolved thread, the **orchestrator** (you, not a sub-agent) picks one of:

- **fix** — valid bug / standard violation / missing test / doc gap. Requires a code change.
- **defend-with-reply** — the reviewer is mistaken or the existing code is correct by design. Requires a reply explaining why, with a citation to code or spec.
- **defer-to-followup-ticket** — valid but out of scope for this PR. Requires explicit Stakeholder approval AND a tracked follow-up (ADO work item or TODO with ticket reference).

**Rules**:
- Never auto-defer. Deferrals need Stakeholder approval in this session.
- Copilot comments are classified on merit, not dismissed as "AI noise". Most naming / docs / missing-test findings are valid.
- If a thread contains multiple distinct points, split them and classify each.

Present the classified list to the Stakeholder for review before acting. Proceed only after approval.

---

## Step 4: Execute Fixes

For each **fix** thread:

1. Launch the `fullstack-engineer` agent with a focused prompt:
   > "Address review comment on `<path>:<line>` by `<reviewer>`. Comment body:
   > ```
   > <body>
   > ```
   > Requirements: (a) make the minimum change that resolves the comment, (b) add or update a test that would have caught the original issue, (c) do not expand scope. Report the files changed and the test added."
2. After the agent reports, verify the diff yourself:
   - Read each changed file.
   - Confirm the test exists and actually exercises the fix (not a tautology).
3. Run the full local check between fixes if changes are non-trivial:
   ```bash
   npx tsc --noEmit && npx vitest run
   ```
4. Once all fixes for this round are in, stage and push a single commit with a clear message referencing the PR and the review round (e.g. `address PR #<num> review: rename cooldown env vars + docs`).

---

## Step 5: Reply and Resolve Threads

For every thread that now has a landed fix OR a defend-with-reply classification:

1. Post a reply on the review thread:
   ```bash
   # reply to an inline review comment
   gh api -X POST repos/{owner}/{repo}/pulls/<num>/comments/<comment_id>/replies \
     -f body='<reply>'
   ```
   Reply content:
   - **fix**: cite the commit SHA and the test that proves it.
   - **defend-with-reply**: explain the reasoning, cite the code or spec, thank the reviewer for the scrutiny.
   - **defer-to-followup-ticket**: link the follow-up ticket / ADO work item and note the Stakeholder approval.
2. Resolve the thread via GraphQL:
   ```bash
   gh api graphql -f query='
     mutation($threadId:ID!) {
       resolveReviewThread(input:{threadId:$threadId}) {
         thread { id isResolved }
       }
     }' -F threadId=<thread_node_id>
   ```
3. Do **not** resolve a thread you did not reply to. Every resolution needs a visible rationale for the reviewer.

---

## Step 6: Re-query and Loop

**Actions**:
1. Re-run the review-thread query from Step 2 to get the fresh unresolved count.
2. Also pull any new comments posted since the original query (reviewers may have replied to your replies).
3. If unresolved > 0:
   - New threads ⇒ go back to Step 3.
   - Existing threads not yet addressed ⇒ continue Step 4/5 for the remainder.
4. If unresolved == 0 **and** no new reviews were requested: proceed to Step 7.

---

## Step 7: Gate & Hand-off

**Actions**:
1. Confirm all CI checks are green:
   ```bash
   gh pr checks <num>
   ```
2. Summarise to the Stakeholder:
   - Number of threads addressed by each classification (fix / reply / defer).
   - Commits pushed in this round.
   - Any deferred follow-up tickets created.
   - Final CI status.
3. Hand back to `/feature-dev` Phase 10.75 (Merge & Deploy). **Do not merge from this command.**

---

## Hard gates

- Unresolved review threads block merge — same severity as unresolved High security findings.
- A thread may only be resolved with a visible reply explaining the outcome.
- Deferrals require Stakeholder approval AND a tracked follow-up item. Never silently defer.
- Every fix lands with a test that would have caught the original issue. "Fixed it, trust me" is not acceptable.
