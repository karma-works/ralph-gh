name: ralph-setup
description: Automatically set up the Ralph autonomous agent loop in a project. Use this skill when the user wants to enable autonomous development cycles in a repository by cloning the Ralph repository, setting up the necessary directory structure, and configuring the environment.
---
# Ralph Loop Setup

This skill automates the installation and configuration of the Ralph autonomous agent loop.

## Overview

Ralph is an autonomous agent loop that uses `gh copilot` to perform multi-step development tasks. This skill sets it up using the `karma-works/ralph-gh` repository.

## Setup Workflow

1. **Clone/Update Ralph**: Clone the Ralph repository into a `.ralph-repo` directory (or update if exists).
   - Repository: `https://github.com/karma-works/ralph-gh.git`
2. **Scaffold Project**: Create a `ralph/` directory in the target project root.
3. **Copy Assets**:
   - Copy `ralph.sh` (for macOS/Linux) or `ralph.ps1` (for Windows) from the repo to the project's `ralph/` directory.
   - Copy `prompt.md` to `ralph/prompt.md`.
   - Copy `AGENTS.md` to the project root.
4. **Initialize PRD**: Create a basic `prd.json` if it doesn't exist, following the template in the repo.
5. **Ignore Files**: Ensure `.ralph-repo`, `ralph/archives/`, and `ralph/progress.txt` are added to `.gitignore`.

## Commands

### Bash (macOS/Linux)
```bash
git clone https://github.com/karma-works/ralph-gh.git .ralph-repo
mkdir -p ralph
cp .ralph-repo/ralph/ralph.sh ralph/
cp .ralph-repo/ralph/prompt.md ralph/
cp .ralph-repo/ralph/AGENTS.md .
chmod +x ralph/ralph.sh
```

### PowerShell (Windows)
```powershell
git clone https://github.com/karma-works/ralph-gh.git .ralph-repo
New-Item -ItemType Directory -Force -Path ralph
Copy-Item .ralph-repo\ralph\ralph.ps1 ralph\
Copy-Item .ralph-repo\ralph\prompt.md ralph\
Copy-Item .ralph-repo\ralph\AGENTS.md .
```

## Verification
- Confirm `ralph/ralph.sh` (or `.ps1`) exists.
- Confirm `prompt.md` exists in `ralph/`.
- Confirm `AGENTS.md` exists in the root.
