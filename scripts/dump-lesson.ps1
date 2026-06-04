param([int]$Id = 20)
$base = 'http://localhost:5056'
$items = (Invoke-RestMethod "$base/api/lessons?page=1&pageSize=200").items
$l = $items | Where-Object { $_.id -eq $Id } | Select-Object -First 1
$slug = [uri]::EscapeDataString($l.slug)
$d = Invoke-RestMethod "$base/api/lessons/slug/$slug"
$out = Join-Path $PSScriptRoot "lesson-$Id.html"
[System.IO.File]::WriteAllText($out, $d.lesson.content, [System.Text.UTF8Encoding]::new($false))
Write-Output "Wrote $out ($($d.lesson.content.Length) chars)"
