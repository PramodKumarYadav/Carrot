function Test-EvenOdd {
    [CmdletBinding()]
    param(		
        [parameter(Mandatory = $true)] [string] $Application,

        [parameter(Mandatory = $true)] [string] $TestScenario,

        [parameter(Mandatory = $true)] [string[]] $TappedExchanges,

        [parameter(Mandatory = $false)] [string[]] $CheckedExchanges,

        [parameter(Mandatory = $true)] [string] $InputExchange,

        [parameter(Mandatory = $true)] [string[]] $Queues,

        [parameter(Mandatory = $true)] [string[]] $Jobs,

        [parameter(Mandatory = $true)] [string] $CleanDb
    ) 

    $fn = $MyInvocation.MyCommand.Name
    Write-Host ("`nExecuting script: $fn")

    # Set root location
    Set-Location '/test'
    Write-Host "root directory: /test"

# Step01: Check if system is ready to test
    # 01. Wait for exchanges and queues to be available before pushing messages on them.
    Wait-ForExchangeToBeCreated($CheckedExchanges + $TappedExchanges)
    Wait-ForQueueToBeCreated($Queues)

    # 02. Clear all tables (useful when running in debug mode, when running multiple times). 
    Write-Host "Value of `$CleanDb: $CleanDb "
    if( $CleanDb -eq $true){
        Invoke-TruncateTablesWhenNeeded -PathSQLFile "/test/TestApplications/$Application/truncate-tables.sql"
    }

# Step02: Set the Taps on output exchanges that we want to validate
    # Remove existing taps if any (needed when running in debug mode)
    Remove-TapOnExchange -jobNames $Jobs

    # Common variables for next steps
    $outDir = "/test/out/$Application/$TestScenario"

    # Initialize tapped msgs directory
    $tappedMsgsDir = "$outDir/TappedMsgs"
    Initialize-Directory -path $tappedMsgsDir

    # Set tap on exchange
    Set-TapOnExchange -exchanges $TappedExchanges -jobs $Jobs -PathTappedMsgs $tappedMsgsDir

# Step03: Publish and Wait for Input messages to be published

    # Initialize exchanges directory
    $exchangesDir = "$outDir/Exchanges"
    Initialize-Directory -path $exchangesDir

    # Store Path of test data directory in a variable
    $testdataDir = "/test/TestData/$Application"

    # 01: Publish all the messages from input directory
    $inputDir = "$testdataDir/Input"
    Publish-AndWaitForMsgsToBePublished -InputDir "$inputDir" -InputExchange $InputExchange -Queues $Queues[0]

    # 02: Publish all the messages from duplicates directory
    $duplicatesDir = "$testdataDir/Duplicates"
    Publish-AndWaitForMsgsToBePublished -InputDir "$duplicatesDir" -InputExchange $InputExchange -Queues $Queues[0]

# Step04: Create results repositories for each tapped exchange
    Add-ResultsRepositories -PathDirectory $exchangesDir -directoryNames $Jobs

# Step05: Prepare actual Output for Compare 
    # 01. Merge output for each exchange in one file
    Merge-ActualFilesToASingleFile -InputDir $tappedMsgsDir -OutputDir $exchangesDir -ExchangeDirs $Jobs 

    # 02: Sort all actual files before compare
    $sortKey = 'conversationId'
    Get-SortAllFilesInAFolderOnAKey -PathDirectory $exchangesDir  -SortOnKey "$sortKey"

# Step06: Prepare expected for Compare 
    # 01: Based on the files chosen in input and duplicates, build a merged expected file for each exchange.
    $expectedDir = "$testdataDir/Expected"
    Merge-ExpectedFilesToASingleFile -LookUpInputDir $inputDir -ExpectedResultsDir $expectedDir -OutputDir $exchangesDir -ExchangeDirs $Jobs
    Merge-ExpectedFilesToASingleFile -LookUpInputDir $duplicatesDir -ExpectedResultsDir $expectedDir -OutputDir $exchangesDir -ExchangeDirs $Jobs

    # 02: Sort all build expected files before compare
    Get-SortAllFilesInAFolderOnAKey -PathDirectory $exchangesDir -excludeFile "Actual.txt" -SortOnKey "$sortKey"

# Step07: Remove unwanted keys from json (For both Actual and Expected files for each exchange.)
    $commonKeys = @('sendTimestamp','host.machineName')
    Remove-UnwantedKeysFromJson -resultsDir "$exchangesDir" -jobs $Jobs -sortKey "$sortKey" -removeKeys ($commonKeys)
    
# Step08: create map scenario <-> [$sortKey] in the results folder for all tapped exchanges
    $excludeSubDirectories =  @() # In case if there are files that dont share the same sorting keyField and thus you want to exclude
    Add-ScenarioConversationIdMapInResultsFolder -InputDir $inputDir -DuplicatesDir $duplicatesDir -ExpectedDir $expectedDir `
                                                   -ExchangesDir $exchangesDir -Jobs $Jobs `
                                                   -excludeSubDir $excludeSubDirectories -keyField "$sortKey"

    Write-Host "`nAdded scenarios.json file in each results folder. This file contains map of scenario <-> [$sortKey] "
    Write-Host "===============================================================`n"

# Step09: Compare and store results in a diff file
    # create json diff of base64 exp/actual
    Add-JsonDiffOfExpectedVsActualCompare -resultsDir "$exchangesDir" -excludeSubDir $excludeSubDirectories -keyField "$sortKey"

    # create 'scenario results' file
    Add-ScenarioResultsFile -resultsDir "$exchangesDir" -excludeSubDir $excludeSubDirectories -keyField "$sortKey"

# Step10: Remove the taps    
    Remove-TapOnExchange -jobNames $Jobs

    Write-Host ("Finished script: $fn")
    Write-Host "===============================================================`n"
}