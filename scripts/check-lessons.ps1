$base = 'http://localhost:5056'
$items = (Invoke-RestMethod "$base/api/lessons?page=1&pageSize=200").items
foreach ($l in $items) {
  $slug = [uri]::EscapeDataString($l.slug)
  $d = Invoke-RestMethod "$base/api/lessons/slug/$slug"
  Write-Output ("{0} | cat={1} | type={2}" -f $l.title, $d.lesson.categoryName, $l.categoryType)
}
