Write-Host "root dir: $PSScriptRoot"
$excludeList = Get-Content "$PSScriptRoot\Ignore\system-apps.json" | ConvertFrom-Json 

Write-Host "`ncheck app:"
foreach($word in $excludeList.applications){
    Write-Host "`t$word"
    Get-ChildItem -Path $PSScriptRoot -Recurse -Exclude 'system-apps.json' | Select-String -Pattern $word
}

foreach($word in $excludeList.others){
    Write-Host "`t$word"
    Get-ChildItem -Path $PSScriptRoot -Recurse -Exclude 'system-apps.json' | Select-String -Pattern $word
}
