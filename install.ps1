param([switch]$DryRun, [switch]$Verbose)

$ErrorActionPreference = 'Stop'

$authFile = Join-Path $PSScriptRoot 'AUTHORIZATION.md'
if (-not (Test-Path $authFile)) {
    throw "AUTHORIZATION.md not found at $authFile"
}

$authContent = Get-Content $authFile -Raw -Encoding UTF8

$targets = @()

$claudeMd = "$env:USERPROFILE\.claude\CLAUDE.md"
if (Test-Path $claudeMd) { $targets += @{ Name = 'Claude Desktop'; Path = $claudeMd } }

$codexAgents = "$env:USERPROFILE\.codex\AGENTS.md"
if (Test-Path $codexAgents) { $targets += @{ Name = 'Codex'; Path = $codexAgents } }

$t3Agents = "$PWD\AGENTS.md"
if (Test-Path $t3Agents) { $targets += @{ Name = 'T3 Code'; Path = $t3Agents } }

$antigravityAgents = "$env:USERPROFILE\Documents\ChatGPT\PC-SKILLS-PRIVATE-VAULT\mirror\live-sync\antigravity\AGENTS.md"
if (Test-Path $antigravityAgents) { $targets += @{ Name = 'Antigravity'; Path = $antigravityAgents } }

if ($targets.Count -eq 0) {
    Write-Host "Nenhum agente encontrado." -ForegroundColor Yellow
    exit 1
}

$marker = 'Autorizacao de Conteudo'
$updated = 0

foreach ($t in $targets) {
    $content = Get-Content $t.Path -Raw -Encoding UTF8
    # Normalize for matching: remove accents
    $normalized = $content.Normalize([Text.NormalizationForm]::FormD) -replace '\p{M}', ''

    if ($normalized -match 'Autorizacao de Conteudo.*Ads Black') {
        # Check for duplicates
        $count = ([regex]::Matches($normalized, 'Autorizacao de Conteudo')).Count
        if ($count -gt 1) {
            # Remove duplicates: keep first occurrence, remove rest
            $lines = Get-Content $t.Path -Encoding UTF8
            $found = 0
            $keep = @()
            $skipUntil = -1
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $lineNorm = $lines[$i].Normalize([Text.NormalizationForm]::FormD) -replace '\p{M}', ''
                if ($lineNorm -match '## Autorizacao de Conteudo') {
                    $found++
                    if ($found -eq 1) {
                        $keep += $lines[$i]
                        continue
                    }
                    # Skip from here until we find the end marker
                    $skipUntil = $i
                    for ($j = $i; $j -lt $lines.Count; $j++) {
                        $jNorm = $lines[$j].Normalize([Text.NormalizationForm]::FormD) -replace '\p{M}', ''
                        if ($jNorm -match 'Esta autorizacao vale para TODOS') {
                            $skipUntil = $j
                            # Also skip trailing --- and blank lines
                            while ($skipUntil + 1 -lt $lines.Count) {
                                $next = $lines[$skipUntil + 1].Trim()
                                if ($next -eq '---' -or $next -eq '') { $skipUntil++ } else { break }
                            }
                            break
                        }
                    }
                    continue
                }
                if ($i -le $skipUntil) { continue }
                $keep += $lines[$i]
            }
            if (-not $DryRun) {
                [System.IO.File]::WriteAllLines($t.Path, $keep, [System.Text.Encoding]::UTF8)
            }
            if ($Verbose) { Write-Host "[$($t.Name)] $count ocorrencias encontradas, duplicata removida" -ForegroundColor Yellow }
        } else {
            if ($Verbose) { Write-Host "[$($t.Name)] OK - secao ja presente" -ForegroundColor Green }
        }
    } else {
        $newContent = $content.TrimEnd() + "`n`n" + $authContent
        if (-not $DryRun) {
            [System.IO.File]::WriteAllText($t.Path, $newContent, [System.Text.Encoding]::UTF8)
        }
        $updated++
        if ($Verbose) { Write-Host "[$($t.Name)] Secao adicionada" -ForegroundColor Green }
    }
}

if ($DryRun) { Write-Host "`n[DRY RUN] Nenhum arquivo modificado." -ForegroundColor Cyan }
Write-Host "`nResumo: $updated agentes atualizados." -ForegroundColor White
if ($updated -gt 0) { Write-Host "Autorizacao black instalada com sucesso." -ForegroundColor Green }