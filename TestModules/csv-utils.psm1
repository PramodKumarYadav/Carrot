# This function can be used by both sql table output and csv output to sort the output before compare
function Get-SortedCSVOnKeys{
    [CmdletBinding()]
    param(		
        [parameter(Mandatory = $true)]
        [string] $path,    
        
        [parameter(Mandatory = $true)]
        [string[]] $sortOnKeys 
    )   
    
    Import-Csv -Path $path | Sort-Object $sortOnKeys -Ascending | Export-Csv -Path $path -NoTypeInformation
}

function Convert-InputFileNamesToWhereClause{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $false)] # For testing, later make this mandatory
        [string] $PathDir = '/test/TestData/MyApp/FTPImport/Input'
    ) 
    # Get all the file names in a folder in an array
    $inputFiles = Get-ChildItem -Path $PathDir –File -Recurse
    Foreach ($inputFile in $inputFiles){
        # Make a comma seperated where clause string input with the file names
        $WhereClauseString += "$($inputFile.BaseName),"
    }
    
    # Trim the ending comma and return 
    return $WhereClauseString.TrimEnd(',')
}

function Get-CountOfRecordsInACSVFile{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] 
        [string] $FilePath,
        
        [string[]] $Headers,

        [string] $Delimiter = ','   # Default is ',' 
    ) 

    $records = Get-CSVRecordSet -FilePath $FilePath -Delimiter $Delimiter -Header $Headers

    $count =  $records.Count
    return $count
}

function Get-CSVRecordSet{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] 
        [string] $FilePath,
        
        [string[]] $Headers,

        [string] $Delimiter = ','   # Default is ',' 
    ) 

    # Pass on the file name and delimiter to get the records in a file
    if($null -eq $Headers){
        $records = Import-Csv -Path $FilePath -Delimiter $Delimiter -Encoding UTF8
    }else{       
        $records = Import-Csv -Path $FilePath -Delimiter $Delimiter -Encoding UTF8 -Header $Headers
    }

    return $records
}

function Get-CSVFileHeaderNames{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] 
        [string] $FilePath,

        [string[]] $Headers,

        [string] $Delimiter = ','   # Default is ',' 
    ) 

    # Pass on the file name and delimiter to get the records in a file
    $records = Get-CSVRecordSet -FilePath $FilePath -Delimiter $Delimiter -Header $Headers
    $headerNames = $records[0].psobject.Properties.Name

    return $headerNames
}

function Show-EachValueInCSVRecord{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] 
        [string] $FilePath,
        
        [string[]] $Headers,

        [string] $Delimiter = ','   # Default is ',' 
    ) 
    $records = Get-CSVRecordSet -FilePath $FilePath -Delimiter $Delimiter -Header $Headers
    $headerNames = $records[0].psobject.Properties.Name

    ForEach ($record in $records){
        Write-Host "-------------------------"
        ForEach ($headerName in $headerNames){
            $header = $($record.$headerName)
            Write-Host $header 
        }
    }
    Write-Host "-------------------------"
}

function Convert-CSVFileToJSON{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] 
        [string] $FilePath,
        
        [string[]] $Headers,

        [string] $Delimiter = ','   # Default is ',' 
    ) 

    $records = Get-CSVRecordSet -FilePath $FilePath -Delimiter $Delimiter -Header $Headers
    $json = $records | ConvertTo-Json

    return $json
}