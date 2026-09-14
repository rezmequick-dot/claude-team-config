#!/usr/bin/env bash
#
# PreToolUse/mcp__azure-devops__wit_work_item_comment_write — sign agent-written ADO comments.
#
# WHY
#   Azure DevOps authenticates as the Stakeholder (AAD-as-Jason). System.CreatedBy,
#   ChangedBy and ActivatedBy all read "Jason Anthony" for agent writes too — verified
#   2026-09-13, when an agent's own hyperlink write on ADO-533 was recorded as
#   ChangedBy: Jason Anthony. Unlike GitHub, there is no second identity available and no
#   way to add one, so the only place provenance can live is the comment body itself.
#
#   This is not cosmetic. On 2026-09-13 an agent read ADO attribution as proof of human
#   action and told the Stakeholder they had hand-authored work they had never touched.
#
# SCOPE
#   Fires only on comments written through the ADO MCP tool, which by definition means an
#   agent wrote them. The copilot-ado-loop daemon is unaffected: it performs its ADO writes
#   through its own harness client (AzCliAdoClient), never through this tool — the agent was
#   deliberately taken out of the ADO write path. So no loop-session guard is needed here.
#
# NOT COVERED — and this is the gap to remember
#   Structural writes (hyperlinks, state transitions, field and link changes) carry no
#   comment, so this hook cannot mark them. Nothing mechanical can. That case is an ambient
#   rule in CLAUDE.md: follow a structural ADO write with a short comment saying what changed
#   and why. The ADO-533/534 hyperlink backfill is the worked example — a silent structural
#   write, indistinguishable from a Stakeholder edit.
set -uo pipefail

SIGNATURE_TEXT="Posted by Claude Code on behalf of Jason Anthony."

input=$(cat)

text=$(printf '%s' "$input" | jq -r '.tool_input.text // empty')
[ -n "$text" ] || exit 0

# Idempotent: an `update` action re-sends existing body text, so never sign twice.
case "$text" in *"$SIGNATURE_TEXT"*) exit 0 ;; esac

# The tool accepts Markdown (its default) or Html; emit a separator valid in whichever is set.
format=$(printf '%s' "$input" | jq -r '.tool_input.format // "Markdown"')
if [ "$format" = "Html" ]; then
  signed="$text<br /><br /><hr /><em>$SIGNATURE_TEXT</em>"
else
  signed="$text

---
_${SIGNATURE_TEXT}_"
fi

printf '%s' "$input" | jq -c --arg t "$signed" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",updatedInput:(.tool_input + {text:$t})}}'
