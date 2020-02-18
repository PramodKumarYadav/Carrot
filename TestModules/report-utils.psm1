function Set-RunStatus{
    <#
    .SYNOPSIS
    To Set the overall run status for this Test run
    .DESCRIPTION
    Note: For this function to work correctly, it expects atleast 3 levels of hierarchy (more is Okay).
    So say /test/out/systemUnderTest/TSfolder/[multiple TC folders for each exchange] is minimum requirement.
    This will also work: /test/out/systemUnderTest/SubSystem/SubSubSystem/.../TSfolder/morefoldersunder.../[multiple TC folders for each exchange]
    .PARAMETER pathParentTS
    The parameter 'pathParentTS' should be path just until-above TSfolder (in each case above).Then this fn would work Ok.
    .EXAMPLE
    Set-RunStatus -pathParentTS '/test/out/Arjuna'
    Set-RunStatus -pathParentTS '/test/out/Pandav/Bheem'
    #>
    
    param(		
        [parameter(Mandatory = $true)]
        [string] $pathParentTS 
	)   
    
    Write-Host ("[Executing script]: {0} " -f $MyInvocation.MyCommand.Name)

    # Step01: Set the Overall TestRunStatus flag as FAILED (Make it OK, only when if there was atleast one test to test). 
    # Also any single failure below and this status will turn back, to Failed. This is to avoid False OKays when there are no tests to run. 
    $statusTestRun = 'FAILED'

    # Step02: Get content of a OK file with no failures (used for comparing with actual scenario-results.json files to determine if a TC was pass/fail)
    $contentOKFile = Get-OKScenarioResultsContent

    # Step03: Get Test Scenario folders
    $run = 0;

    $TSFolders = Get-ChildItem -Path $pathParentTS 
    foreach ($TSfolder in $TSFolders){
        Write-Host "Running TS: "  $TSfolder
        
        # Step04: Set the Overall TestScenarioStatus flag as OK (any single failure below and this status will turn to Failed)
        $statusTestScenario = 'OK'

        # Step05: Get TestCase folders (folders that contain scenario-results.json file )
        $TCFolders = Get-ChildItem -Path $TSfolder -Recurse -File | ForEach-Object {$_.FullName | Select-String 'scenario-results\.json' }
        foreach ($TCfolder in $TCFolders){
            
            # Step06: Set default TC status to 'Failed'. Reset it only if the TC was passed. 
            $statusTestCase = 'Failed'
            $contentActualScenarioFile = Get-Content -Path $TCfolder -Raw
            $contentActualScenarioFile = $contentActualScenarioFile.Trim() # Do not refactor this step to above. If the file scenario-results is empty ".trim" will fail.
            # If there was atleast one test to test, now we can confidently set the flag to OK (as Initial status). Only set one time.
            if($run -eq 0){
                $statusTestRun = 'OK'
            }

            if($contentOKFile.Equals($contentActualScenarioFile)){
                $statusTestCase = 'OK'
            }else{
                # Step07: If one test case fails, this scenario has failed and so has the TestRun
                $statusTestScenario = 'FAILED'
                $statusTestRun = 'FAILED'
            }

            # Step08: Set the TC folder name with the value of $statusTestCase
            Set-TestCaseStatus -status $statusTestCase -path $TCfolder
            
            $run++
        }

        # Step09: Set the TS folder name with the value of $statusTestScenario
        Set-TestScenarioStatus -status $statusTestScenario -path $TSfolder
    }
    
    # Step10: Set the TR status in an env variable, so that it can be used in publish-documents funtion; to Set the TR folder name with the value of $statusTestRun
    Set-TestRunStatus -status $statusTestRun

    Write-Host ("[Execution finished]: {0} " -f $MyInvocation.MyCommand.Name)
    Write-Host "===============================================================`n"
}

function Get-OKScenarioResultsContent {  

    $contentScenariosResultFile = '{
        "scenariosWithMissingKeys": [],
        "scenariosWithUnexpectedKeys": [],
        "scenariosWithAddedFields": [],
        "scenariosWithDeletedFields": [],
        "scenariosWithUpdatedFields": [],
        "orphans": []
      }'
    
    # Prettify json, else it wouldnt match with actual content
    $contentScenariosResultFile = $contentScenariosResultFile | ConvertFrom-Json | ConvertTo-Json 

    return $contentScenariosResultFile
}

function Set-TestCaseStatus {
    param(		
        [parameter(Mandatory = $true)]
        [string] $status,

        [parameter(Mandatory = $true)]
        [string] $path
	)   
    
    Write-Host ("[Executing script]: {0} " -f $MyInvocation.MyCommand.Name)

    # Get TC folder path 
    $pathTCFolder = Split-Path $path
    Write-Host $pathTCFolder

    # Get TC name
    $nameTC = Split-Path $pathTCFolder -Leaf
    Write-Host $nameTC

    # Get TC folder's parent path
    $pathTCParent = Split-Path $pathTCFolder 
    Write-Host $pathTCParent

    # Move item from old directoy to new directory
    Move-Item -Path $pathTCFolder -Destination "$pathTCParent\$status-$nameTC"

    Write-Host ("[Execution finished]: {0} " -f $MyInvocation.MyCommand.Name)
    Write-Host "===============================================================`n"
}

function Set-TestScenarioStatus {
    param(		
        [parameter(Mandatory = $true)]
        [string] $status,

        [parameter(Mandatory = $true)]
        [string] $path
	)   
    
    Write-Host ("[Executing script]: {0} " -f $MyInvocation.MyCommand.Name)

    # Get TS folder name
    $nameTSFolder = Split-Path $path -Leaf
    Write-Host $nameTSFolder

    # Get TS parent's path
    $pathParent = Split-Path $path
    Write-Host $pathParent

    # Move item from old directoy to new directory
    Move-Item -Path $path -Destination "$pathParent\$status-$nameTSFolder"

    Write-Host ("[Execution finished]: {0} " -f $MyInvocation.MyCommand.Name)
    Write-Host "===============================================================`n"
}

function Set-TestRunStatus {
    param(		
        [parameter(Mandatory = $true)]
        [string] $status
	)   
    
    Write-Host ("[Executing script]: {0} " -f $MyInvocation.MyCommand.Name)

    # We want to pass the final status to the publish folder function, so that it shows in storage what the status of exeuction was.
    # Thus, Set variable on the process env level 
    Set-EnvVariable -name 'statusTestRun' -value $status -target 'Process'

    Write-Host ("[Execution finished]: {0} " -f $MyInvocation.MyCommand.Name)
    Write-Host "===============================================================`n"
}

function Set-EnvVariable {
    param(		
        [parameter(Mandatory = $true)]
        [string] $name,

        [parameter(Mandatory = $true)]
        [string] $value,

        [parameter(Mandatory = $true)]
        [string] $target # Machine, User, Process
	)   
    
    [System.Environment]::SetEnvironmentVariable("$name","$value","$target")

    Get-EnvVariable -name "$name" -target "$target"
}

function Get-EnvVariable {
    param(		
        [parameter(Mandatory = $true)]
        [string] $name,

        [parameter(Mandatory = $true)]
        [string] $target # Machine, User, Process
	)   
    
    $value = [System.Environment]::GetEnvironmentVariable("$name","$target")
    Write-Host  "`$name: $name ; `$value: $value ; `$target: $target" 

    return $value
}