# Sync lesson tables to Supabase from backend/doc/sql/sync_lessons_only_supabase.sql
param(
    [string]$SecretsFile = (Join-Path $PSScriptRoot "..\backend\appsettings.Secrets.json"),
    [string]$SqlFile = (Join-Path $PSScriptRoot "..\backend\doc\sql\sync_lessons_only_supabase.sql"),
    [string]$PatchFile = (Join-Path $PSScriptRoot "..\backend\doc\sql\patch_lesson_content_rich.sql"),
    [string]$ConnectionString = "",
    [switch]$SkipRichPatch
)

$ErrorActionPreference = "Stop"

function Get-ConnectionStringFromSecrets {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        throw "Secrets file not found: $Path"
    }
    $json = Get-Content $Path -Raw | ConvertFrom-Json
    $cs = $json.ConnectionStrings.DefaultConnection
    if ([string]::IsNullOrWhiteSpace($cs) -or $cs -match "YOUR_SUPABASE") {
        throw "DefaultConnection is not configured in Secrets."
    }
    return $cs
}

if ([string]::IsNullOrWhiteSpace($ConnectionString)) {
    $ConnectionString = Get-ConnectionStringFromSecrets -Path $SecretsFile
}

if (-not (Test-Path $SqlFile)) {
    throw "SQL file not found: $SqlFile"
}

$toolDir = Join-Path $PSScriptRoot "..\backend\tools\SyncLessonsToDb"
Write-Host "Syncing lessons to Supabase..."
Write-Host "SQL: $SqlFile"

Push-Location $toolDir
try {
    dotnet restore --verbosity quiet | Out-Null
    dotnet run -- "$ConnectionString" $SqlFile
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    if (-not $SkipRichPatch -and (Test-Path $PatchFile)) {
        Write-Host "Applying rich lesson content patch..."
        dotnet run -- "$ConnectionString" $PatchFile
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
}
finally {
    Pop-Location
}
