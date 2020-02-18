$excludeList = Get-Content "C:\Carrot\ignore\tlmapps.json" | ConvertFrom-Json 

Write-Host "`ncheck app:"
foreach($word in $excludeList.applications){
    Write-Host "`t$word"
    Get-ChildItem -Path $PSScriptRoot -Recurse -Exclude 'tlmapps.json' | Select-String -Pattern $word
}
