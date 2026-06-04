# Chay API EXE201 (http://localhost:5056)
Set-Location $PSScriptRoot\backend
if (-not (Test-Path "appsettings.json")) {
  Copy-Item "appsettings.Example.json" "appsettings.json"
  Copy-Item "appsettings.Example.json" "appsettings.Development.json"
  Write-Host "Da tao appsettings.json - sua ConnectionStrings neu can."
}
dotnet run --launch-profile http
