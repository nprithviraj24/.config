[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$ClaudeHome = (Join-Path $env:USERPROFILE ".claude"),
    [string]$GeminiHome = (Join-Path $env:USERPROFILE ".gemini"),
    [string]$CodexHome  = (Join-Path $env:USERPROFILE ".codex")
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


function Test-TreesMatch {
    param([string]$Left, [string]$Right)

    $leftFiles = @(Get-ChildItem -LiteralPath $Left -Recurse -File |
        ForEach-Object { $_.FullName.Substring($Left.Length).TrimStart('\') } | Sort-Object)
    $rightFiles = @(Get-ChildItem -LiteralPath $Right -Recurse -File |
        ForEach-Object { $_.FullName.Substring($Right.Length).TrimStart('\') } | Sort-Object)

    if (Compare-Object -ReferenceObject $leftFiles -DifferenceObject $rightFiles) {
        return $false
    }

    foreach ($rel in $leftFiles) {
        $lh = (Get-FileHash -LiteralPath (Join-Path $Left $rel) -Algorithm SHA256).Hash
        $rh = (Get-FileHash -LiteralPath (Join-Path $Right $rel) -Algorithm SHA256).Hash
        if ($lh -ne $rh) { return $false }
    }

    return $true
}

function Install-CodexSkill {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$SkillPath,
        [string]$OverlayPath,
        [string]$DestPath
    )

    # Codex cannot use a junction: its validator rejects frontmatter keys Claude
    # uses (argument-hint, disable-model-invocation), and it reads an extra
    # agents/openai.yaml. So it gets a copy with codex/<name>/ layered on top.

    # Assemble the expected tree first, so this stays idempotent: a re-run that
    # would produce what is already installed touches nothing and leaves no
    # backup. Without this, every run backs up a tree it just wrote itself.
    $staged = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $staged | Out-Null
    try {
        Copy-Item -Path (Join-Path $SkillPath "*") -Destination $staged -Recurse -Force
        if (Test-Path -LiteralPath $OverlayPath) {
            Copy-Item -Path (Join-Path $OverlayPath "*") -Destination $staged -Recurse -Force
        }

        if ((Test-Path -LiteralPath $DestPath) -and
            (Test-TreesMatch -Left $staged -Right $DestPath)) {
            Write-Host "Already current: $DestPath"
            return
        }

        # Anything here that is not what we would have written may be a local edit.
        if (Test-Path -LiteralPath $DestPath) {
            $existingItem = Get-Item -LiteralPath $DestPath -Force
            $isReparsePoint = [bool]($existingItem.Attributes -band [IO.FileAttributes]::ReparsePoint)
            if (-not $isReparsePoint) {
                Move-ToBackup -Path $DestPath -WhatIf:$WhatIfPreference
            } elseif ($PSCmdlet.ShouldProcess($DestPath, "Remove existing reparse point")) {
                Remove-Item -LiteralPath $DestPath -Force
            }
        }

        if ($PSCmdlet.ShouldProcess($DestPath, "Install skill from $SkillPath")) {
            if (Test-Path -LiteralPath $DestPath) {
                Remove-Item -LiteralPath $DestPath -Recurse -Force
            }
            Copy-Item -LiteralPath $staged -Destination $DestPath -Recurse
            if (Test-Path -LiteralPath $OverlayPath) {
                Write-Host "Copied $DestPath (+ overlay)"
            } else {
                Write-Host "Copied $DestPath"
            }
        }
    } finally {
        if (Test-Path -LiteralPath $staged) {
            Remove-Item -LiteralPath $staged -Recurse -Force
        }
    }
}

$skillsSource = Join-Path $RepoRoot "skills"
$codexOverlay = Join-Path $RepoRoot "codex"
$claudeSkillsPath = Join-Path $ClaudeHome "skills"
$geminiSkillsPath = Join-Path $GeminiHome "skills"
$codexSkillsPath  = Join-Path $CodexHome  "skills"

foreach ($dir in @($ClaudeHome, $claudeSkillsPath, $GeminiHome, $geminiSkillsPath, $CodexHome, $codexSkillsPath)) {
    Ensure-Directory -Path $dir -WhatIf:$WhatIfPreference
}

# Skills the overlay marks as not-for-Codex.
$excludeFile = Join-Path $codexOverlay "EXCLUDE"
$codexExcluded = @()
if (Test-Path -LiteralPath $excludeFile) {
    $codexExcluded = Get-Content -LiteralPath $excludeFile |
        Where-Object { $_.Trim() -and -not $_.Trim().StartsWith("#") } |
        ForEach-Object { $_.Trim() }
}

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
    Write-Host $skill.Name

    Ensure-Junction -LinkPath (Join-Path $claudeSkillsPath $skill.Name) `
        -TargetPath $skill.FullName -WhatIf:$WhatIfPreference
    Ensure-Junction -LinkPath (Join-Path $geminiSkillsPath $skill.Name) `
        -TargetPath $skill.FullName -WhatIf:$WhatIfPreference

    if ($codexExcluded -contains $skill.Name) {
        Write-Host "Skipped for codex (listed in codex/EXCLUDE)"
    } else {
        Install-CodexSkill -SkillPath $skill.FullName `
            -OverlayPath (Join-Path $codexOverlay $skill.Name) `
            -DestPath (Join-Path $codexSkillsPath $skill.Name) `
            -WhatIf:$WhatIfPreference
    }
}

Write-Host ""
Write-Host "Bootstrap complete."
Write-Host "  Claude: $claudeSkillsPath"
Write-Host "  agy:    $geminiSkillsPath"
Write-Host "  Codex:  $codexSkillsPath"
