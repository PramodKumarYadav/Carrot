function Test-RunScenarios{
    param(		
        [parameter(Mandatory = $true)]
        [string] $ScriptName,

        [parameter(Mandatory = $true)]
        [string] $Application,

        [parameter(Mandatory = $true)]
        [string[]] $TestScenarios,
        
        [parameter(Mandatory = $true)]
        [string] $InputExchange
	)
    
    $fn = $MyInvocation.MyCommand.Name
    Write-Host ("`nExecuting script: $fn")
    
    $run=0   
    Foreach ($TestScenario in $TestScenarios){
        Write-Host "Executing Test scenario: $TestScenario!`n"
        
        Invoke-Expression "$ScriptName -Application $Application -TestScenario $TestScenario -InputExchange $InputExchange"
        $run++
    }

    Write-Host ("Execution finished: {0} " -f $MyInvocation.MyCommand.Name)
    Write-Host "===============================================================`n"
}
# This function expects that there is already expected results created before calling this function (and only one expected results file in the outputDir directory). 
# This function can then compare expected and actual for a table and create results.
function Test-TableExpectedVsActual{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] 
        [string] $outputDir,

        [parameter(Mandatory = $true)] 
        $keyField,

        [parameter(Mandatory = $true)] 
        $sql
    ) 

    $fn = $MyInvocation.MyCommand.Name
    Write-Host ("`nExecuting script: $fn")

    Write-Host "$fn : create map scenario <-> [$keyField] in the results folder for all tapped exchanges"
    Publish-KeysFromDir -sourceDir "$outputDir" -target "$outputDir/scenarios.json" -keyField "$keyField" 

    Write-Host "$fn : Get actual results as JSON file (This step ONLY after the above mapping was created. Else it would have also copied the actual files resourceName )"
    Set-TableResultAsJson -sql "$sql" -PathOutDir "$outputDir"
    
    Write-Host "$fn : Sort expected.txt and actual.txt files on $keyField before compare"
    Set-SortJsonOnAKey -jsonFilePath  "$outputDir/Expected.txt" -keyForSorting "$keyField"
    Set-SortJsonOnAKey -jsonFilePath  "$outputDir/Actual.txt" -keyForSorting "$keyField"

    Write-Host "$fn : create json diff of exp/actual"
    node "/test/TestModules/nodejs/jsondiff.js" "$outputDir/Expected.txt" "$outputDir/Actual.txt" "$keyField"  > "$outputDir/Expected.txt.diff"

    Write-Host "$fn : create 'scenario results' file"
    node "/test/TestModules/nodejs/create-scenario-results.js" "$outputDir/scenarios.json" "$outputDir/Expected.txt.diff" "$keyField" > "$outputDir/scenario-results.json"

    Write-Host ("Finished script: $fn")
}