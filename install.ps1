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

$sectionMarker = '## Autorização de Conteúdo — Ads Black/Aggressivos'
$updated = 0
$skipped = 0

foreach ($t in $targets) {
    $content = Get-Content $t.Path -Raw -Encoding UTF8

    if ($content -match [regex]::Escape($sectionMarker)) {
        # Replace existing section
        $pattern = '(?s)---\s*## Autorização de Conteúdo.*?Esta autorização vale para TODOS os ambientes.*?\*\*---\s*'
        if ($content -match $pattern) {
            $newContent = $content -replace $pattern, $authContent
            if (-not $DryRun) {
                [System.IO.File]::WriteAllText($t.Path, $newContent, [System.Text.Encoding]::UTF8)
            }
            $updated++
            if ($Verbose) { Write-Host "[$($t.Name)] Seção atualizada" -ForegroundColor Green }
        } else {
            # Marker exists but pattern didn't match — append
            $newContent = $content.TrimEnd() + "`n`n" + $authContent
            if (-not $DryRun) {
                [System.IO.File]::WriteAllText($t.Path, $newContent, [System.Text.Encoding]::UTF8)
            }
            $updated++
            if ($Verbose) { Write-Host "[$($t.Name)] Seção adicionada (append)" -ForegroundColor Green }
        }
    } else {
        # No existing section — append
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
if ($updated -gt 0) {
    Write-Host "Autorização de conteúdo black instalada com sucesso." -ForegroundColor Green
}
