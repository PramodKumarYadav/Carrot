# Wait for exchanges to be created 
function Wait-ForExchangeToBeCreated {
    param(
            [String[]]$exchanges
        )

    foreach($exchange in $exchanges){
        $exchangePresent = $false
        $regexGetExchange = "$exchange \(exchange"
        DO{           
            Write-Host "Checking for exchange: $exchange..."
			$info = rabtap info | Select-String $regexGetExchange
            $exchangePresent = $info.length -gt 0
            If ($exchangePresent) {
                Write-Host "$info`n..found"
            } Else {
                Write-Host "..not found"
                Start-Sleep -Seconds 1
            }
        }
        while($exchangePresent -eq $false)
    }

    Write-Host "`nAll exchanges found!"
    Write-Host "===============================================================`n"
}
# Wait for queues to be created 
function Wait-ForQueueToBeCreated {
    param(
            [String[]]$queues
        )

    foreach($queue in $queues){
        $queuePresent = $false
        $regexGetQueue = "$queue.*\(queue"
        DO{           
            Write-Host "Checking for queue: $queue ..."
			$info = rabtap info | Select-String $regexGetQueue
            $queuePresent = $info.length -gt 0
            If ($queuePresent) {
                Write-Host "$info`n..found"
            } Else {
                Write-Host "..not found"
                Start-Sleep -Seconds 1
            }
        }
        while($queuePresent -eq $false)
    }

    Write-Host "`nAll queues found!"
    Write-Host "===============================================================`n"
}
# Remove all/any previous running tap jobs (needed when debugging-stopping in middle of the script, multiple times) 
# If not, you will get corrupted results after second debug (due to multiple taps opening)
function Remove-TapOnExchange {
    # Removes tap jobs for $exchanges using $jobNames for job names 
     param(	
		[Parameter(Mandatory=$True,HelpMessage="job (tap) names")]		
        [String[]]$jobNames
	)

    # Check if there are any jobs at all to remove before checking each of them.
    $AnyjobPresent = (get-job).length -gt 0
    if ($AnyjobPresent){
        Write-Host "There are jobs present. Now we can find and terminate them!"

        Write-Host "Total Jobs present before removal of taps: " 
        Get-Job | Format-List -Property Id,Name,State
        Foreach ($job in $jobNames){

            # Check if the job exists
            # $jobItems = get-job -Name $job 
            $jobPresent = (get-job -Name $job).length -gt 0
            if ($jobPresent){            
                get-job -Name $job | Stop-Job
                get-job -Name $job | Remove-Job
                Write-Host "Job $job stopped and removed"
            }else {
                Write-Host "Job $job doesnt exist"
            }
        }
    
        Write-Host "Total Jobs present after removal of taps: " 
        get-job 
    } else{
        Write-Host "No jobs to terminate!"
    }
    
}
function Set-TapOnExchange{
    # Creates tap jobs for $exchanges using $jobs for job names (you will be able to Receive-Job and read the tap from these jobs)
     param(
		[Parameter(Mandatory=$True,HelpMessage="Full exchange names as seen in RabbitMQ.")]		
        [String[]]$exchanges,   
	
		[Parameter(Mandatory=$True,HelpMessage="jobs 1:1 to exchanges")]		
        [String[]]$jobs,

        [Parameter(Mandatory=$True,HelpMessage="Parent path location of all tapped msgs")]		
        [String]$PathTappedMsgs
	)

	$rabtapTapBlock = {
		param($_ex, $_dir)
		rabtap tap $_ex --saveto=$_dir --format=raw --silent   # suppress message output to stdout (gains performance).
	}

	if ($exchanges.Length -ne $jobs.Length){
		throw 'Set-TapOnExchange - different arrays length';
	}

    for ($i=0; $i -lt $exchanges.length; $i++){
		$ex = $exchanges[$i];
		$job = $jobs[$i];

		Write-Host "Setting tap on exchange: $ex"
		
		# 01. Fix the exchange name for escaping colons (due to a bug in rabtap: https://github.com/jandelgado/rabtap/issues/13 )
		$exchange = $ex.Replace(":","\:") + ":";
        
        $DIR = "$PathTappedMsgs/$job"
        New-Item -Path $DIR -ItemType "directory" -Force > $null # Create silently without throwing too many details in o/p
        
        # 02. Start the tap job
        Start-Job $rabtapTapBlock -ArgumentList $exchange, $DIR  -Name $job | Format-List -Property Id,Name,State

        # 03. Check for existence of queue tapping the exchange
        Wait-ForQueueToBeCreated("__tap-queue-for-$ex")
        
        Write-Host "`nTap set now on exchange!"
        Write-Host "===============================================================`n"
    }
}
# Publish and Wait for messages to be published
function Publish-AndWaitForMsgsToBePublished{
    param(       
        [Parameter(Mandatory=$True,HelpMessage="Path of Input directory to pick messages for publishing")]	    
        [String] $InputDir,

        [Parameter(Mandatory=$True,HelpMessage="Exchange to publish the messages")]	 
        [String] $InputExchange,

        [Parameter(Mandatory=$True,HelpMessage="Queues to check if they are consumed/empty or not")]	 
        [String[]]$Queues
    )

    # 01: Publish stored messages on tapped exchanges and process output: 
    Publish-AllMessagesFromInputDir -InputDir "$InputDir" -InputExchange $InputExchange

    # 02: Wait for a while for all messages to be published (Wait only once for all published msg files)
    Wait-ForQueueToBeEmpty -queueNames $Queues -waitBeforeCheckingQueue 2 -maxWaitCounter 180 

    Write-Host "`nMessages published and consumed on exchange: $InputExchange"
    Write-Host "===============================================================`n"
}
function Publish-AllMessagesFromInputDir{

    param(
       [Parameter(Mandatory=$True, HelpMessage="Directory to read and publish msgs from")]		
       [String] $InputDir,

       [Parameter(Mandatory=$True, HelpMessage="Exchange to publish these msgs")]		
       [String] $InputExchange
   )
    # Iterate over each sub directory in Input directory to create expected results
    $subDirs = Get-ChildItem $InputDir -Directory
    Foreach ($subDir in $subDirs){

        # Get subdirectory name
        $subDirName =  Split-Path -Path "$subDir" -Leaf -Resolve 

        # Publish stored messages on tapped exchanges and process output: 
        Publish-MsgsInDirectoryOnExchange -InputDir "$InputDir/$subDirName" -Exchange $InputExchange -DELAY '0s'
    }
    
    Write-Host "`nAll messages published from $inputDir!"
    Write-Host "===============================================================`n"
}
function Publish-MsgsInDirectoryOnExchange {
    param(       
        [Parameter(Mandatory=$True,HelpMessage="Path of directory from where to publish msgs")]	    
        [String] $InputDir,

        [Parameter(Mandatory=$True,HelpMessage="Exchange to publish the messages")]	 
        [String] $Exchange,

        [Parameter(Mandatory=$False,HelpMessage="Delay in publishing message(add). If not set then messages will be delayed as recorded. The value must be suffixed with a time unit, e.g. ms, s etc. Ex: --delay=0s is no delays")]	 
        [String] $DELAY,

        [Parameter(Mandatory=$False,HelpMessage="rate of publishing messages(product). Speed factor to use during publish [default: 1.0].")]	 
        [String] $FACTOR = 1.0 
    )

    # Publish stored messages on this exchange
    # Only One of the two (delay/factor) can be used at one time [--delay=DELAY | --speed=FACTOR] 
    if($DELAY){
        rabtap pub "$InputDir" --exchange="$Exchange" --format=raw --delay="$DELAY"
    }else{
        rabtap pub "$InputDir" --exchange="$Exchange" --format=raw  --speed="$FACTOR"
    }
    

    Write-Host "`nMessages in directory: $InputDir published on exchange: $Exchange!"
    Write-Host "===============================================================`n"
}
function Wait-ForQueueToBeEmpty {
    param(
        [String[]]$queueNames,
        [Int]$waitBeforeCheckingQueue = 3,

        [Parameter(Mandatory = $false)]  	
        [Int] $maxWaitCounter = 180 # With each counter 2 seconds wait, this makes default max 6 mins wait. To avoid going in infinite wait.
        # Kubernetes wait for pods increases exponentially starting from 10,20,40 secs. This means on 6th restart it becomes 4 min and from 7th restart onwards, fix wait of 5 mins. 
        # Waiting for 6 mins, ensure that we always have our results. That said, try to limit restarts within 5 restarts to get a good execution performance. 
        # https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy
    )

    Write-Host "Checking if the queues are processed ..."
    Start-Sleep -Seconds 6  # Initial wait before checking. Refresh rate is 5 secs on rabbitMq admin.
    
    # Define a regex to match for idle part of string i.e.: "cons, (0, 0.0/s) msg, (0, 0.0/s) msg ready"
    $regexIdleQueue = '^.*cons.*\(0, 0\.0\/s\) msg, \(0, 0\.0\/s\) msg ready.*$'
    Write-Host "regex to see if the queue is now idle: $regexIdleQueue"

    for ($i=0; $i -lt $queueNames.length; $i++){
        $queueName = $queueNames[$i];
        
        Write-Host "`nChecking queue...: $queueName"
        Start-Sleep -Seconds $waitBeforeCheckingQueue

        $waitCounter = 0;
        
        $queueActive = $true
        DO{
                
            # Get queue with name queueName 
            $regexGetQueues = "$queueName \(queue"
            $myqueue = rabtap info --stats | Select-String $regexGetQueues
            Write-Host "`nContent parsed in myqueue: $myqueue"

            # Get the first queue (there are two returned)
            $myqueue = $myqueue[0]
            Write-Host "`nFirst row of myqueue: $myqueue"

            # Match the queue content with regexIdle to see if we have an idle queue
            if ($myqueue -match $regexIdleQueue){
                $queueActive = $false
                Write-Host "`nAll messages consumed in Queue: $queueName "
            }else {
                Write-Host "Waiting for 2 more seconds to finish publishing of msgs in queue: $queueName ..."
                Start-Sleep -Seconds 2
                $waitCounter++;
            } 
            
            if($waitCounter -gt $maxWaitCounter){
                Write-Error "`nTimed Out. There are still messages on the queue!"
                Write-Error "Results not reliable in this case..."
            }       

        } while($queueActive -and ($waitCounter -le $maxWaitCounter) )

        Write-Host "===============================================================`n"
    }
}
function Publish-ReceiveMsgsOneByOne{

    param(
       [Parameter(Mandatory=$True, HelpMessage="Directory to read and publish msgs from")]		
       [String] $InputDir,

       [Parameter(Mandatory=$True, HelpMessage="Exchange to publish these msgs")]		
       [String] $InputExchange,

       [Parameter(Mandatory=$True, HelpMessage="Queues to check")]		
       [String[]] $Queues,

       [Parameter(Mandatory=$True, HelpMessage="Expected Msgs root directory")]		
       [String] $ExpectedMsgsDir,

       [Parameter(Mandatory=$True, HelpMessage="Directory to temporary store these tapped msgs")]		
       [String] $TappedMsgsDir

   )
    # Iterate over each sub directory in Input directory to create expected results
    $subDirs = Get-ChildItem $InputDir -Directory
    Foreach ($subDir in $subDirs){

        # Get subdirectory name
        $subDirName =  Split-Path -Path "$subDir" -Leaf -Resolve 

        # 01: Publish stored messages on tapped exchanges and process output: 
        Publish-MsgsInDirectoryOnExchange -InputDir "$InputDir/$subDirName" -Exchange $InputExchange -DELAY '0s'

        # 02: Wait for a while for all messages to be published (Wait only once for all published msg files)
        Wait-ForQueueToBeEmpty -queueNames $Queues -waitBeforeCheckingQueue 2 -maxWaitCounter 180 

        # Initialise the expected msgs directory for this scenario
        $resultsDir = "$ExpectedMsgsDir/$subDirName"
        Initialize-Directory -path $resultsDir

        # Now whatever you received in the tapped msgs directory, move it to the expected directory
        Copy-Item -Path "$TappedMsgsDir\*" -Destination "$resultsDir" -Recurse -Force

        # Remove all files in the tapped directory for next scenario.
        Get-Childitem "$TappedMsgsDir\*" -File -Recurse | Foreach-Object {Remove-Item $_.FullName}
        
        Write-Host "===============================================================`n"
    }
    
    Write-Host "`nAll messages published and received from $inputDir!"
    Write-Host "===============================================================`n"
}
function Wait-ForAQueueConsumer {
    param(
        [String[]]$queueNames,
        [Int]$waitBeforeCheckingQueue = 7,

        [Parameter(Mandatory = $false)]  	
        [Int] $maxWaitCounter = 180 # With each counter 2 seconds wait, this makes default max 6 mins wait. To avoid going in infinite wait.
        # Kubernetes wait for pods increases exponentially starting from 10,20,40 secs. This means from 6th restart it becomes 5 min and there onwards a fix wait of 5 mins. 
        # Waiting for 6 mins, ensure that we always have our results. That said, try to limit restarts within 5 restarts to get a good execution performance. Works well when run from EntryPoint.
        # https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy
    )

    foreach($queueName in $queueNames){
        
        Write-Host "`nChecking queue for consumers...: $queueName"
        Start-Sleep -Seconds $waitBeforeCheckingQueue

        $waitCounter = 0;        
        $haveConsumers = $false
        $regExPattern = ' \(queue,'

        Write-Host "Initial status of the queue"       
        rabtap info --stats | Select-String $queueName | Select-String $regExPattern

        DO{
                
            # Command used: rabtap info --stats | grep message_queue_name | grep '(queue' | grep '0 cons'           
            $zeroConsumers = rabtap info --stats | Select-String $queueName | Select-String $regExPattern | Select-String  '0 cons'
            Write-Host "`nCount of zeroConsumer records in rabtap info: " $zeroConsumers.Length

            # Match the queue content with regexIdle to see if we have an idle queue
            if ($zeroConsumers.Length -ge 1){
                
                Write-Host "Waiting for 2 more seconds to see if there are any consumers on the queue: $queueName ..."
                Start-Sleep -Seconds 2
                $waitCounter++;   
            }else {
                $haveConsumers = $true 
                Write-Host "`nQueue now have a consumer. Meaning the consuming application is up: $queueName"
                rabtap info --stats | Select-String $queueName | Select-String $regExPattern
            } 
            
            if($waitCounter -gt $maxWaitCounter){
                Write-Warning "`nTimed Out. Still no consumers of the queue!"
                Write-Error "Results not reliable in this case..."
            }       

        } while(($haveConsumers -eq $false) -and ($waitCounter -le $maxWaitCounter) )

        Write-Host "===============================================================`n"
    }
}
# ToDo: Refine below as per latest rabtap version
function Set-DebugTapOnExchange {

    param(
       [Parameter(Mandatory=$True, 
                  HelpMessage="Full exchange name as seen in RabbitMQ.")]		
       [String] $Exchange  
   )

   $exForTap = $exchange.Replace(":","\:") + ":";
   rabtap tap $exForTap --json
}