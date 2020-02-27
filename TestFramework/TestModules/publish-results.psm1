function Publish-TestResults {
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
function Get-TestResults{
    param(
            [Parameter(Mandatory = $true)]    
            [string] $containerName,

            [Parameter(Mandatory = $true)]    
            [String] $testPlan,

            [Parameter(Mandatory = $true)]    
            [String] $buildId,

            [Parameter(Mandatory = $true)]    
            [String] $SAS # NOTE: SAS key should be passed in the calling function. We dont want to provide here since it is a secret.
        )

        # URL would be either OK-testplanname-buildid or FAILED-testplanname-buildid
        $urlNoSasOK = Set-URL -status 'OK'
        $urlOK = $urlNoSasOK + "?$SAS"

        $urlNoSasFAILED = Set-URL -status 'FAILED'
        $urlFAILED = $urlNoSasFAILED + "?$SAS"

        $attempt = 0;
        $statuscode = 418 #I'm a ☕🍃

        # Assume $urlToDownloadFrom start with OK, unless we find otherwise in below code
        $urlToDownloadFrom = $urlOK
        do{
            Write-Host "Attempt $attempt\300:"
            $attempt++
            
            $statusCode = Get-UrlStatusCode $urlOK
            Write-Host "Got $statusCode from $urlNoSasOK" #urlOK also contains SAS key, so we dont use that
            
            if ($statusCode -eq 200){
                Write-Host "Success! Got $statusCode from $urlNoSasOK" 
            }

            # Try with the failed status URL only if the statusCode from OK-url was not 200
            if ($statusCode -ne 200){
                $statusCode = Get-UrlStatusCode $urlFAILED
                Write-Host "Got $statusCode from $urlNoSasFAILED" #urlFAILED also contains SAS key, so we dont use that
                if ($statusCode -eq 200){
                    $urlToDownloadFrom = $urlFAILED
                    Write-Host "Success! Got $statusCode from $urlNoSasFAILED" 
                }
            }
        
            Start-Sleep -Seconds 2
        } while ($statusCode -ne 200 -and $attempt -lt 300) #until 200 OK or 300 attempts ~ >10 mins

        # Download test-results in current location
        Invoke-WebRequest -Uri $urlToDownloadFrom -OutFile test-results.zip
}

function Set-URL{
    param(		
        [parameter(Mandatory = $true)]
        [string] $status 
    )
    
    $urlNoSas = ('https://your-test-url-that-has-your-test-results.blob.core.windows.net/{0}/{1}-{2}-{3}.zip' -f $containerName.Trim(), $status, $testPlan.Trim(), $buildId.Trim());
    Write-Host "url w/o sas with `$status:$status :" $urlNoSas

    return $urlNoSas
}
function Get-UrlStatusCode([string] $Url)
{
    try
    {
        (Invoke-WebRequest -Uri $Url -UseBasicParsing -DisableKeepAlive).StatusCode
    }
    catch [Net.WebException]
    {
        [int]$_.Exception.Response.StatusCode
    }
    catch
    {
        #https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest?view=powershell-6
        $_.Exception.Response.StatusCode.value__
    }
}

# Get-TestResults a b c d