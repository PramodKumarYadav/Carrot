# To check 'say' a database-table is up or not. 
function Wait-PositiveResultFromSqlQuery {
    param(
		[Parameter(Mandatory = $true)]  
		[Alias('sql')]		
		[String] $sql,

		[Parameter(Mandatory = $false)]  	
		[Int] $maxWaitCounter = 180 # With each counter 2 seconds wait, this makes default max 6 mins wait. To avoid going in infinite wait.
	)

	Write-Host "sql: $sql"

	if ($sql.Length -lt 1){
		Write-Host 'Empty sql statement passed :(('
		return;
	}

	$waitCounter = 0;
	$countOfRecords = 0
	DO{           
		$Tables = Invoke-Sqlcmd -ServerInstance $env:SQL_SERVER -query $sql -As DataTables -username $env:SQL_USERNAME -password $env:SQL_PASSWORD
		$countOfRecords = $Tables.Rows.Count
		Write-Host "count of records: $countOfRecords"
		
		if($countOfRecords -eq 0){
			Write-Host "Query returned empty set - waiting for 2 more seconds..."
			Start-Sleep -Seconds 2
			$waitCounter++;
		}
		
		if($waitCounter -gt $maxWaitCounter){
			Write-Error "`nTimed Out. DB not available or query not returning proper results."
			Write-Error "Results not reliable in this case..."
		} 
		
	} while (($countOfRecords -eq 0) -and ($waitCounter -le $maxWaitCounter))
}

# Delete all tables in the file (useful when running in debug mode, when running multiple times). 
function Invoke-TruncateTablesWhenNeeded {
    param(
		[Parameter(Mandatory = $false)]  
		[String] $PathSQLFile 
	)
	# Reason from buddy (Antonio): I would do this only in debug/local mode. Imagine someone introduces a bad thing in one of the apps
    # that writes something in the DB at startup that would break the test.. this sql script would remove the problem :D
    Write-Host "Value of `$env:LOCAL_DEBUG: $env:LOCAL_DEBUG "
    if( $env:LOCAL_DEBUG -eq 'true'){
        Invoke-SqlFile -sqlFile "$PathSQLFile"
	}
}
# Invoke a sql File
function Invoke-SqlFile {
    param(
		[Parameter(Mandatory = $false)]  
		[Alias('file')]		
		[String] $sqlFile
	)

	Write-Host ("Executing script: {0} " -f $MyInvocation.MyCommand.Name)
	
	Write-Host "sqlFile: $sqlFile"
    if (Test-Path $sqlFile) {		
		Invoke-Sqlcmd -ServerInstance $env:SQL_SERVER -InputFile $sqlFile -username $env:SQL_USERNAME -password $env:SQL_PASSWORD
		Write-Host "sqlFile Executed! `n"
	}else {
        Write-Host 'SQL file doesnt exist :(('
	}
	
	Write-Host "===============================================================`n"
}
function Invoke-SqlStatement {
    param(
		[Parameter(Mandatory = $false)]
		[Alias('sql')]
		[String] $sql 
	)
	
	Write-Host ("Executing script: {0} " -f $MyInvocation.MyCommand.Name)

	Write-Host "sqlStatement: $sql"
    if ($sql.Length -gt 0){
		Invoke-Sqlcmd -ServerInstance $env:SQL_SERVER -query $sql -username $env:SQL_USERNAME -password $env:SQL_PASSWORD
	}else {
        Write-Host 'Empty sql statement passed :(('
	}
	
	Write-Host "===============================================================`n"
}
function Set-TableResultAsJson{
    param(
		[Parameter(Mandatory = $true)]  	
        [String] $sql,
        
        [parameter(Mandatory = $true)] 
        [string] $PathOutDir
    )
	
	$fn = $MyInvocation.MyCommand.Name
	Write-Host ("`nExecuting script: $fn")
	
    $result = Get-SqlStatementDataRows -sqlStatement $sql

    # Get dataRows output as Json: https://mac-blog.org.ua/powershell-invoke-sqlcmd-convertto-json/ 
    $json = $result | Select-Object * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors | ConvertTo-Json 
    $json > "$PathOutDir/Actual.txt" 
}
function Get-SqlStatementDataRows {
    param(
		[Parameter(Mandatory = $false)]  
		[Alias('sql')]		
		[String] $sql 
	)

	$fn = $MyInvocation.MyCommand.Name
    Write-Host ("`nExecuting script: $fn")

	Write-Host "sqlStatement: $sql"
	
    if ($sql.Length -gt 0){
		$resultSet = Invoke-Sqlcmd -ServerInstance $env:SQL_SERVER -query $sql -username $env:SQL_USERNAME -password $env:SQL_PASSWORD
	}else {
		Write-Host 'Empty sql statement passed :(('
		$resultSet = ''
	}
	
	return $resultSet
}
