
# Idea is: A scenario is domain aware. It knows, the configuration for the application under test.
# The test case that scenario calls, will get these values from here.
function Test-ScenariosEvenOdd{
    [CmdletBinding()]
    param(		
        [parameter(Mandatory = $true)]
        [string] $Application # Give application sub path (ex: Integer/Positive)
    )

    $fn = $MyInvocation.MyCommand.Name
    Write-Host ("`nExecuting script: $fn")

    # Initialise out directory (only once for all Test Scenarios - needed when running in debug mode)
    $outDir = "/test/out/$Application"
    Initialize-Directory -path $outDir
    
    # Set out directory that is used in the Set-RunStatus function in main.ps1
    Set-EnvVariable -name 'outDir' -value $outDir -target 'Process'

    # Define domain specific variables
    $CheckedExchanges = @("myexchange:Number");

    $TappedExchanges = @("myexchange:Even",
                        "myexchange:Odd");

    $Jobs = @('Even', 'Odd');
    
    $InputExchange = $CheckedExchanges[0];

    $Queues = @("even_message_queue",
                "odd_message_queue");

    $run=0
    # This will serve as TS directory above TC directories that we will be used later in the reporting script
    $TestScenarios = @('Even','Odd')
    Foreach ($TestScenario in $TestScenarios){
        Write-Host "Executing Test scenario: $TestScenario!`n"
        
        # Generally we want to truncate tables except-"when running in cluster for its very 1st run"
        # This is to ensure we dont remove an sql injection done by say a malware/defect. 
        # For debug, we want to set this as true for each run (else we get corrupt results in consecutive debug runs)
        $CleanDb = $true 
        if( $env:LOCAL_DEBUG -ne 'true' -and $run -eq 0){
            Write-Host "Running in clustor for first test run. Thus CleanDb is set to false. `n"
            $CleanDb = $false
        }

        Test-EvenOdd    -Application $Application -TestScenario $TestScenario `
                        -TappedExchanges $TappedExchanges -CheckedExchanges $CheckedExchanges `
                        -InputExchange $InputExchange -Queues $Queues `
                        -Jobs $Jobs -CleanDb $CleanDb

        $run++
    }

    Write-Host ("Finished script: $fn")
    Write-Verbose "===============================================================`n"
}