
Start-Transcript -Path "/TestFramework/TestResults/debug.log"

# Install dependent modules from TestModules directory, recursive and forcefully (to get latest changes)
. '/TestFramework/TestModules/import-modules.ps1'
Import-Modules -Path '/TestFramework'

Write-Host "In the main entrypoint"
# Write-Host "Starting test plan '$env:TEST_PLAN' - buildId '$env:BUILD_ID'"

# run tests according to plan
switch ($env:TEST_PLAN) {
    
    "even-odd"       { Test-ScenariosEvenOdd -Application 'EvenOdd'; break; }

    "positive-int"   { Test-ScenariosPositiveInt -Application 'Int/Positive'; break; }
    "negative-int"   { Test-ScenariosPositiveInt -Application 'Int/Negative'; break; }

    "debug"          { Test-ScenariosEvenOdd -Application 'EvenOdd'; break; }

    default {"Did not find an associated plan!"; break}
}

Stop-Transcript

# Get path of results directory
$outDirectory = Get-EnvVariable -name "outDir" -target 'Process'

# Set the run status for this overall Test run
Set-RunStatus -pathParentTS "$outDirectory"

# Publish out folder into to azure blob storage
Publish-OutFolder