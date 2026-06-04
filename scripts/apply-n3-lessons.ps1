# Apply N3 lesson seed to Supabase
param(
    [string]$SecretsFile = (Join-Path $PSScriptRoot "..\backend\appsettings.Secrets.json"),
    [string]$SqlFile = (Join-Path $PSScriptRoot "..\backend\doc\sql\patch_n3_lessons.sql")
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path $SecretsFile)) { throw "Secrets not found: $SecretsFile" }
$json = Get-Content $SecretsFile -Raw | ConvertFrom-Json
$cs = $json.ConnectionStrings.DefaultConnection
if ([string]::IsNullOrWhiteSpace($cs)) { throw "DefaultConnection missing in Secrets." }

$toolDir = Join-Path $PSScriptRoot "..\backend\tools\SyncLessonsToDb"
Push-Location $toolDir
try {
    dotnet run -- "$cs" $SqlFile
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
