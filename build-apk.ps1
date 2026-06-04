# Build APK release và copy ra thư mục gốc repo.
# Sửa $ApiUrl nếu cài trên điện thoại thật (IP PC cùng Wi-Fi).
param(
    [string]$ApiUrl = "",
    [string]$OutDir = (Join-Path $PSScriptRoot ""),
    [string]$OutName = "YumeGo-Ji-release.apk"
)

$ErrorActionPreference = "Stop"
$mobile = Join-Path $PSScriptRoot "mobile"

Push-Location $mobile
try {
    # Tranh loi Kotlin cache / Gradle daemon (dong Android Studio truoc khi build).
    Get-Process java -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -notlike "*cursor*" -and $_.Path -notlike "*redhat*" } |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Push-Location (Join-Path $mobile "android")
    .\gradlew.bat --stop 2>$null
    Pop-Location

    $args = @("build", "apk", "--release")
    if (-not [string]::IsNullOrWhiteSpace($ApiUrl)) {
        $args += "--dart-define=API_BASE_URL=$ApiUrl"
        Write-Host "API_BASE_URL=$ApiUrl"
    } else {
        Write-Host "Khong co API_BASE_URL — emulator mac dinh 10.0.2.2:5056; may that nen truyen -ApiUrl."
    }
    flutter @args
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    $src = Join-Path $mobile "build\app\outputs\flutter-apk\app-release.apk"
    if (-not (Test-Path $src)) {
        throw "Khong tim thay APK: $src"
    }
    $dest = Join-Path $OutDir $OutName
    Copy-Item $src $dest -Force
    Write-Host ""
    Write-Host "APK da luu tai:"
    Write-Host "  $dest"
}
finally {
    Pop-Location
}
