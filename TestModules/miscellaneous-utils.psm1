function Convert-ToBase64String {
    
    param(
        [Parameter(Mandatory=$True,HelpMessage="String that we want to base64 encode")]		
        [String]$Payload 
	)

    # Base64 encode content
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Payload -join [Environment]::NewLine) #NewLine is required.
    $EncodedPayload =[Convert]::ToBase64String($Bytes)
    return $EncodedPayload
}