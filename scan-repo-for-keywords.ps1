$excludeList = Get-Content "C:\Carrot\Ignore\system-apps.json" | ConvertFrom-Json 

Write-Host "`ncheck app:"
foreach($word in $excludeList.applications){
    Write-Host "`t$word"
    Get-ChildItem -Path $PSScriptRoot -Recurse -Exclude 'system-apps.json' | Select-String -Pattern $word
}
