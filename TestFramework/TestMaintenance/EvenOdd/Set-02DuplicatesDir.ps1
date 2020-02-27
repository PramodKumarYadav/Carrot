# To create new input files (which will then be the basis of creating all expected results later)
    
# Install dependent modules from TestModules directory, recursive and forcefully (to get latest changes)
. '/TestFramework/TestModules/import-modules.ps1'
Import-Modules -Path '/TestFramework'

# EvenOdd directory
$TestDataDir = "C:\Carrot\TestFramework\TestData\EvenOdd"

# Initialise duplicates directory
$duplicateDir = "$TestDataDir/Duplicates"
Initialize-Directory $duplicateDir

# Inputs directory
$inputDir = "$TestDataDir/Input"

# 01. Create duplicate messages (since rabbit can send same message multiple times- valid case)
$SubDirName = 'This-is-name-of-one-of-my-test-cases-in-input-directory'
Copy-InputSubDirToDuplicatesDirAndRename -PathInput "$inputDir" -SubDirName "$SubDirName" `
                                         -PathDuplicates "$duplicateDir" -TestForSystem "EvenOdd"

Set-Location -Path '/test'
Write-Host "Done!"

function Copy-InputSubDirToDuplicatesDirAndRename {
    
    param(
        [Parameter(Mandatory=$True,HelpMessage="Path Input directory")]		
        [String]$PathInput,

        [Parameter(Mandatory=$True,HelpMessage="Sub directory name in Input Directoy to copy")]		
        [String]$SubDirName,

        [Parameter(Mandatory=$True,HelpMessage="Path Duplicates directory")]		
        [String]$PathDuplicates,

        [Parameter(Mandatory=$True,HelpMessage="Name of system you want to make a copy for")]		
        [String]$TestForSystem 
	)

    # Make a copy of the duplicate scenario to duplicates directory
    Copy-Item -Path "$PathInput/$SubDirName" -Destination "$PathDuplicates" -Recurse -Force

    # Rename to another folder as -copy. Needed while building expected results script (else results will overwrite each other)
    Rename-Item -Path "$PathDuplicates/$SubDirName" -NewName "$PathDuplicates/$SubDirName-$TestForSystem-duplicate"

    Write-Host "Input msg duplicated and renamed as a $TestForSystem-duplicate in $PathDuplicates"
}