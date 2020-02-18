function Import-Modules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String] $Path 
    )

    # Install dependent modules
    Write-Host "Importing modules under Path: $Path `n" 
    foreach ($module in Get-Childitem "$Path" -Filter "*.psm1" -Recurse) {
        Import-Module $module.FullName -Force  # Use Force; so that the latest changes are imported. 
	}

    Write-Host "🟢 🐱 All modules imported! 🍕 ✅ `n" 
}