
Start-Transcript -Path "/TestFramework/TestResults/debug.log"

# Install dependent modules from TestModules directory, recursive and forcefully (to get latest changes)
. '/TestFramework/TestModules/import-modules.ps1'
Import-Modules -Path '/TestFramework'

Write-Host "In the debug entrypoint"
# Write-Host "Starting test plan '$env:TEST_PLAN' - buildId '$env:BUILD_ID'"

Write-Host "Setup complete. Now going to sleep forever..."
Stop-Transcript

# Equivalent of CMD tail -f /dev/null
tail -f /dev/null