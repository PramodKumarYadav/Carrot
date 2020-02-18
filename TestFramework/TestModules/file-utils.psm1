# Function to create and clear directories 
function Initialize-Directory {
	param([String]$path)
    
	if (Test-Path $path){
        Write-Information "$path Exist. Deleting directory now!"
        $cmd = "rm -rf $path/*" 
        sh -c $cmd  
        # Since pwsh isnt too reliable doing this (Due to a known bug in remove-item cmd)
	}else {
		Write-Information "$path doesn't exist. Creating directory now!"
		New-Item -Path $path -ItemType "directory" -Force > $null # To get silent output.
	}
}

function Remove-Directory {
	param([String]$path)
    
	if (Test-Path $path){
        Remove-Item "$path" -Recurse -Force
	} 
}
# Based on the files chosen in inputDir & the chosen masterdata; build an expected file to compare with file named as jobs
function Merge-FilesToASingleFile {
    param(       
		[String] $referenceDir,
        [String] $lookUpDir,      
        [String] $outputDir,
        [String[]] $expectedMergedFileNames
    )

    # Get all folders in expected lookup directory
    $lookUpFolders = Get-ChildItem $lookUpDir 
    Foreach ($lookUpFolder in $lookUpFolders){
        
        # Define the name/path of final merged file
        $resultsDir = $lookUpFolder.Basename
        $mergedFilePath = "$outputDir/$resultsDir/Expected.txt"

        # Get all file names in Input directory for which you want to create a merge
        $inputFiles = Get-ChildItem $referenceDir -Recurse
        Foreach ($inputFile in $inputFiles){

            # Get all file names from here and start merging
            $lookUpFiles = Get-ChildItem $lookUpFolder 
            Foreach ($lookUpFile in $lookUpFiles){
                
                if($lookUpFile.BaseName -eq $inputFile.BaseName){           
                    Get-Content -Path "$lookUpFile" >> "$mergedFilePath"
                }                
            }
        }
    }
}

# To add result repositories based on exchanges tapped
function Add-ResultsRepositories {
    param(       
        [String] $PathDirectory ,  
        [String[]] $directoryNames
    )

    Foreach ($directoryName in $directoryNames){
        
        # Create a sub repository to save results
        $results = "$PathDirectory/$directoryName"
        Initialize-Directory -path $results 

        Write-Host "Created results repository: $results"
    }
}

# Create a merged input file 
function New-MergedInputFileFromDirFiles{
    param(       
        [Parameter(Mandatory=$True,HelpMessage="Path of Input Directory")]	    
        [String] $InputDir,

        [Parameter(Mandatory=$True,HelpMessage="Path of Merged Input File to be created")]	    
        [String] $MergedInputFile
    )

    # Get all files recursively and create a merged input file
    $inputFiles = Get-ChildItem $InputDir -File -Recurse
    Foreach ($inputFile in $inputFiles){
        Write-Host "Merged input file added with file: $inputFile"             
        Get-Content -Path $inputFile >> $MergedInputFile 
    }
}

function Merge-ActualFilesToASingleFile{
    param(
       [Parameter(Mandatory=$True, HelpMessage="Directory containing raw and header msgs (.dat and .json files)")]
       [String] $InputDir,

       [Parameter(Mandatory=$True, HelpMessage="Directory to contain all exchange directories")]
       [String] $OutputDir,

       [Parameter(Mandatory=$True, HelpMessage="All exchange directories for which we want to create merged output files")]
       [String[]] $ExchangeDirs

       
   )
    # 
    Foreach ($ExchangeDir in $ExchangeDirs){
        $mergedOutput = Get-AllRawMsgsAsStringFromDirectory -InputDir "$InputDir/$ExchangeDir"
        $mergedOutput > "$OutputDir/$ExchangeDir/Actual.txt"
    }
    return $RawJSONmsgs
}
function Get-AllRawMsgsAsStringFromDirectory{
    param(
       [Parameter(Mandatory=$True, HelpMessage="Directory containing raw and header msgs (.dat and .json files)")]
       [String] $InputDir
   )
    # Get all the raw message files in this directory (.dat files) and exclude all header files (.json files)
    $inputFiles = Get-ChildItem $InputDir -File -Recurse -Exclude *.json
    Foreach ($inputFile in $inputFiles){
        $RawJSONmsgs += Get-Content $inputFile -Raw
    }
    return $RawJSONmsgs
}
function Merge-ExpectedFilesToASingleFile{
    param(       
		[String] $LookUpInputDir,
        [String] $ExpectedResultsDir,      
        [String] $OutputDir,
        [String[]] $ExchangeDirs
    )

    # For each file in Input Dir
    $InputDirs = Get-ChildItem $LookUpInputDir 
    Foreach ($InputDir in $InputDirs){
        # Pick the expected directory 
        $InputDirName = $InputDir.BaseName
        $ExpectedDir = "$ExpectedResultsDir/$InputDirName"
        
        # Add content from each subdirectory (named as per exchange dirs) to its respective Expected.txt
        foreach($ExchangeDir in $ExchangeDirs){
            $mergedOutput = Get-AllRawMsgsAsStringFromDirectory -InputDir "$ExpectedDir/$ExchangeDir"
            $mergedOutput >> "$OutputDir/$ExchangeDir/Expected.txt" # Append for all sceanrios.
        }
    }
}
function Set-ScenariosKeyMapJson {  
    # Reads all jsons from $sourceDir, extract the $keyField field from all of them, creates a single json array with the extracted data as [{ "name": "scenario1", "conversationId": [ "guid1", "guid2" ]}
    param(
        [Parameter(Mandatory=$true)]
        [String] $ScenarioName,

        [Parameter(Mandatory=$true)]
        [String] $ExchangeDir,

        [Parameter(Mandatory=$true)]
        [String] $target,
        
        [Parameter(Mandatory=$true)]
        [String] $keyField
    )
    
    # For each of the messages in expected directory get all the keys as array
    $Keys = @()
    $ExchangeFiles = Get-ChildItem $ExchangeDir -File -Recurse -Exclude *.json
    Foreach ($ExchangeFile in $ExchangeFiles){
        # Get all keys for this scenario
        $jsonObjs = Get-Content $ExchangeFile -Raw | ConvertFrom-Json 
        foreach($jsonObj in $jsonObjs){
            $Keys += $jsonObj.$keyField
        }
    }

    # Now with all the collected keys (say conversation Ids) for this scenario, we can make our TS-Keys map
    # Make a hashtable for Scenarion name and KeyField values.
    $mapObj = [psobject]@{
                    'name' = $ScenarioName
                    "$keyField" = $Keys
                    }

    # Convert this map object to jsonobject
    $mapObj | ConvertTo-Json | Add-Content $target -NoNewline

    # This will make one scenario. Now we need to iterate over all scenarios to get this Scenario-Keys map
}
#  Create map scenario <-> [conversationId] in the results folder
function Add-ScenarioConversationIdMapInResultsFolder {
    param( 
        [String] $InputDir,
        [String] $DuplicatesDir,
        [String] $ExpectedDir,
        [String] $ExchangesDir,
        [String[]] $Jobs,

        [Parameter(Mandatory=$false)]
        [String[]] $excludeSubDir,

        [Parameter(Mandatory=$true)]
        [String] $keyField
    )

    # Initialise scenario files for each exchange
    foreach($Job in $Jobs){
        New-item  "$ExchangesDir/$Job/scenarios.json" -Value "[" -Force > $null
    }

    # For each sub directory in Input Dir 
    $InputSubDirs = Get-ChildItem $InputDir -Exclude $excludeSubDir
    Foreach ($inputSubDir in $InputSubDirs){
        # Pick the expected directory 
        $inputSubDirName = $inputSubDir.BaseName
        $expectedSubDir = "$ExpectedDir/$inputSubDirName"
        
        # Add content from each subdirectory (named as per exchange dirs) to its respective Expected.txt
        foreach($Job in $Jobs){
            $target = "$ExchangesDir/$Job/scenarios.json"
            Set-ScenariosKeyMapJson -ScenarioName $inputSubDirName -ExchangeDir "$expectedSubDir/$Job" -target "$target" -keyField $keyField  
            # Add a comma after each scenario
            "," | Add-Content "$target" -NoNewline
        }
    }

    # For each sub directory in duplicates Dir 
    $DuplicatesSubDirs = Get-ChildItem $DuplicatesDir -Exclude $excludeSubDir
    Foreach ($duplicatesSubDir in $DuplicatesSubDirs){
        # Pick the expected directory 
        $duplicatesSubDirName = $duplicatesSubDir.BaseName
        $expectedSubDir = "$ExpectedDir/$duplicatesSubDirName"
        
        # Add content from each subdirectory (named as per exchange dirs) to its respective Expected.txt
        foreach($Job in $Jobs){
            $target = "$ExchangesDir/$Job/scenarios.json"
            Set-ScenariosKeyMapJson -ScenarioName $duplicatesSubDirName -ExchangeDir "$expectedSubDir/$Job" -target "$target" -keyField $keyField  
            # Add a comma after each scenario
            "," | Add-Content "$target" -NoNewline
        }
    }

    # Make the scenarios.json proper by adding ending bracket and removing extra , from previous step
    foreach($Job in $Jobs){
        # In the end add a bracket to each of scenarios file
        $target = "$ExchangesDir/$Job/scenarios.json"
        "]" >> "$target"

        # Replace extra comma from the last message
        $tmp = (Get-Content "$target").Replace(",]","]")
        $tmp > "$target"
    }

    # Format output properly as json array
    foreach($Job in $Jobs){
        $target = "$ExchangesDir/$Job/scenarios.json"
        (Get-Content "$target") `
                    | Convertfrom-Json `
                    | ConvertTo-Json -depth 100 `
                    > "$target"
    }
    
    Write-Host "Scenario.json created for all exchanges!"
}