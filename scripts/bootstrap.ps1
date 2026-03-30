[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$ClaudeHome = (Join-Path $env:USERPROFILE ".claude")
)

$ErrorActionPreference = "Stop"

function Ensure-Directory {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        if ($PSCmdlet.ShouldProcess($Path, "Create directory")) {
            New-Item -ItemType Directory -Path $Path | Out-Null
        }
    }
}

function Move-ToBackup {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Path)

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = "$Path.backup-$timestamp"

    if ($PSCmdlet.ShouldProcess($Path, "Move to backup at $backupPath")) {
        Move-Item -LiteralPath $Path -Destination $backupPath
        Write-Host "Backed up existing path to $backupPath"
    }
}

function Ensure-Junction {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$LinkPath,
        [string]$TargetPath
    )

    if (-not (Test-Path -LiteralPath $TargetPath)) {
        throw "Target path does not exist: $TargetPath"
    }

    if (Test-Path -LiteralPath $LinkPath) {
        $existingItem = Get-Item -LiteralPath $LinkPath -Force
        $isReparsePoint = [bool]($existingItem.Attributes -band [IO.FileAttributes]::ReparsePoint)

        if ($isReparsePoint) {
            $currentTarget = $existingItem.Target
            if ($currentTarget -is [array]) {
                $currentTarget = $currentTarget[0]
            }

            if ($currentTarget) {
                $resolvedCurrent = [IO.Path]::GetFullPath($currentTarget)
                $resolvedTarget = [IO.Path]::GetFullPath($TargetPath)
                if ($resolvedCurrent -eq $resolvedTarget) {
                    Write-Host "Already linked: $LinkPath"
                    return
                }
            }

            if ($PSCmdlet.ShouldProcess($LinkPath, "Remove existing reparse point")) {
                Remove-Item -LiteralPath $LinkPath -Force
            }
        } else {
            Move-ToBackup -Path $LinkPath -WhatIf:$WhatIfPreference
        }
    }

    if ($PSCmdlet.ShouldProcess($LinkPath, "Create junction to $TargetPath")) {
        New-Item -ItemType Junction -Path $LinkPath -Target $TargetPath | Out-Null
        Write-Host "Linked $LinkPath -> $TargetPath"
    }
}

$skillsSource = Join-Path $RepoRoot "skills"
$claudeSkillsPath = Join-Path $ClaudeHome "skills"

Ensure-Directory -Path $ClaudeHome -WhatIf:$WhatIfPreference
Ensure-Directory -Path $claudeSkillsPath -WhatIf:$WhatIfPreference

if (-not (Test-Path -LiteralPath $skillsSource)) {
    throw "Skills directory not found: $skillsSource"
}

$managedSkills = Get-ChildItem -LiteralPath $skillsSource -Directory |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "SKILL.md") }

if (-not $managedSkills) {
    Write-Host "No repo-managed skills found under $skillsSource"
    return
}

foreach ($skill in $managedSkills) {
    $linkPath = Join-Path $claudeSkillsPath $skill.Name
    Ensure-Junction -LinkPath $linkPath -TargetPath $skill.FullName -WhatIf:$WhatIfPreference
}

Write-Host ""
Write-Host "Bootstrap complete."
Write-Host "Claude skills path: $claudeSkillsPath"
