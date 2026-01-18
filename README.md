# Ralph (for copilot cli and claude)

![Ralph](ralph.webp)

Ralph is an autonomous AI agent loop that runs the Agent (github copilot cli, claude) repeatedly until all PRD items are complete. Each iteration is a fresh agent instance with clean context. Memory persists via git history, `progress.txt`, and `prd.json`.

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/).

[Read my in-depth article on how I use Ralph](https://x.com/ryancarson/status/2008548371712135632)

## Prerequisites

- [GitHub CLI (gh)](https://cli.github.com/) installed and the [Copilot extension](https://github.com/github/gh-copilot) installed (`gh extension install github/gh-copilot`)
- [PowerShell](https://github.com/PowerShell/PowerShell) installed (macOS/Linux: `pwsh`, Windows: `powershell`)
- `jq` installed (`brew install jq` on macOS)
- A git repository for your project

## Setup

### Option 1: Copy to your project

Copy the ralph files into your project:

```bash
# From your project root (macOS/Linux)
mkdir -p scripts/ralph
cp /path/to/ralph/ralph.sh scripts/ralph/
cp /path/to/ralph/ralph.ps1 scripts/ralph/
cp /path/to/ralph/prompt.md scripts/ralph/
chmod +x scripts/ralph/ralph.sh

# From your project root (Windows PowerShell)
New-Item -ItemType Directory -Path scripts\ralph -Force
Copy-Item \path\to\ralph\ralph.sh scripts\ralph\
Copy-Item \path\to\ralph\ralph.ps1 scripts\ralph\
Copy-Item \path\to\ralph\prompt.md scripts\ralph\
```

### Option 2: Use an alias or environment variable (RALPH_AGENT)

You can define which agent Ralph uses by setting the `RALPH_AGENT` environment variable. By default, it uses `gh copilot --allow-all-tools`.

```bash
# Bash example
export RALPH_AGENT="gh copilot --allow-all-tools"

# PowerShell example
$env:RALPH_AGENT = "gh copilot --allow-all-tools"
```

Ralph can handle large stories that exceed a single context window by breaking them into smaller, manageable user stories in `prd.json`.

## Workflow

### 1. Create a PRD

Use the PRD skill to generate a detailed requirements document:

```
Load the prd skill and create a PRD for [your feature description]
```

Answer the clarifying questions. The skill saves output to `tasks/prd-[feature-name].md`.

### 2. Convert PRD to Ralph format

Use the Ralph skill to convert the markdown PRD to JSON:

```
Load the ralph skill and convert tasks/prd-[feature-name].md to prd.json
```

This creates `prd.json` with user stories structured for autonomous execution.

### 3. Run Ralph

```bash
# Bash
./scripts/ralph/ralph.sh [max_iterations]

# PowerShell
.\scripts\ralph\ralph.ps1 [max_iterations]
```

Default is 10 iterations.

Ralph will:
1. Create a feature branch (from PRD `branchName`)
2. Pick the highest priority story where `passes: false`
3. Implement that single story
4. Run quality checks (typecheck, tests)
5. Commit if checks pass
6. Update `prd.json` to mark story as `passes: true`
7. Append learnings to `progress.txt`
8. Repeat until all stories pass or max iterations reached

## Key Files

| File | Purpose |
|------|---------|
| `ralph.sh` | The bash loop that spawns fresh agent instances |
| `ralph.ps1` | The PowerShell loop that spawns fresh agent instances |
| `prompt.md` | Instructions given to each Amp instance |
| `prd.json` | User stories with `passes` status (the task list) |
| `prd.json.example` | Example PRD format for reference |
| `progress.txt` | Append-only learnings for future iterations |
| `skills/prd/` | Skill for generating PRDs |
| `skills/ralph/` | Skill for converting PRDs to JSON |
| `flowchart/` | Interactive visualization of how Ralph works |

## Critical Concepts

### Each Iteration = Fresh Context

- Git history (commits from previous iterations)
- `progress.txt` (learnings and context)
- `prd.json` (which stories are done)

Ralph works with any agentic CLI (defaults to GitHub Copilot CLI). You can swap the agent by setting the `RALPH_AGENT` environment variable.

### Small Tasks

Each PRD item should be small enough to complete in one context window. If a task is too big, the LLM runs out of context before finishing and produces poor code.

Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

Too big (split these):
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

### AGENTS.md Updates Are Critical

After each iteration, Ralph updates the relevant `AGENTS.md` files with learnings. This is key because Amp automatically reads these files, so future iterations (and future human developers) benefit from discovered patterns, gotchas, and conventions.

Examples of what to add to AGENTS.md:
- Patterns discovered ("this codebase uses X for Y")
- Gotchas ("do not forget to update Z when changing W")
- Useful context ("the settings panel is in component X")

### Feedback Loops

Ralph only works if there are feedback loops:
- Typecheck catches type errors
- Tests verify behavior
- CI must stay green (broken code compounds across iterations)

### Browser Verification for UI Stories

Frontend stories should include clear acceptance criteria. Ralph will use the agent to implement and verify changes. If your agent supports browser interaction (like certain custom agents or extensions), you can include "Verify in browser" in the criteria.

### Stop Condition

When all stories have `passes: true`, Ralph outputs `<promise>COMPLETE</promise>` and the loop exits.

## Debugging

Check current state:

```bash
# See which stories are done
cat prd.json | jq '.userStories[] | {id, title, passes}'

# See learnings from previous iterations
cat progress.txt

# Check git history
git log --oneline -10
```

## Customizing prompt.md

Edit `prompt.md` to customize Ralph's behavior for your project:
- Add project-specific quality check commands
- Include codebase conventions
- Add common gotchas for your stack

## Archiving

Ralph automatically archives previous runs when you start a new feature (different `branchName`). Archives are saved to `archive/YYYY-MM-DD-feature-name/`.

## References

- [GitHub Copilot CLI](https://github.com/github/gh-copilot)
- [Geoffrey Huntley's Ralph article](https://ghuntley.com/ralph/)
