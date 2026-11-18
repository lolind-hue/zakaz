# update.ps1 — пересобрать страницу из свежего inventory.txt и запушить (без токена в аргументах)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
Copy-Item '..\inventory.txt' 'inventory.txt' -Force
git add inventory.txt
$staged = git diff --cached --name-only
if (-not $staged) { Write-Host "inventory.txt не изменился — пушить нечего"; exit 0 }
git commit -q -m "inventory $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
git push -q origin main
Write-Host "Каталог обновлён на Pages."
