# Steps to run this function are at the end of this file. Have a look and do F5.
function Set-ExpectedResultsEvenOdd {
    [CmdletBinding()]
    param(		
        [parameter(Mandatory = $true)]
        [string] $TestDataDir,

        [parameter(Mandatory = $true)]
        [string] $InputExchange
    ) 

    $fn = $MyInvocation.MyCommand.Name
    Write-Host ("`nExecuting script: $fn")

    # Set root location
    Set-Location '/TestFramework'
    Write-Host "root directory: /TestFramework"

# Step01: Check if system is ready to test
    # 01. Define all exchanges and queues that you want to check or tap. Give job names as per the exchange names. 
    $checkedExchanges = @("$InputExchange",
        "other-exchange"
        );
        
    $tappedExchanges = @('first-exchange', 
                        'second-exchange'
                        );
    
    # 02. Job names for tapped exchanges
    $jobs = @('firstExchange', 'secondExchange');

    # Should check queues for both checked/tapped exchanges
    $queues = @("first-queue", 
                'second-queue'
                );

    # 03. Wait for exchanges and queues to be available before pushing messages on them.
    Wait-ForExchangeToBeCreated($checkedExchanges + $tappedExchanges)
    Wait-ForQueueToBeCreated($queues)

    # 04: Clear all tlm tables (useful when running in debug mode, when running multiple times). 
    Invoke-TruncateTablesSQLWhenNeeded -PathSQLFile '/test/TestApplications/EvenOdd/truncate-tables.sql' 

# Step02: Set the Taps on tapped exchanges
    # Remove existing taps if any (needed when running in debug mode)
    Remove-TapOnExchange -jobNames $jobs

    # Initialize tapped msgs directory
    $tappedMsgsDir = "/test/out/EvenOdd/TappedMsgs"
    Initialize-Directory -path $tappedMsgsDir

    # Set tap on exchange
    Set-TapOnExchange -exchanges $exchanges -jobs $jobs -PathTappedMsgs $tappedMsgsDir

# Step03: Publish and receive messages one by one, so that we can store expected results for each input file
    # Initialise expected msgs directory 
    $expectedDir = "$TestDataDir/Expected"
    Initialize-Directory -path $expectedDir

    # publish all messages from input directory
    $inputDir = "$TestDataDir/Input"
    Publish-ReceiveMsgsOneByOne -InputDir  "$inputDir" -InputExchange "$InputExchange" -Queues $queues `
                                -ExpectedMsgsDir "$expectedDir" -TappedMsgsDir "$tappedMsgsDir"

    # publish all messages from duplicates directory
    $duplicateDir = "$TestDataDir/Duplicates"
    Publish-ReceiveMsgsOneByOne -InputDir  "$duplicateDir" -InputExchange "$InputExchange" -Queues $queues `
                                -ExpectedMsgsDir "$expectedDir" -TappedMsgsDir "$tappedMsgsDir"

# Step04: Housekeeping 
    Remove-Directory -path $tappedMsgsDir

# Step05: Remove the taps    
    Remove-TapOnExchange -jobNames $jobs

    Write-Host ("Finished script: $fn")
    Write-Verbose "===============================================================`n"
}

# Install dependent modules from TestModules directory, recursive and forcefully (to get latest changes)
. '/TestFramework/TestModules/import-modules.ps1'
Import-Modules -Path '/TestFramework'
    
# 01. Call the function you want to call with parameters
$testDataDir = '/test/TestData/EvenOdd' 
$exchange = 'my-input-exchange'
Set-ExpectedResultsEvenOdd -TestDataDir $testDataDir  -InputExchange $exchange 

# 02. Assert count of expected messages
$inputDir = '/test/TestData/EvenOdd/Input'
$countMsgs = Get-CountOfJsonMsgsInADirectory -Path $inputDir -keyForSorting 'conversationId'
Write-Host "Count of msgs published: $countMsgs"

$sql = 'SELECT [my-column]
            FROM [EvenOdd].[database-name].[my-table]' 
$rows = Get-SqlStatementDataRows -sqlStatement $sql
$NrOfRecords = $rows.Count
Write-Host "Count of msgs in table: $NrOfRecords"