function Publish-OutFolder {
    param(
            [String] $PathResultsToPublish,

            [String[]]$PublishURL
        )

    # Create out.zip
    Set-Location $PathResultsToPublish
    zip -r "$PathResultsToPublish/out.zip ./*"
    
    # Get the final test run status and pass this to publish-out to see overall run result
    $runStatus = Get-EnvVariable -name 'statusTestRun' -target 'process'

    # If statusTestRun was not set due to some error in processing, set the status to failed. Thus making sure the status always exists in published output.
    if(!$runStatus){
        $runStatus = 'Failed'
    }

    $publishTargetNoSas = "$PublishURL/$runStatus-$env:TEST_PLAN-$env:BUILD_ID.zip"
    Write-Host "`n `$publishTargetNoSas: $publishTargetNoSas " 

    $publishTarget = $publishTargetNoSas + "?" + $env:AZURE_STORAGE_SAS

    Write-Host "target for publish: " $publishTargetNoSas
    azcopy copy "out.zip" $publishTarget

    Set-Location -
}