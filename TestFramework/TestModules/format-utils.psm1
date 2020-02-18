# Tested OKay
Function Convert-PSObjectArrayToJSON{
    [CmdletBinding()]
    Param(
        [parameter(Mandatory,ValueFromPipeline)]
        [object[]]$PSObjectArray
    )
        
    return $PSObjectArray | ConvertTo-Json 
}

# Tested OKay
Function Convert-PSObjectArrayToCSV{
    [CmdletBinding()]
    Param(
        [parameter(Mandatory,ValueFromPipeline)]
        [object[]]$PSObjectArray
    )
         
    return $PSObjectArray | ConvertTo-Csv -NoTypeInformation
}

Function Convert-PSObjectArrayToXML{
    [CmdletBinding()]
    Param(
        [parameter(Mandatory,ValueFromPipeline)]
        [object[]]$PSObjectArray
    )
     
        return $PSObjectArray | ConvertTo-Xml -NoTypeInformation 
}