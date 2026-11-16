---
description: Review open docs-first spec PRs with the spec-reviewer agent. Requests changes on the ones with real defects (verdict + spec:retry label) and hands the approve-worthy ones back to you to merge.
argument-hint: PR number(s) or ADO id(s) to review (optional — defaults to every open spec PR)
---

# Spec Review

You are triggering spec review. The `spec-reviewer` agent already exists and is thorough —
**you are not reviewing the specs yourself, and you are not writing a second reviewer.**
The agent went unused for months not because it was inadequate but because nothing ever
invoked it: twelve spec PRs sat a median of 12 days, 17 at the tail, against a 3.9h median
once someone actually looked. This command is that trigger.

The user is the **Product Stakeholder and owner**. Merging a spec is their approval act and
it commits real money to unattended implementation.

Use TodoWrite to track progress across PRs.

---

## Step 1: Find the spec PRs

Review target: $ARGUMENTS

- **If `$ARGUMENTS` names PRs or ADO ids** — use exactly those. An ADO id maps to the PR
  whose head branch is `spec/ado-<id>-…`.
- **If `$ARGUMENTS` is empty** — every open PR whose head branch starts with `spec/`:

```bash
gh pr list --repo {GITHUB_REPO} --state open \
  --json number,title,headRefName,updatedAt,reviewDecision --limit 100 \
  --jq '[.[] | select(.headRefName | startswith("spec/"))]'
```

Implementation PRs (`feature/…`) are **out of scope** — this command reviews specs. If the
user named one, say so and stop rather than reviewing it against the wrong bar.

Report the list before starting, with a count. If it is large, say roughly how long it will
take — each review is a real agent run, not a glance.

## Step 2: Review each PR

Run the `spec-reviewer` agent once per PR. Launch independent PRs **in parallel** (multiple
tool calls in one message) — they do not depend on each other.

Give each agent: the PR number, the ADO work item id from the branch name, and the repo.
Tell it to follow its own checklist. Do not summarise the spec for it or pre-judge the
verdict — it verifies claims against the real tree, which is the entire value.

**Override its merge autonomy for this command.** State plainly in the prompt:

> Do not merge, whatever you score it. The Stakeholder is keeping the merge click for
> themselves on this pass. If you would have merged, say so and why — that calibration is
> useful — but hand it back.

This overrides the agent's own "When You May Merge" section. Everything else in its
instructions stands.

## Step 3: Act on each verdict

**REQUEST CHANGES** — the agent posts its own verdict and signal, per its "How to Request
Changes" section. On a loop-opened PR that is a verdict comment followed by the
`spec:retry` label, because the loop and the reviewer share one bot account and GitHub
refuses a changes-requested review from a PR's own author. A formal `REQUEST_CHANGES`
review applies only to a PR some other account opened. Verify it actually landed rather
than trusting the report:

```bash
gh api --paginate repos/{GITHUB_REPO}/issues/<n>/comments \
  --jq '.[] | {user: .user.login, at: .created_at, head: (.body | split("\n")[0])}' | tail -n 3
gh api --paginate repos/{GITHUB_REPO}/issues/<n>/events \
  --jq '.[] | select(.label.name == "spec:retry") | {event, at: .created_at, actor: .actor.login}' | tail -n 2
gh pr view <n> --repo {GITHUB_REPO} --json reviewDecision,labels \
  --jq '{reviewDecision, labels: [.labels[].name]}'
```

Three things must hold, and each one catches a failure that has happened:

1. **A verdict comment from this run exists**, posted by the bot account, whose first line
   names **this** PR and ADO id. Parallel reviewers have cross-posted, and a write with an
   empty bot token lands under the Stakeholder's account without any error.
2. **A `labeled` event exists that is later than that comment.** An older
   `labeled`/`unlabeled` pair belongs to an earlier rejection of the same spec and says
   nothing about this one.
3. **For a PR another account opened only:** `reviewDecision` is `CHANGES_REQUESTED`. On a
   loop-opened PR it is always empty, so do not read it as a failure there.

An `unlabeled` event after the new `labeled` one is the loop having picked the rejection
up; the label being gone is the normal case, not a problem, and is not something to ask
the Stakeholder to fix.

A prose verdict that set no review state and applied no label is the failure mode this
whole command exists to avoid — it looks like a rejection and blocks nothing. If the
verdict comment is there but no `labeled` event postdates it, apply the label yourself
under the bot token, following step 3 of the agent's sequence (remove it first if it is
already on the PR), and say that you had to. Do not post the comment again.

**APPROVE / NEEDS YOUR CALL** — do **not** merge, do **not** label, do **not** close.
Report it for the Stakeholder with the PR link and a one-line rationale.

**Never close a PR.** Abandoning a spec is a product decision.

## Step 4: Report

Lead with a table the Stakeholder can act on without reading further:

| ADO | PR | Verdict | One-line reason | Action taken |
|---|---|---|---|---|

Then, per PR needing their attention, the agent's bullets. Keep it short.

End with the merge list — just the PRs awaiting their click, as links — so approving is one
pass down the list.

State plainly which checks could not run (ADO unreachable, etc.). A skipped check that goes
unmentioned is worse than one reported as skipped.

---

## What Happens After

For each PR you flagged, the loop picks the signal up on a following cycle, moves the work
item to `Spec Rejected`, and pushes a new spec version **to the same branch** so the PR
stays open and the revision reads as a diff. Expect a few minutes, not seconds.

The feedback the revision answers is the verdict text on the PR. This works because the
loop's PR-feedback window carries a one-hour lookback (`PR_FEEDBACK_LOOKBACK_MS`,
copilot-ado-loop `src/github/client.ts`) — the signal always postdates the comment, so
without it the revision would be authored against nothing. Worth knowing when a v2 comes
back having ignored the feedback: check whether the comment was in window before concluding
the model ignored it.

The same window is why a stuck label matters. The loop reads comments from the hour
before the moment it acts, so if the daemon is paused or backed off and `spec:retry` is
still on a PR about 45 minutes after its verdict comment, report it: past the hour the
verdict falls out of the window and the spec is re-authored against nothing.

## Attribution

Every write you or the agent make on the Stakeholder's behalf must be self-identifying.
A bare `gh` acts as the Stakeholder; agent writes go through
`GH_TOKEN=$(gh auth token --user {AGENT_GH_LOGIN})`, and an empty token falls back to the
Stakeholder's account silently, so check it is non-empty first. Never run `gh auth switch` — the
loop daemon resolves the keyring's active account live on every spawn, so switching would
silently change the identity of automated work mid-cycle.
