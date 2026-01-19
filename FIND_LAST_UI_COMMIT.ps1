# PowerShell script to find last UI-related commit

Write-Host "=== Recent Commits ===" -ForegroundColor Yellow
git log --oneline -30

Write-Host "`n=== Commits with UI/Design keywords ===" -ForegroundColor Yellow
git log --all --grep="ui\|UI\|design\|Design\|theme\|Theme\|screen\|Screen\|layout\|Layout" --oneline -20

Write-Host "`n=== Commits from last week ===" -ForegroundColor Yellow
git log --since="1 week ago" --oneline

Write-Host "`n=== Recent commits with dates ===" -ForegroundColor Yellow
git log --format="%h %ad %s" --date=short -20

Write-Host "`n=== To revert to a specific commit, run: ===" -ForegroundColor Green
Write-Host "git reset --hard COMMIT_HASH" -ForegroundColor Cyan
Write-Host "`n(Replace COMMIT_HASH with the hash from above)" -ForegroundColor Gray

