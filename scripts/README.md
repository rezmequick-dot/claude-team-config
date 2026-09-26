# scripts/

Portable drivers for things that need to run on a schedule rather than when someone
happens to be in a session. They hold no judgement of their own — the judgement lives in
the agent each one invokes.

Like `hooks/`, nothing here is wired up by copying it across. Each script needs a
scheduler entry on the machine, and those entries carry concrete paths, so they are not
vendored.

## `spec-review-sweep.sh`

Gives the `spec-reviewer` agent a trigger.

The agent was written, good, and almost never run — it only fired when invoked by hand.
Measured 2026-09-26 on the turnoverly project: **twelve spec PRs open, median age 12 days,
oldest 17**, against a **3.9h median** time-to-merge once somebody actually looked. The
review capability was never the bottleneck; the trigger was.

The script finds open spec PRs, skips revisions already reviewed, and invokes
`claude --agent spec-reviewer -p` once per PR. It contains no review logic. Adding a check
here instead of in `agents/spec-reviewer.md` is how the two drift.

### It must run locally

Two of the agent's checks need what only a local run has:

- **The target repo's real tree** — change sites are verified with
  `git ls-tree origin/main`, and sibling-spec collisions by grepping `docs/specs/*/spec.md`.
  The point is to distrust the spec's own assertions, so a checkout is not optional.
- **The `azure-devops` MCP server** — the first and mandatory check compares the spec
  against the ADO work item *and its comments*. That server is user-scoped on the
  workstation and is routinely absent from headless and cloud runs.

A run missing either degrades safely rather than silently: the agent must report an
unperformed check, and an unperformed check disqualifies it from merging (see
`agents/spec-reviewer.md` → "When You May Merge"). It recommends instead. That guard is
there because on 2026-09-16 a seven-PR audit returned a verdict on every PR while
reviewing specs alone, having had no ADO tools — and the gap surfaced only in its own
caveats section.

### Environment

| Variable | Required | Notes |
|---|---|---|
| `TARGET_REPO` | yes | Path to the checkout to review in. |
| `GH_BOT_LOGIN` | yes | `gh` account for writes. A bare `gh` attributes the review — and any merge — to the Stakeholder. |
| `MAX_PRS` | no | Reviews per run. Default 6. |
| `STATE_DIR` | no | Run log location. Default `~/.local/state/spec-review-sweep`. |

Check what it would do before scheduling it:

```bash
TARGET_REPO=<path> GH_BOT_LOGIN=<bot> scripts/spec-review-sweep.sh --dry-run
```

### Scheduling it (macOS)

Write `~/Library/LaunchAgents/com.<you>.spec-review-sweep.plist`. Keep the cadence low —
see the cost note below.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.{YOU}.spec-review-sweep</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>{HOME}/Documents/workspace/claude-team-config/scripts/spec-review-sweep.sh</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>TARGET_REPO</key><string>{HOME}/Documents/workspace/{REPO}</string>
    <key>GH_BOT_LOGIN</key><string>{GH_BOT_LOGIN}</string>
    <key>MAX_PRS</key><string>4</string>
    <key>PATH</key><string>{HOME}/.local/bin:/opt/homebrew/bin:/usr/bin:/bin</string>
    <key>HOME</key><string>{HOME}</string>
  </dict>
  <key>StartCalendarInterval</key>
  <array>
    <dict><key>Hour</key><integer>8</integer><key>Minute</key><integer>17</integer></dict>
    <dict><key>Hour</key><integer>16</integer><key>Minute</key><integer>17</integer></dict>
  </array>
  <key>StandardOutPath</key><string>{HOME}/.local/state/spec-review-sweep/launchd.out.log</string>
  <key>StandardErrorPath</key><string>{HOME}/.local/state/spec-review-sweep/launchd.err.log</string>
</dict>
</plist>
```

```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.<you>.spec-review-sweep.plist
launchctl kickstart -k gui/$(id -u)/com.<you>.spec-review-sweep   # run it now
```

**Never put a credential in the plist.** The script resolves the bot token at runtime via
`gh auth token --user`; `GH_BOT_LOGIN` names an account, it is not a secret. A plist that
holds a token leaks it into every `.bak` the installer leaves behind, and `<string>`
matches every value in a plist, so any later grep over it prints the token.

### Cost, and the contention that actually matters

`spec-reviewer` is an opus agent doing real tool work per PR — an ADO fetch, tree checks,
sibling greps, a mergeability check. Budget roughly one substantial agent run per PR.

Where Claude Code authenticates against a Max subscription, this is not a dollar cost — it
is **allowance contention with anything else on the same subscription**. On this setup the
`copilot-ado-loop` daemon's implementation stage is cloud-only with no local fallback, so a
claude cooldown stalls it on `no_runnable_provider`. A sweep that burns allowance can
therefore starve delivery to review specs, which is the wrong trade.

So: start at twice a day with `MAX_PRS=4`, and watch the loop's provider outcomes for
cooldowns before widening. The queue that motivated this had a 12-day median; twice a day
is already two orders of magnitude faster than that, and there is nothing to gain from
polling harder.

### Turning it off

```bash
launchctl bootout gui/$(id -u)/com.<you>.spec-review-sweep
```

Removing the trigger leaves the agent exactly as it was — invokable by hand. Nothing else
depends on the sweep.
