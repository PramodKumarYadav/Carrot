# it also sorts by a key that you must provide
function Remove-Keys {
    param(
    [Parameter(Mandatory = $true)]    
    [String] $jsonFilePath,   
    
    [Parameter(Mandatory = $true)]    
    [String] $keyForSorting,   

    [Parameter(Mandatory = $true)]    
    [String[]] $keysToRemove)

    $delkey = "";

    foreach($key in $keysToRemove){
        $delkey = $delkey + ".$key" + ','
    }

    if ($delkey.Length -gt 0){
        # remove the last comma
        $delkey = $delkey.TrimEnd(',')

        $jqDelCmd = "'del($delKey)'"
        $jqSortCmd = "'sort_by(.$keyForSorting)'"

        # Write-Host "delcmd: $jqDelCmd"
        # Write-Host "jqSortCmd: $jqSortCmd"

        $cmd = "Get-Content $jsonFilePath -Raw | jq .[] | jq $jqDelCmd | jq -s $jqSortCmd | Set-Content -Path $jsonFilePath"
        Invoke-Expression $cmd

        Write-Host "json keys removed from file: $jsonFilePath "
    } else {
        Write-Host 'no key to remove :(('
    }
}

# This function is when you need to sort all files in a folder on a single key 
function Get-SortAllFilesInAFolderOnAKey{
    param(       
        [String] $PathDirectory,
        [String] $SortOnKey,
        [String] $excludeFile
    )

    # Get all files from root directory
    $files = Get-ChildItem $PathDirectory  -File -Recurse -Exclude $excludeFile
    Foreach ($file in $files){
        Set-SortJsonOnAKey -jsonFilePath  "$file" -keyForSorting $SortOnKey
    }
}
# This function is when you need to sort each file differently on a key  
function Set-SortJsonOnAKey {
    param(
    [Parameter(Mandatory=$True,HelpMessage="Full path of JSON file to be sorted. Ex: /test/out/myApp/RawOutput/RawExpected.txt")]	  
    [String] $jsonFilePath,   
    
    [Parameter(Mandatory=$True,HelpMessage="Key used to sort the JSON file")]	   
    [String] $keyForSorting)
    
    # Write-Host "`nFile path: $jsonFilePath"
    # Write-Host "`nKey for sorting: $keyForSorting"

    # Get content of the file and see if it starts with '{'   
    $content = Get-Content -Path $jsonFilePath -Raw

    # Trim leading and trailing spaces if content is not null
    if ($content){
        $content = $content.trim()
    }
         
    # If file starts with a '{', we assume it's a collection of json objects not wrapped in a json array []
    if ($content -match '^{'){
        # Ex: Get-Content $jsonFilePath -Raw | jq -s 'sort_by(.MessageID) ' | Set-Content -Path $jsonFilePath   
        $jqSortCmd = "'sort_by(.$keyForSorting)'"
        $cmd = "Get-Content '$jsonFilePath' -Raw | jq -s $jqSortCmd | Set-Content -Path '$jsonFilePath'"
        Invoke-Expression $cmd

        Write-Host "`njson File: $jsonFilePath sorted and set on key $keyForSorting"     
    } else {
        # we don't support already well-foormed arrays [yet]
        Write-Host "`nFile: $jsonFilePath is not supported. Must be a colection of json objects (not an array!). eg '{},{}'" 
    }
}

function Publish-KeysFromDir {  
    # Reads all jsons from $sourceDir, extract the $keyField field from all of them, creates a single json array with the extracted data as [{ "name": "scenario1", "conversationId": [ "guid1", "guid2" ]}
    # feel free to change name, did not come up with better one.
    param(
    [Parameter(Mandatory=$true)]
    [String] $sourceDir,

    [Parameter(Mandatory=$true)]
    [String] $target,
    
    [Parameter(Mandatory=$true)]
    [String] $keyField)

    # In some cases, when source and target directory are same (like while validating tables, we need to first get all source childs)
    # Before we create the new target file as shown below.
    $inputFiles = Get-ChildItem $sourceDir
    "[" >> $target 
    Foreach ($inputFile in $inputFiles){
        $scenarioName = $inputFile.BaseName
        # We need to escape the double quotes using both the backslash(\) and grave accent (`)
        Invoke-Expression "Get-Content '$($inputFile.FullName)' -Raw| jq '{\`"name\`": \`"$($scenarioName)\`",\`"$keyField\`":[.[].\`"$keyField\`"]}' --slurp | Add-Content $target -NoNewline"
        "," | Add-Content $target -NoNewline
    }

    "]" >> $target
    $tmp = (Get-Content $target).Replace(",]","]")
    $tmp > $target

    (Get-Content $target) `
                | Convertfrom-Json `
                | ConvertTo-Json -depth 100 `
                > $target
}

# To remove the common keys from Actual.txt and Expected.txt from results folder
function Remove-UnwantedKeysFromJson{
    [CmdletBinding()]
    param(		
        [parameter(Mandatory = $true)]
        [string] $resultsDir,

        [parameter(Mandatory = $true)]
        [string[]] $jobs,

        [parameter(Mandatory = $true)]
        [string] $sortKey,

        [parameter(Mandatory = $true)]
        [string[]] $removeKeys
    )  

    # Remove unwanted keys from jsons (Each file has a few common keys, that we can remove generically.)
    foreach ($job in $jobs){ 
        Remove-KeysFromSimilarFiles -pathDirectory "$resultsDir/$job" -excludeFile '' -keyForSorting "$sortKey" -keysToRemove $removeKeys
    }

    Write-Host "`nAll keys that change in actual and expected (and are not important for compare) are removed!"
    Write-Host "===============================================================`n"
}
function Remove-KeysFromSimilarFiles {
    param(
    [Parameter(Mandatory = $true)]    
        [String] $pathDirectory,

        [String] $excludeFile,

        [String] $keyForSorting,

        [String[]] $keysToRemove
    )

    # Get all files except the MergedInput.txt file from root directory
    $files = Get-ChildItem $pathDirectory -File -Recurse -Exclude $excludeFile
    Foreach ($file in $files){

        Remove-Keys -jsonFilePath $file -keyForSorting $keyForSorting -keysToRemove $keysToRemove
    }
}

# Get base64 decoded Expected 
function Get-Base64DecodedExpected {
    param(       
        [String] $inputPathDirectory,
        [String] $outputPathDirectory,
        [String] $SortKey = "conversationId" # Default if not passed any
    )

    # Get all files from root directory
    $files = Get-ChildItem $inputPathDirectory -File -Recurse 
    Foreach ($file in $files){

        $outFileName = $file.Name
        $base64DecodedFile = "$outputPathDirectory/$outFileName"
        Write-Host "Writing base64 decode output to $base64DecodedFile"

        # Note: We need a jsonObject output (not array since we will merge this later). Thus piped to convert to object.
        # 'sort_by(.conversationId) | .[]'
        $sortCmd = 'sort_by(.' + $SortKey + ") | .[]"
        Get-Content $file -Raw `
                    | jq '[.[] | .Body | @base64d ]' `
                    | ConvertFrom-Json `
                    | jq -s $sortCmd `
                    > $base64DecodedFile
    }
}

# Get base64 decoded output 
function Get-Base64DecodedActual {
    param(       
        [String] $inputPathDirectory,
        [String] $outputPathDirectory,
        [String] $SortKey = "conversationId", # Default if not passed any
        [String] $outFileName = "Actual.txt" # Default if not passed any
    )

    # Get all files from root directory
    $files = Get-ChildItem $inputPathDirectory -File -Recurse

    Foreach ($file in $files){
  
        $base64DecodedFile = "$outputPathDirectory/$outFileName"
        Write-Host "Writing base64 decode output to $base64DecodedFile"

        $sortCmd = 'sort_by(.' + $SortKey + ')'
        Get-Content $file -Raw `
                    | jq '[.[] | .Body | @base64d ]' `
                    | ConvertFrom-Json `
                    | jq -s $sortCmd `
                    > $base64DecodedFile
    }
}

# create json diff of exp/actual compare
function Add-JsonDiffOfExpectedVsActualCompare {
    param( 
        [Parameter(Mandatory=$true)]
        [String] $resultsDir,

        [Parameter(Mandatory=$false)]
        [String[]] $excludeSubDir,

        [Parameter(Mandatory=$true)]
        [String] $keyField
    )

    # Get all folders except the directory that doesnt share the common key (and thus we want to exclude)
    $subFolders = Get-ChildItem $resultsDir -Directory -Recurse -Exclude $excludeSubDir
    Foreach ($subFolder in $subFolders){

        # create json diff of exp/actual
        node "/test/TestModules/nodejs/jsondiff.js" "$subFolder/Expected.txt" "$subFolder/Actual.txt" "$keyField"  > "$subFolder/Expected.txt.diff"
    }
}

# create json diff of exp/actual compare
function Add-ScenarioResultsFile {
    param( 
        [Parameter(Mandatory=$true)]
        [String] $resultsDir,

        [Parameter(Mandatory=$false)]
        [String[]] $excludeSubDir,

        [Parameter(Mandatory=$true)]
        [String] $keyField
    )

    # Get all folders except the directory that doesnt share the common key (and thus we want to exclude)
    $subFolders = Get-ChildItem $resultsDir -Directory -Recurse -Exclude $excludeSubDir
    Foreach ($subFolder in $subFolders){

        # create 'scenario results' file
        node "/test/TestModules/nodejs/create-scenario-results.js" "$subFolder/scenarios.json" "$subFolder/Expected.txt.diff" "$keyField" > "$subFolder/scenario-results.json"
    }
}
function Get-CountOfJsonMsgsInADirectory {
    
    param(
        [Parameter(Mandatory=$True,HelpMessage="Path of Input directory")]		
        [String]$Path,

        [String]$keyForSorting = 'conversationId'
	)

    # Iterate through all files in the directory (excluding the header files)
    $totalJsonMsgs = 0;
    $files = Get-ChildItem "$Path" -File -Recurse -Exclude '*.json'
    foreach ($file in $files){
        
        Write-Host "Processing file: $file"

        # Get Content and convert to jsonArray 
        $jqSortCmd = "'sort_by(.$keyForSorting)'"
        $script = "Get-Content '$file' -Encoding UTF8 -Raw | jq -s $jqSortCmd"
        $rawContent = Invoke-Expression $script

        # Get the jsonObjects from this file in an array
        $inputJsonObjs = $rawContent | ConvertFrom-Json

        $jsonItems = $inputJsonObjs.Length
        Write-Host "Total JSON items in this file: $jsonItems"

        $totalJsonMsgs = $totalJsonMsgs + $jsonItems;
        
    } 
    
    Write-Host "Total JSON items in this directory: $totalJsonMsgs"
    Return $totalJsonMsgs 
}