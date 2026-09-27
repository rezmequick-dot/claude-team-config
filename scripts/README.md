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

#### Full Disk Access is required, and without it the agent fails silently

**Do this before bootstrapping, or the sweep will never run.** Grant Full Disk Access to the
new agent in **System Settings → Privacy & Security → Full Disk Access**.

macOS TCC protects `~/Documents`, `~/Desktop` and `~/Downloads` from processes that have no
consent, and a **newly created** launchd agent has none. Both paths in the plist above live
under `~/Documents`: the script itself and `TARGET_REPO`. Verified on macOS 25.5 on
2026-09-27, with a real bootstrapped agent:

```
a) read script in ~/Documents:  DENIED
b) list target repo:            DENIED
c) git in target repo:          DENIED
d) source the sweep script:     DENIED
```

Two things make this easy to misdiagnose:

* **Consent does not transfer between agents.** An existing LaunchAgent on the same machine
  reading the same directories proves nothing about a new one — TCC is keyed to the agent,
  not to `/bin/bash`. On the machine above, the `copilot-ado-loop` daemon reads
  `~/Documents/workspace/…` all day while this agent could not read any of it.
* **Rooting the program outside `~/Documents` does not help.** Pointing
  `ProgramArguments` at `/usr/bin/caffeinate → /bin/bash → ~/.local/bin/…`, mirroring that
  working daemon exactly, was denied identically. The block is on reading the target paths,
  not on locating the program.

The failure mode is `/bin/bash: <path>: Operation not permitted` in
`StandardErrorPath` — and nowhere else. `launchctl list` reports the job as loaded and
healthy, so an uninstalled-but-loaded agent looks indistinguishable from a working one until
you read that log. If you cannot grant Full Disk Access, leave the agent **unloaded** rather
than loaded-and-failing, and run the script by hand from a terminal that already has consent.

**Never put a credential in the plist.** The script resolves the bot token at runtime via
`gh`; `GH_BOT_LOGIN` names an account, it is not a secret. A plist that holds a token leaks
it into every `.bak` the installer leaves behind, and `<string>` matches every value in a
plist, so any later grep over it prints the token.

**Validate the plist with a strict parser, not just `plutil -lint`.** `plutil -lint` accepts
XML that is not well-formed. A comment containing `--` (easily introduced by writing a flag
such as `gh auth token --user` in a comment) is illegal XML, and `plutil -lint` still reports
`OK`:

```bash
plutil -lint ~/Library/LaunchAgents/com.<you>.spec-review-sweep.plist   # necessary, not sufficient
python3 -c "import plistlib,sys; plistlib.loads(open(sys.argv[1],'rb').read())" \
  ~/Library/LaunchAgents/com.<you>.spec-review-sweep.plist              # the real check
```

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
