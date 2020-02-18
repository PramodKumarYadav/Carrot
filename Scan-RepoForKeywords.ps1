$excludeList = Get-Content "C:\Carrot\ignore\systemapps.json" | ConvertFrom-Json 

Write-Host "`ncheck app:"
foreach($word in $excludeList.applications){
    Write-Host "`t$word"
    Get-ChildItem -Path $PSScriptRoot -Recurse -Exclude 'systemapps.json' | Select-String -Pattern $word
}
