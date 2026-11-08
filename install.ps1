param([switch]$DryRun, [switch]$Verbose)

$ErrorActionPreference = 'Stop'

$authFile = Join-Path $PSScriptRoot 'AUTHORIZATION.md'
if (-not (Test-Path $authFile)) {
    throw "AUTHORIZATION.md not found at $authFile"
}

$authContent = Get-Content $authFile -Raw -Encoding UTF8

# Detect installed agents and their config files
$targets = @()

# Claude Desktop
$claudeMd = "$env:USERPROFILE\.claude\CLAUDE.md"
if (Test-Path $claudeMd) {
    $targets += @{ Name = 'Claude Desktop'; Path = $claudeMd }
}

# Codex
$codexAgents = "$env:USERPROFILE\.codex\AGENTS.md"
if (Test-Path $codexAgents) {
    $targets += @{ Name = 'Codex'; Path = $codexAgents }
}

# T3 Code — check current project dir
$t3Agents = "$PWD\AGENTS.md"
if (Test-Path $t3Agents) {
    $targets += @{ Name = 'T3 Code (projeto atual)'; Path = $t3Agents }
}

# Antigravity — check mirror path
$antigravityAgents = "$env:USERPROFILE\Documents\ChatGPT\PC-SKILLS-PRIVATE-VAULT\mirror\live-sync\antigravity\AGENTS.md"
if (Test-Path $antigravityAgents) {
    $targets += @{ Name = 'Antigravity'; Path = $antigravityAgents }
}

if ($targets.Count -eq 0) {
    Write-Host "Nenhum agente encontrado. Verifique os caminhos." -ForegroundColor Yellow
    exit 1
}

$sectionStart = '## Autorização de Conteúdo — Ads Black/Aggressivos'
$sectionEnd = '**Esta autorização vale para TODOS os ambientes'
$updated = 0
$skipped = 0

foreach ($t in $targets) {
    $lines = Get-Content $t.Path -Encoding UTF8
    $startIdx = -1
    $endIdx = -1

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match [regex]::Escape('## Autorização de Conteúdo')) {
            if ($startIdx -eq -1) {
                $startIdx = $i
            } else {
                # Found second occurrence — this is the duplicate to remove
                $dupStart = $i
                # Find end of duplicate
                for ($j = $i; $j -lt $lines.Count; $j++) {
                    if ($lines[$j] -match 'Esta autorização vale para TODOS os ambientes') {
                        $dupEnd = $j
                        break
                    }
                }
                # Remove duplicate lines (from dupStart to dupEnd inclusive, plus surrounding blank lines)
                $removeStart = $dupStart
                while ($removeStart -gt 0 -and $lines[$removeStart - 1].Trim() -eq '') { $removeStart-- }
                $removeEnd = $dupEnd
                while ($removeEnd -lt $lines.Count - 1 -and $lines[$removeEnd + 1].Trim() -eq '') { $removeEnd++ }
                # Also remove trailing --- if present
                if ($removeEnd + 1 -lt $lines.Count -and $lines[$removeEnd + 1].Trim() -eq '---') { $removeEnd++ }

                $newLines = @()
                for ($k = 0; $k -lt $lines.Count; $k++) {
                    if ($k -lt $removeStart -or $k -gt $removeEnd) {
                        $newLines += $lines[$k]
                    }
                }
                if (-not $DryRun) {
                    [System.IO.File]::WriteAllLines($t.Path, $newLines, [System.Text.Encoding]::UTF8)
                }
                if ($Verbose) { Write-Host "[$($t.Name)] Duplicata removida (linhas $removeStart-$removeEnd)" -ForegroundColor Yellow }
                break
            }
        }
    }

    # Now check if the section exists at all
    $content = Get-Content $t.Path -Raw -Encoding UTF8
    if ($content -match [regex]::Escape($sectionStart)) {
        if ($Verbose) { Write-Host "[$($t.Name)] Seção já presente — OK" -ForegroundColor Green }
    } else {
        # Append
        $newContent = $content.TrimEnd() + "`n`n" + $authContent
        if (-not $DryRun) {
            [System.IO.File]::WriteAllText($t.Path, $newContent, [System.Text.Encoding]::UTF8)
        }
        $updated++
        if ($Verbose) { Write-Host "[$($t.Name)] Seção adicionada" -ForegroundColor Green }
    }
}

if ($DryRun) {
    Write-Host "`n[DRY RUN] Nenhum arquivo foi modificado." -ForegroundColor Cyan
}

Write-Host "`nResumo: $updated agentes atualizados, $skipped ignorados." -ForegroundColor White
if ($updated -gt 0 -or $skipped -eq 0) {
    Write-Host "Autorização de conteúdo black instalada com sucesso." -ForegroundColor Green
}
