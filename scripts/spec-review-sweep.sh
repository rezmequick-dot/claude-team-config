#!/usr/bin/env bash
# spec-review-sweep.sh — give the spec-reviewer agent a trigger.
#
# ## Why this exists
#
# The `spec-reviewer` agent was already written, already good, and almost never run.
# It only fired when someone invoked it by hand in a session, so in practice nothing
# reviewed a queued spec PR. Measured 2026-09-26: twelve spec PRs open, median age 12
# days, oldest 17 — while the same review took a 3.9h median once somebody actually
# looked. The review capability was never the bottleneck. The trigger was.
#
# This is that trigger, and nothing more. It contains no review logic: every judgement
# lives in `~/.claude/agents/spec-reviewer.md`, which stays the single source of what
# "reviewed" means. Adding a check here instead of there is how the two drift.
#
# ## Why it runs locally and not in CI or a cloud routine
#
# The agent's checks need things only a local run has:
#
#   * The target repo's real tree. It verifies change sites with `git ls-tree
#     origin/main` and finds sibling-spec collisions by grepping `docs/specs/*/spec.md`,
#     because the whole point is to distrust the spec's own assertions.
#   * The `azure-devops` MCP server. Its first and mandatory check compares the spec
#     against the ADO work item AND its comments. That server is configured at user
#     scope on this machine and is routinely absent from headless and cloud runs.
#
# A run missing either degrades safely rather than silently: the agent is required to
# report an unperformed check, and an unperformed check disqualifies it from merging
# anything (see "When You May Merge"). It will recommend instead. That guard exists
# because on 2026-09-16 a seven-PR audit returned a verdict on every PR while reviewing
# specs alone, having had no ADO tools — and it only surfaced in its own caveats.
#
# ## Usage
#
#   spec-review-sweep.sh [--dry-run]
#
# Environment:
#   TARGET_REPO   Path to the checkout to review in.      (required)
#   GH_BOT_LOGIN  gh account for writes; reviews and merges are attributed to it.
#                 (required — a bare `gh` would attribute them to the Stakeholder)
#   MAX_PRS       Most PRs to review per run. Default 6.
#   STATE_DIR     Where the run log goes. Default ~/.local/state/spec-review-sweep.
#
# Exit codes: always 0 unless the environment is unusable. A sweep is a background
# convenience; a non-zero exit from a LaunchAgent just produces noise in the system log.

set -uo pipefail

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

if [ -z "${TARGET_REPO:-}" ] || [ ! -d "${TARGET_REPO}/.git" ]; then
  echo "error: TARGET_REPO must point at a git checkout (got '${TARGET_REPO:-<unset>}')." >&2
  exit 1
fi
if [ -z "${GH_BOT_LOGIN:-}" ]; then
  echo "error: GH_BOT_LOGIN is required; a bare gh attributes writes to the Stakeholder." >&2
  exit 1
fi

MAX_PRS="${MAX_PRS:-6}"
STATE_DIR="${STATE_DIR:-$HOME/.local/state/spec-review-sweep}"
mkdir -p "$STATE_DIR"
LOG="$STATE_DIR/sweep.log"

log() { printf '%s %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" | tee -a "$LOG"; }

# Resolve the bot token once. `gh auth token --user` is used rather than reading the
# keychain directly: the keychain entry is a `go-k…` wrapper, not the token, and 401s.
# Never printed — only exported into the child.
if ! BOT_TOKEN=$(gh auth token --user "$GH_BOT_LOGIN" 2>/dev/null) || [ -z "$BOT_TOKEN" ]; then
  log "error: could not resolve a token for '$GH_BOT_LOGIN'; nothing attributable to write with."
  exit 1
fi

cd "$TARGET_REPO" || exit 1
git fetch origin --quiet 2>/dev/null || log "warn: git fetch failed; tree checks may use a stale origin/main"

# Spec PRs carry the `spec: ADO-NNN — …` title the docs-first spec stage writes. Matching
# the title rather than a label because nothing applies a label, and matching the branch
# would also catch implementation branches for the same ticket.
PRS=$(gh pr list --state open --limit 50 --json number,title,headRefOid,isDraft \
  --jq '[.[] | select(.isDraft | not) | select(.title | startswith("spec:"))]' 2>/dev/null)

if [ -z "$PRS" ] || [ "$(printf '%s' "$PRS" | jq 'length')" = "0" ]; then
  log "no open spec PRs; nothing to review."
  exit 0
fi

log "found $(printf '%s' "$PRS" | jq 'length') open spec PR(s)."

REVIEWED=0
while IFS=$'\t' read -r NUMBER HEAD_SHA TITLE; do
  [ -z "$NUMBER" ] && continue
  if [ "$REVIEWED" -ge "$MAX_PRS" ]; then
    log "hit MAX_PRS=$MAX_PRS; stopping. Remaining PRs will be picked up next run."
    break
  fi

  SHORT_SHA="${HEAD_SHA:0:7}"

  # Idempotency, anchored to the PR rather than to local state.
  #
  # The marker is the agent's own posted verdict carrying the head sha it reviewed, so a
  # re-pushed spec is reviewed again while an unchanged one is not — and the record
  # survives this machine being rebuilt. A local "seen" file would not, and would also
  # silently re-review everything after a state-dir change.
  ALREADY=$(gh pr view "$NUMBER" --json comments \
    --jq "[.comments[] | select(.body | contains(\"spec-review: ${SHORT_SHA}\"))] | length" 2>/dev/null || echo 0)
  if [ "${ALREADY:-0}" != "0" ]; then
    log "#${NUMBER} already reviewed at ${SHORT_SHA}; skipping."
    continue
  fi

  if [ "$DRY_RUN" = "1" ]; then
    log "[dry-run] would review #${NUMBER} (${SHORT_SHA}) — ${TITLE}"
    REVIEWED=$((REVIEWED + 1))
    continue
  fi

  log "reviewing #${NUMBER} (${SHORT_SHA}) — ${TITLE}"

  # One PR per invocation, deliberately. A single prompt covering six PRs loses all six
  # when one review fails, and it invites the agent to economise by reusing one PR's tree
  # checks for another — which is exactly the check-did-not-run failure the merge gate
  # refuses to tolerate.
  PROMPT=$(cat <<EOP
Review spec PR #${NUMBER} in ${TARGET_REPO} ("${TITLE}"), head commit ${HEAD_SHA}.

Follow your full instructions, including "When You May Merge". You are running unattended
on a schedule, so nobody will read a question you ask back — decide, act within what you
are permitted to do, and record the reasoning on the PR.

Post your verdict as a PR comment. Begin that comment with exactly this marker line so a
later sweep can tell this revision has been reviewed:

    <!-- spec-review: ${SHORT_SHA} -->

Post the verdict BEFORE any merge, so the record survives a failed merge.
EOP
)

  # `--agent spec-reviewer` selects the reviewer; GH_TOKEN makes every write it performs
  # attributable to the bot rather than to the Stakeholder.
  if GH_TOKEN="$BOT_TOKEN" claude --agent spec-reviewer -p "$PROMPT" >>"$LOG" 2>&1; then
    log "#${NUMBER} review completed."
  else
    log "warn: review of #${NUMBER} exited non-zero; leaving it for the next sweep."
  fi
  REVIEWED=$((REVIEWED + 1))
done < <(printf '%s' "$PRS" | jq -r '.[] | "\(.number)\t\(.headRefOid)\t\(.title)"')

log "sweep done; reviewed=${REVIEWED}."
exit 0
