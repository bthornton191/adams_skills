<#
.SYNOPSIS
    Install all Adams skills into the current project.

.DESCRIPTION
    Downloads every .zip asset from the latest GitHub release and extracts
    them into a skills directory.

    If -Destination is given, skills are installed there.

    Otherwise the script looks for existing .*\skills folders in the current
    directory (e.g. .agents\skills, .github\skills, .claude\skills).
      - One match  → uses it automatically
      - No match   → creates .agents\skills
      - Multiple   → prompts you to choose

.PARAMETER Destination
    Optional. Explicit path to install skills into.

.EXAMPLE
    .\install.ps1

.EXAMPLE
    .\install.ps1 -Destination ~\.agents\skills
#>
param(
    [Parameter(Position = 0)]
    [string]$Destination
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repo = 'bthornton191/adams_skills'

# --- Resolve destination ---
if ($Destination) {
    $dest = (Resolve-Path -Path $Destination -ErrorAction SilentlyContinue)?.Path
    if (-not $dest) {
        $dest = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)
    }
}
else {
    # Scan for existing .*\skills folders in the current directory
    $candidates = @(Get-ChildItem -Directory -Force -Path $PWD |
        Where-Object { $_.Name -match '^\.' -and (Test-Path (Join-Path $_.FullName 'skills')) } |
        ForEach-Object { Join-Path $_.FullName 'skills' })

    if ($candidates.Count -eq 1) {
        $dest = $candidates[0]
        Write-Host "Found existing skills folder: $dest" -ForegroundColor DarkGray
    }
    elseif ($candidates.Count -gt 1) {
        Write-Host 'Multiple skills folders found:' -ForegroundColor Yellow
        for ($i = 0; $i -lt $candidates.Count; $i++) {
            $rel = [IO.Path]::GetRelativePath($PWD, $candidates[$i])
            Write-Host "  [$($i + 1)] $rel"
        }
        $choice = Read-Host "Choose a folder (1-$($candidates.Count))"
        $idx = [int]$choice - 1
        if ($idx -lt 0 -or $idx -ge $candidates.Count) {
            Write-Host 'Invalid selection.' -ForegroundColor Red
            exit 1
        }
        $dest = $candidates[$idx]
    }
    else {
        $dest = Join-Path $PWD '.agents\skills'
    }
}

if (-not (Test-Path $dest)) {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
}

# --- Download and install ---
$release = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest"
$zips    = $release.assets | Where-Object { $_.name -like '*.zip' }

if (-not $zips) {
    Write-Host 'No .zip assets found in the latest release.' -ForegroundColor Red
    exit 1
}

foreach ($asset in $zips) {
    $tmp = Join-Path $env:TEMP $asset.name
    Write-Host "Installing $($asset.name -replace '\.zip$') ..." -ForegroundColor Cyan
    Invoke-WebRequest $asset.browser_download_url -OutFile $tmp -UseBasicParsing
    Expand-Archive $tmp -DestinationPath $dest -Force
    Remove-Item $tmp -Force
}

Write-Host "`nDone. Skills installed to $dest" -ForegroundColor Green
