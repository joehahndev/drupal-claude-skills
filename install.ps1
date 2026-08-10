# Installs/updates the Drupal skills + global CLAUDE.md section on Windows.
# Idempotent — safe to re-run after every git pull.
#
#   powershell -File install.ps1
#
# What it does:
#   1. Junctions skills/* into ~\.claude\skills\ (junctions need no admin).
#   2. Inserts or refreshes the "Drupal work" section in ~\.claude\CLAUDE.md,
#      between the claude-drupal-config markers, with this clone's path.

$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot
$ClaudeHome = Join-Path $env:USERPROFILE '.claude'
$SkillsDir = Join-Path $ClaudeHome 'skills'

# --- 1. Skill junctions -----------------------------------------------------
New-Item -ItemType Directory -Force $SkillsDir | Out-Null
Get-ChildItem (Join-Path $RepoRoot 'skills') -Directory | ForEach-Object {
  $link = Join-Path $SkillsDir $_.Name
  $item = Get-Item $link -ErrorAction SilentlyContinue
  if ($item -and $item.LinkType) {
    if ($item.Target -ne $_.FullName) {
      # Points somewhere else (old clone path) — repoint it.
      $item.Delete()
      cmd /c mklink /J "`"$link`"" "`"$($_.FullName)`"" | Out-Null
      Write-Output "repointed: $($_.Name)"
    } else {
      Write-Output "ok: $($_.Name)"
    }
  } elseif ($item) {
    Write-Warning "$link exists and is a real directory, not a link - resolve by hand."
  } else {
    cmd /c mklink /J "`"$link`"" "`"$($_.FullName)`"" | Out-Null
    Write-Output "linked: $($_.Name)"
  }
}

# --- 2. Global CLAUDE.md section --------------------------------------------
$claudeMd = Join-Path $ClaudeHome 'CLAUDE.md'
$section = (Get-Content (Join-Path $RepoRoot 'configs\global-claude-section.md') -Raw).Replace('{{REPO}}', $RepoRoot).TrimEnd()
$startMarker = '<!-- claude-drupal-config:start'
$endMarker = '<!-- claude-drupal-config:end -->'

if (Test-Path $claudeMd) {
  $content = Get-Content $claudeMd -Raw
  $start = $content.IndexOf($startMarker)
  if ($start -ge 0) {
    $end = $content.IndexOf($endMarker, $start)
    if ($end -lt 0) { throw "Found start marker but no end marker in $claudeMd - fix by hand." }
    $end += $endMarker.Length
    $content = $content.Substring(0, $start) + $section + $content.Substring($end)
    Write-Output 'CLAUDE.md: section refreshed'
  } else {
    $content = $content.TrimEnd() + "`n`n" + $section + "`n"
    Write-Output 'CLAUDE.md: section appended'
  }
  Set-Content -Path $claudeMd -Value $content -NoNewline
} else {
  Set-Content -Path $claudeMd -Value ("# Global rules`n`n" + $section + "`n") -NoNewline
  Write-Output 'CLAUDE.md: created'
}

Write-Output "Done. Repo: $RepoRoot"
