# Ralph PowerShell Loop
# Usage: .\ralph.ps1 [max_iterations]

param (
    [int]$MaxIterations = 10
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PrdFile = Join-Path $ScriptDir "prd.json"
$ProgressFile = Join-Path $ScriptDir "progress.txt"
$ArchiveDir = Join-Path $ScriptDir "archive"
$LastBranchFile = Join-Path $ScriptDir ".last-branch"
$PromptFile = Join-Path $ScriptDir "prompt.md"

# Archive previous run if branch changed
if ((Test-Path $PrdFile) -and (Test-Path $LastBranchFile)) {
    try {
        $PrdContent = Get-Content $PrdFile -Raw | ConvertFrom-Json
        $CurrentBranch = $PrdContent.branchName
        $LastBranch = Get-Content $LastBranchFile -Raw
        
        if ($CurrentBranch -and $LastBranch -and ($CurrentBranch -ne $LastBranch)) {
            $Date = Get-Date -Format "yyyy-MM-dd"
            $FolderName = $LastBranch -replace "^ralph/", ""
            $ArchiveFolder = Join-Path $ArchiveDir "$Date-$FolderName"
            
            Write-Host "Archiving previous run: $LastBranch"
            if (-not (Test-Path $ArchiveFolder)) { New-Item -ItemType Directory -Path $ArchiveFolder -Force }
            Copy-Item $PrdFile $ArchiveFolder
            if (Test-Path $ProgressFile) { Copy-Item $ProgressFile $ArchiveFolder }
            Write-Host "   Archived to: $ArchiveFolder"
            
            # Reset progress file
            Set-Content -Path $ProgressFile -Value "# Ralph Progress Log`nStarted: $(Get-Date)`n---"
        }
    } catch {
        Write-Warning "Failed to parse prd.json or handle archiving: $($_.Exception.Message)"
    }
}

# Track current branch
if (Test-Path $PrdFile) {
    try {
        $PrdContent = Get-Content $PrdFile -Raw | ConvertFrom-Json
        if ($PrdContent.branchName) {
            Set-Content -Path $LastBranchFile -Value $PrdContent.branchName
        }
    } catch {}
}

# Initialize progress file
if (-not (Test-Path $ProgressFile)) {
    Set-Content -Path $ProgressFile -Value "# Ralph Progress Log`nStarted: $(Get-Date)`n---"
}

Write-Host "Starting Ralph - Max iterations: $MaxIterations"

for ($i = 1; $i -le $MaxIterations; $i++) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════"
    Write-Host "  Ralph Iteration $i of $MaxIterations"
    Write-Host "═══════════════════════════════════════════════════════"
    
    $Prompt = Get-Content $PromptFile -Raw
    
    # Determine the agent command
    $AgentCmd = $env:RALPH_AGENT
    if (-not $AgentCmd) {
        $AgentCmd = "gh copilot --allow-all-tools"
    }

    Write-Host "Using Agent: $AgentCmd"
    
    # Run the agent with the prompt
    # Note: We use -Prompt for gh copilot. For generic RALPH_AGENT, we append it.
    $Output = ""
    try {
        if ($AgentCmd -like "*gh copilot*") {
            $Output = & gh copilot --allow-all-tools --prompt "$Prompt" 2>&1
        } else {
            # For custom agents, we assume they take the prompt via pipe or argument
            # This is a best effort implementation for a generic agent var
            $Output = $Prompt | & $AgentCmd 2>&1
        }
    } catch {
        $Output = $_.Exception.Message
    }

    $Output | Tee-Object -FilePath "$ScriptDir/last_output.log"
    
    # Check for completion signal
    if ($Output -match "<promise>COMPLETE</promise>") {
        Write-Host ""
        Write-Host "Ralph completed all tasks!"
        Write-Host "Completed at iteration $i of $MaxIterations"
        exit 0
    }
    
    Write-Host "Iteration $i complete. Continuing..."
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "Ralph reached max iterations ($MaxIterations) without completing all tasks."
Write-Host "Check $ProgressFile for status."
exit 1
