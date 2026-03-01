# claude-team-config

Global [Claude Code](https://claude.ai/claude-code) configuration — a complete AI software delivery team built from custom agents and workflow commands.

## What's in here

| Directory | Contents |
|---|---|
| `CLAUDE.md` | Global rules, stakeholder policy, session start behaviour, agent roster |
| `agents/` | 14 custom agents covering the full delivery lifecycle |
| `commands/` | 12 slash commands that orchestrate agents into workflows |

---

## The Agent Team

| Agent | Role |
|---|---|
| `project-manager` | Requirements gathering, clarification, Stakeholder sign-off |
| `fullstack-engineer` | TypeScript/Node.js full-stack implementation |
| `senior-code-reviewer` | Code quality auditing, standards enforcement, scope validation |
| `qa-engineer` | Acceptance testing and negative testing against the running application |
| `devops-engineer` | CI/CD pipelines, infrastructure, secrets management, deployment |
| `security-engineer` | OWASP audits, CVE scanning, secrets detection, auth review |
| `database-architect` | Schema design, query optimisation, migration safety |
| `performance-engineer` | Load testing, Node.js profiling, bundle analysis |
| `technical-writer` | README, OpenAPI specs, ADRs, runbooks, changelogs |
| `dependency-auditor` | CVE scanning, license compliance, bloat reduction |
| `accessibility-engineer` | WCAG 2.1 AA compliance, keyboard nav, screen reader testing |
| `incident-responder` | Production incident diagnosis, restoration, post-mortems |
| `api-designer` | REST/GraphQL contract design, versioning, OpenAPI specs |
| `observability-engineer` | Structured logging, metrics, tracing, alerting, SLOs, dashboards |

---

## Workflow Commands

| Command | What it does |
|---|---|
| `/feature-dev` | Full 9-phase pipeline: PM → API design → explore → architect → build → review → security → QA → observability → docs → deploy |
| `/code-review` | Standalone senior code review against any files or git changes |
| `/qa` | Standalone QA validation against the locally running application |
| `/deploy` | Standalone deployment — new infra, feature deploys, rollbacks, audits |
| `/security-audit` | OWASP Top 10, CVE scanning, secrets detection, auth review |
| `/performance-test` | Load testing, profiling, bottleneck identification |
| `/accessibility-audit` | WCAG 2.1 AA audit with Playwright + axe-core |
| `/db-review` | Schema design, migration safety, query optimisation |
| `/dependency-audit` | CVE scanning, license compliance, unused packages, bloat |
| `/docs` | Generate README, OpenAPI spec, ADRs, runbook, changelog |
| `/api-design` | REST/GraphQL contract design and OpenAPI spec authoring |
| `/incident` | Production incident response — diagnose, restore, post-mortem |
| `/observability` | Set up or audit logging, metrics, tracing, alerting, and dashboards |

---

## Restoring this config on a new machine

### Prerequisites
- [Claude Code](https://claude.ai/claude-code) installed
- Git installed

### Steps

```bash
# 1. Clone this repo
git clone https://github.com/rezmequick-dot/claude-team-config.git

# 2. Copy agents, commands, and CLAUDE.md into your global Claude config directory
#    macOS / Linux
cp -r claude-team-config/agents ~/.claude/agents
cp -r claude-team-config/commands ~/.claude/commands
cp claude-team-config/CLAUDE.md ~/.claude/CLAUDE.md

#    Windows (PowerShell)
Copy-Item -Recurse claude-team-config\agents $env:USERPROFILE\.claude\agents
Copy-Item -Recurse claude-team-config\commands $env:USERPROFILE\.claude\commands
Copy-Item claude-team-config\CLAUDE.md $env:USERPROFILE\.claude\CLAUDE.md

# 3. Restart Claude Code — agents and commands will be available immediately
```

### Updating from this repo

```bash
cd claude-team-config
git pull

# macOS / Linux
cp -r agents ~/.claude/agents
cp -r commands ~/.claude/commands
cp CLAUDE.md ~/.claude/CLAUDE.md

# Windows (PowerShell)
Copy-Item -Recurse agents $env:USERPROFILE\.claude\agents
Copy-Item -Recurse commands $env:USERPROFILE\.claude\commands
Copy-Item CLAUDE.md $env:USERPROFILE\.claude\CLAUDE.md
```

---

## What is NOT included

| Excluded | Reason |
|---|---|
| `settings.json` | May contain tokens or personal configuration |
| `plugins/` | Third-party marketplace content — not custom config |
| `cache/`, `history/`, `projects/` | Local session state — machine-specific |

---

## Key principles baked into this config

- **You are the Product Stakeholder and owner.** No agent expands scope, reinterprets intent, or makes product decisions without your approval.
- **No paid infrastructure without explicit approval.** The `devops-engineer` and `observability-engineer` always present cost estimates first.
- **No production deployment without observability.** The `/deploy` command has an observability gate before the production approval gate.
- **Security before shipping.** The `security-engineer` runs after every implementation and blocks deployment on Critical/High findings.
- **Design before build.** The `project-manager` produces a spec and the `api-designer` produces contracts — both approved by you before any code is written.
