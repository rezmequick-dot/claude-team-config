# Hooks

`PreToolUse` hooks that make agent-authored actions self-identifying.

These are **enforcement**, not instruction. The rules they encode already existed as written
guidance and did not hold: the agent GitHub account was created 2026-09-02 with a documented
instruction to use it, and on 2026-09-08 an agent session opened turnoverly spec PRs #767 and
#768 as `rezmequick-dot` anyway. Days later those PRs were read as the Stakeholder's own
hand-authored work and a diagnosis was built on that false premise. A hook does not depend on
what the model remembered.

Hooks **rewrite** the call rather than blocking it — the action still happens, correctly
attributed.

| Hook | Fires on | Effect |
|---|---|---|
| `ado-comment-signature.sh` | `mcp__azure-devops__wit_work_item_comment_write` | Appends `_Posted by Claude Code on behalf of Jason Anthony._` to the comment body |
| `gh-bot-identity.sh` | `Bash` | Reruns mutating `gh` commands under the `earthandwater-beep` token |

## Install

Copying a script here is not enough — hooks must also be registered. `settings.json` is not
vendored in this repo because it holds machine-specific MCP config and permissions.

1. Copy the scripts and make them executable:

   ```sh
   mkdir -p ~/.claude/hooks
   cp hooks/*.sh ~/.claude/hooks/
   chmod +x ~/.claude/hooks/*.sh
   ```

2. Merge into `~/.claude/settings.json` (additive — keep any existing `hooks` entries):

   ```json
   "hooks": {
     "PreToolUse": [
       {
         "matcher": "Bash",
         "hooks": [
           { "type": "command", "command": "/Users/<you>/.claude/hooks/gh-bot-identity.sh", "timeout": 10 }
         ]
       },
       {
         "matcher": "mcp__azure-devops__wit_work_item_comment_write",
         "hooks": [
           { "type": "command", "command": "/Users/<you>/.claude/hooks/ado-comment-signature.sh", "timeout": 10 }
         ]
       }
     ]
   }
   ```

   The `Bash` matcher deliberately carries no `if: "Bash(gh *)"` filter. That filter matches on
   command prefix, so `cd repo && gh pr create ...` would slip past it — and a large share of
   agent commands start with `cd`. Silently missing those costs more than running a script
   that exits in milliseconds.

3. Review or disable any hook later with `/hooks`.

## Verifying

Test a script directly by piping it the payload shape it expects:

```sh
echo '{"tool_name":"mcp__azure-devops__wit_work_item_comment_write","tool_input":{"action":"add","workItemId":1,"text":"hello"}}' \
  | ~/.claude/hooks/ado-comment-signature.sh | jq -r '.hookSpecificOutput.updatedInput.text'
```

For `gh-bot-identity.sh` the check that matters is behavioural, and it has **two** halves:

- an agent-authored PR must show `earthandwater-beep`
- the next **loop**-authored turnoverly PR must still show `rezmequick-dot`

The second is the one to watch. The copilot-ado-loop daemon has no token of its own, resolves
the keyring's active account live on every spawn, and its provider CLIs are Claude Code
sessions reading this same user-scope config — so a careless matcher flips the *loop's*
identity, which is the opposite of the intent. The script guards against this three ways
(loop env vars, an already-set `GH_TOKEN`, and the loop-owned checkout path) and is biased
toward doing nothing: a missed rewrite costs one manual prefix, a wrong one corrupts the
provenance of automated work.

## What hooks cannot cover

Structural ADO writes — hyperlinks, state transitions, field and link changes — carry no
comment, so nothing mechanical can mark them. That case is a standing rule in `CLAUDE.md`:
follow a structural ADO write with a short comment saying what changed and why.

## Status: `gh-bot-identity.sh` is not yet in this repo

Claude Code's permission classifier blocks the agent from authoring it — a script that
intercepts shell commands and substitutes a credential is exactly the kind of thing an agent
should not be able to write unreviewed, and that judgement is correct. It has to be added by
the Stakeholder, which also guarantees the security-relevant script gets read by a human
before it starts intercepting every command.
