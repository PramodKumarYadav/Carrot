# To create new input files (which will then be the basis of creating all expected results later)

# Install dependent modules from TestModules directory, recursive and forcefully (to get latest changes)
. '/TestFramework/TestModules/import-modules.ps1'
Import-Modules -Path '/TestFramework'

$exchange = 'my-exchange-to-publish-message'
$TestDataDir = "C:\Carrot\TestFramework\TestData\EvenOdd"
$PathTemplate = 'C:\Carrot\TestFramework\TestData\Templates\Header_Template.json'

# Initialise input directory if not existing already. 
Initialize-Directory -path "$TestDataDir/Input"

# Create Input messages for all TestCases in the TestCases folder
Add-HeaderAndMsgFileInInputDir -ExchangeToPublish $exchange -TestDataDir $TestDataDir -PathHeaderTemplate $PathTemplate

Set-Location -Path '/test'
Write-Host "Done!"

function Add-HeaderAndMsgFileInInputDir {
    
    param(
        [Parameter(Mandatory=$True,HelpMessage="Exchange to publish final messages")]		
        [String]$ExchangeToPublish ,

        [Parameter(Mandatory=$True,HelpMessage="Directory to store test data for this exchange type")]		
        [String]$TestDataDir,

        [Parameter(Mandatory=$True,HelpMessage="Path for header template")]		
        [String]$PathHeaderTemplate
	)
  
    # Get the header type for this exchange
    $templateContent = Get-Content $PathHeaderTemplate -Raw
    Write-Host "Template: $templateContent"

    # Get all TestCases that we need to create input files for
    $TestCases = Get-ChildItem "$TestDataDir/TestCases" -Directory
    foreach ($TestCase in $TestCases){
        
        $TestCaseName = Split-Path -Path "$TestCase" -Leaf -Resolve

        # Create a TestCases folder in InputDir to hold the results
        $TCDir = "$TestDataDir/Input/$TestCaseName"
        Initialize-Directory -path $TCDir

        # For each event message (TestStep) create a rabtap header and the message file in rabtap replayable format
        $msgCount = 1;
        $files = Get-ChildItem "$TestCase" -File
        foreach ($file in $files){
            Write-Host $file

            # Replace the template values with input values and randomId for uniqueness of messages
            $randomDeliveryTag = Get-Random -Minimum 0 -Maximum 1000000 

            $XRabtapReceivedTimestamp = (get-date -Format o).Substring(0,27) + 'Z'

            # Make a copy of template
            $copyTemplate = $templateContent

            # Replace the placeholders in template with the values we calculated above (i.e. deliveryTag, exchangeName & XRabtapReceivedTimestamp)
            $rabtapHeader = $copyTemplate -replace '"valueDeliveryTag"', $randomDeliveryTag -replace "valueExchange","$Exchange" -replace "valueXRabtapReceivedTimestamp","$XRabtapReceivedTimestamp"

            # Create header and message file there
            $fileName = "rabtap-" + $msgCount.ToString().PadLeft(3,'0')
            
            $headerFile = "$TCDir/$fileName" + ".json"
            $rabtapHeader | Out-File -FilePath "$headerFile"

            $msgFile = "$TCDir/$fileName" + ".dat"
            Copy-Item -Path "$file" -Destination "$msgFile" 

            $msgCount++
        }
    }
}