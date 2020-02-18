$excludeList = Get-Content "C:\Carrot\ignore\tlmapps.json" | ConvertFrom-Json 

foreach($word in $excludeList.applications){
    Write-Host "`ncheck application: $word"
    Get-ChildItem -Path $PSScriptRoot  -Recurse | Select-String -Pattern $word
}
