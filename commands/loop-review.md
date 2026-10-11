---
description: Weekly data-grounded review of the nightshift daemon with the loop-engineer agent — reads the success indicators, closes last week's hypotheses with this week's numbers, ranks findings by the metric they move, and writes the review to the ledger. Proposes changes; never ships them.
argument-hint: window in days (optional — defaults to 7)
---

# Loop Review

You are triggering the weekly metrics review. The `loop-engineer` agent owns the daemon and
already knows how to diagnose it — **you are not reviewing the loop yourself, and you are
not writing a second reviewer.** This command gathers the evidence, hands it over with the
procedure, and files the result where the next review can find it.

The user is the **Product Stakeholder and owner**. The loop spends their money unattended;
the review tells them what it bought, what it cost, and what — if anything — is worth
changing. It does not change anything itself.

Use TodoWrite to track the steps.

---

## Step 1: Resolve the window and the state dir

Window: `$ARGUMENTS` days, default `7`. Reject anything that is not a positive integer.

The daemon's state dir comes from the **rendered LaunchAgent plist**, not from re-deriving
config (on this host the two disagree — the agent file explains why). Extract the named key
only; never grep the plist by structure, it holds credentials:

```bash
PLIST=$(ls ~/Library/LaunchAgents/com.copilot-ado-loop.*.plist | grep -v '\.bak\.' | grep -v retired | head -1)
STATE_DIR=$(plutil -extract EnvironmentVariables.COPILOT_ADO_LOOP_STATE_DIR raw -o - "$PLIST")
```

The loop repo is `~/Documents/workspace/copilot-ado-loop-v2` (binary `nightshift`; the
`copilot-ado-loop` alias is the same file). Never `cd` into the primary checkout to make
changes — this command makes none, so reading from it is fine.

## Step 2: Gather the evidence

Run all three and keep the raw output for the agent. Do not interpret it yet.

```bash
nightshift metrics --state-dir "$STATE_DIR" --window-days "$DAYS" --compare --json
nightshift digest  --state-dir "$STATE_DIR" --window-hours $((DAYS * 24)) --json   # exit 3 = stalled
nightshift metrics --state-dir "$STATE_DIR" --window-days "$DAYS" --compare          # the text table, for the ledger
```

Then read, from the loop repo:

- `docs/metrics-review.md` — the procedure and the review template
- `docs/success-metrics.md` — definitions, sample floors, guard metrics
- `tasks/metrics-reviews/README.md` — the open-hypotheses index
- the most recent `tasks/metrics-reviews/*.md` — last week's review

Note two things before dispatching:

- **Coverage.** The metrics output ends with a coverage footer. If it names kinds that are
  not instrumented in this window, the headline numbers that depend on them are not real
  yet; the review must say so rather than reading zeros as results.
- **Sample floor.** If fewer tickets shipped than `docs/success-metrics.md` sets as the
  floor, per-ticket rates are reported as "insufficient sample" — the review still runs
  (stalls, spend, provider rates do not need shipped tickets) but draws no per-ticket
  conclusions.

## Step 3: Dispatch the loop-engineer

Invoke the `loop-engineer` agent once, with: the three outputs from Step 2 verbatim, the
window, the state dir, and the four files above. Ask it to follow `docs/metrics-review.md`
exactly and to return the review in that template. Make these constraints explicit in the
prompt, because they are the ones that drift:

1. **Close every open hypothesis first**, with this week's numbers against the target and
   guard recorded when it was opened: `validated` / `ineffective` / `inconclusive` (sample
   below floor → stays open, say why).
2. **Rank findings by the headline metric they move and by how much.** A finding with no
   indicator attached is an observation and goes in the notes, not the ranking.
3. **Approval waits are health.** Gate-wait time is reported for the Stakeholder, never
   proposed as something the loop should shorten.
4. **Every proposal is a hypothesis block**: target metric + direction + expected size,
   guard metric, falsifier, sample needed. No code, no deploy, no ADO writes — the agent
   has comment-only ADO access and must sign any comment as agent-authored.
5. **A `stalled` digest leads the review.** Everything else still runs.

Wait for the agent. Do not start a second one, and do not patch its output beyond
formatting — if the review is wrong, the fix is a better prompt next week, recorded in
`tasks/lessons.md`.

## Step 4: File the review

In the loop checkout, under `tasks/metrics-reviews/`. That directory is untracked on
purpose — `/tasks` is gitignored since #325 because it holds private operational detail —
so nothing here needs a branch or a commit (`docs/metrics-review.md` says how to opt that
one directory back into version control if the Stakeholder wants reviews in history):

- write `tasks/metrics-reviews/<YYYY-MM-DD>.md` with the agent's review in the template
- update `tasks/metrics-reviews/README.md`: move closed hypotheses to the history table with
  their verdict and the review date; add new ones to the open table
- append to `tasks/lessons.md` only if the Stakeholder corrected something this run

Then show the Stakeholder the verdict line, the headline table, and the proposals, and
**stop**. Any change the review proposes is dispatched separately — a review that ships
code is no longer an auditable reading of the data.

## When not to run this

- The daemon has been deployed with the metrics telemetry for less than one full window —
  the coverage footer will say so; wait rather than review half-instrumented data.
- An incident is in progress — that is `loop-engineer` directly, or `/incident` if it is the
  delivered application, not a weekly review.
