# Chay Flutter app (can backend dang chay :5056)
$flutterBat = "E:\FPT\PRM393\flutter_sdk\flutter\bin\flutter.bat"
if (-not (Test-Path $flutterBat)) {
  Write-Host "Chua co Flutter tai E:\FPT\PRM393\flutter_sdk\flutter"
  Write-Host "Chay: git clone https://github.com/flutter/flutter.git -b stable E:\FPT\PRM393\flutter_sdk\flutter"
  exit 1
}
$env:Path = "E:\FPT\PRM393\flutter_sdk\flutter\bin;" + $env:Path
Set-Location $PSScriptRoot\mobile
& $flutterBat pub get
& $flutterBat run
