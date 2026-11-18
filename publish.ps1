# publish.ps1 — выложить каталог в GitHub Pages (нужен ТОЛЬКО токен один раз, через prompt)
# Использование:  cd "C:\090\zakaz sig\site"  →  powershell -File .\publish.ps1 -GithubUser "login"
param(
    [Parameter(Mandatory=$true)][string]$GithubUser,
    [string]$Repo = "zakaz"
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

# токен берём безопасно: не из history, а скрытым вводом
Write-Host "Нужен GitHub Personal Access Token (scope: repo, workflow)."
Write-Host "Создать: https://github.com/settings/tokens -> Generate new token (classic) -> галочка repo."
$secure = Read-Host -AsSecureString "Вставь токен и Enter"
$token  = [Runtime.InteropServices.Marshal]::PtrToStringUni([Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($secure))
$auth   = @{ Authorization = "Bearer $token" }

# 1) создать репозиторий (если нет)
try {
  Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Method Post -Headers $auth -ContentType 'application/json' `
    -Body (@{ name = $Repo; private = $false; has_pages = $true } | ConvertTo-Json) | Out-Null
  Write-Host "репозиторий $Repo/$Repo создан"
} catch {
  if ($_.Exception.Message -match 'already exists|422') { Write-Host "репозиторий уже существует — продолжаем" } else { throw }
}

# 2) git push
if (-not (Test-Path '.git')) {
  git init -q -b main
}
# подставляем логин бота, если ещё не вписан
$html = Get-Content 'index.html' -Raw
if ($html -match 'const BOT_USERNAME = "zakazbot"') {
  $bn = Read-Host "Username твоего бота из @BotFather (без @)"
  if ($bn) { ($html -replace 'const BOT_USERNAME = "zakazbot"', "const BOT_USERNAME = `"$bn`"") | Set-Content 'index.html' -Encoding UTF8 }
}
git add .
git commit -m "catalog $(Get-Date -Format 'yyyy-MM-dd HH:mm')" | Out-Null
git remote remove origin 2>$null
git remote add origin "https://x-access-token:$token@github.com/$GithubUser/$Repo.git"
git push -f -q origin main

# 3) включить Pages (ветка main, корень)
try {
  Invoke-RestMethod -Uri "https://api.github.com/repos/$GithubUser/$Repo/pages" -Method Post -Headers $auth -ContentType 'application/json' `
    -Body (@{ source = @{ branch = 'main'; path = '/' } } | ConvertTo-Json) | Out-Null
} catch {
  Invoke-RestMethod -Uri "https://api.github.com/repos/$GithubUser/$Repo/pages" -Method Put -Headers $auth -ContentType 'application/json' `
    -Body (@{ source = @{ branch = 'main'; path = '/' } } | ConvertTo-Json) | Out-Null
}
Remove-Item Variable:\token
Write-Host ""
Write-Host "ГОТОВО через 1-2 минуты:  https://$GithubUser.github.io/$Repo/"
Write-Host "Этот URL -> в @BotFather: /mybots -> Bot Settings -> Menu Button -> turn on -> вставь URL,"
Write-Host "или /newapp -> Connect existing Web App (получишь ссылку вида t.me/botname/appname — её кидай тестерам)."
Write-Host "Обновление каталога после новых фото: powershell -File .\update.ps1"
