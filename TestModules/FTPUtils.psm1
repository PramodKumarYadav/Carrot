function Disable-HostKeyCheck{
    ssh -o "StrictHostKeyChecking=no" test@ftp # adds ftp public key (generated at every run/deploy) to the known_hosts
}

function Export-LocalToFTPDirectory {
    param(
    [Parameter(Mandatory = $true)]    
    [String] $localPath,   # mind your CWD, or use full paths. e.g. '/test/TestData/App/FTPImport/Input/ccv' for direcotry or ending with say'.../ccv/filename.csv' for files
    
    [Parameter(Mandatory = $true)]    
    [String] $ftpDirName       # the name of the ftp directory to upload to. e.g. 'ccv'. ccv is created by ftp container according to SFTP_USERS env var
    )

    if (!(Test-Path /root/.ssh/known_hosts)){
        Disable-HostKeyCheck
    }

    # If Directory, use localPath without quotes (otherwise it doesnt work)
    if((Get-Item $localPath) -is [System.IO.DirectoryInfo]){
        $localPath = "$localPath/*"  # e.g. '/test/TestData/App/FTPImport/Input/ccv/*'
        Write-Output "put $localPath" > batchFile
    }else {
        Write-Output "put '$localPath'" > batchFile
    }

    sftp -b batchFile test@ftp:$ftpDirName # does not need a pwd because ftp deployment is configured to include test key
    rm batchFile
}

function Remove-FTPDirectory{
    param(
    [Parameter(Mandatory = $true)]    
    [String] $ftpDirName       # the name of the ftp directory to delete its contents. e.g. 'ccv'. 
    )

    if (!(Test-Path /root/.ssh/known_hosts)){
        Disable-HostKeyCheck
    }

    Write-Output "rm *" > batchFile
    sftp -b batchFile test@ftp:$ftpDirName
    rm batchFile
}