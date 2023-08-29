Set-Location '/root/powershell'
$env:GLRoot = '/root/powershell'
$env:GLServer = "localhost"

if (!(Test-Path '/root/powershell/PSGELF')){
    git clone https://github.com/jeremymcgee73/PSGELF.git
}
Import-Module ./PSGELF/PSGELF/PSGelf.psm1

function Send-UdpDatagram
{
    ##  Courtesy of https://gist.github.com/PeteGoo/21a5ab7636786670e47c
    ##  Cheers Pete GOO!
      Param ([string] $EndPoint, 
      [int] $Port, 
      [string] $Message)

      $IP = [System.Net.Dns]::GetHostAddresses($EndPoint) 
      $Address = [System.Net.IPAddress]::Parse($IP) 
      $EndPoints = New-Object System.Net.IPEndPoint($Address, $Port) 
      $Socket = New-Object System.Net.Sockets.UDPClient 
      $EncodedText = [Text.Encoding]::ASCII.GetBytes($Message) 
      $SendMessage = $Socket.Send($EncodedText, $EncodedText.Length, $EndPoints) 
      Write-Debug $SendMessage

      $Socket.Close() 
} 

Function Send-RawTimeAdjustedLogs {
    param (
        $GLServer,
        $LogFile,
        $GLPort,
        $Subset
)
if($subset) { $ReadLogs = Get-Content $LogFile | select-object -First $Subset 
    } else {
    $ReadLogs = Get-Content $LogFile
}  
$RLCount = $ReadLogs.Count
$lastItem = $RLCount -1
$Count = 0

$logDate = ($ReadLogs[$lastItem] -split ' ')[0]
$logTime = ($ReadLogs[$lastItem] -split ' ')[1]
$logTimeStamp = Get-Date "$logDate $logTime"
$LogDelta = ((Get-Date) - $LogTimeStamp)

foreach ($entry in $ReadLogs) {
$entryArray = $entry -split ' '
$entryMessage = "$($entryArray[2..$entryArray.Length])"
$entryDate = Get-Date "$($entryArray[0]) $($entryArray[1])"
$newDate = Get-Date ($entryDate +  $LogDelta) -format 'yyyy-MM-dd hh:mm:ss'
$message = "$newdate $entryMessage"
#Write-Progress -Activity "Sending Log #${Count} of ${RLCount}" -Status "Committing to GL Server" -PercentComplete (($Count / $RLCount)*100)
$Count++
Send-UdpDatagram -EndPoint "$GLServer" -Port $GLPort -Message "$message"
}
}

Function Send-TimeAdjustedLogs {
    param (
        $GLServer,
        $LogFile,
        $TZOffset = 0,
        $GLPort,
        $Subset
)
if($subset) { $ReadLogs = Get-Content $LogFile | ConvertFrom-Json -AsHashTable | select-object -First $Subset 
    } else {
    $ReadLogs = Get-Content $LogFile | ConvertFrom-Json -AsHashtable
}  
$RLCount = $ReadLogs.Count
$lastItem = $RLCount -1
$Count = 0

$LogDelta = ((Get-Date) - (Get-date ($ReadLogs[$lastItem]).timestamp))
$LogPack = (Get-Childitem $LogFile).name
foreach ($entry in $ReadLogs) {
        if($entry.'@timestamp') {
                if($entry.'@timestamp'.count -gt 1) {
                $entry.'@timestamp' = Get-Date ($entry.'@timestamp'[0] + $LogDelta) -Format "yyyy-MM-ddTHH:mm:ss.ffffff"
                }else {
                $entry.'@timestamp' = Get-Date ($entry.'@timestamp' + $LogDelta) -Format "yyyy-MM-ddTHH:mm:ss.ffffff"
                }
       }
       

       ## Remove silly entries from Sophos Logs
       if($entry.date) { $entry.remove('date')}
       if($entry.time) { $entry.remove('time')}
       if($entry.'filebeat_@timestamp') { $entry.remove('filebeat_@timestamp')}
       
       #if($entry.time) { $entry.time.remove()}
        if($entry.timestamp -and ($entry.timestamp -is [array])) {
            $entry.timestamp = Get-Date ($entry.'timestamp'[0] + $LogDelta) -Format "yyyy-MM-ddTHH:mm:ss.ffffff"
        }

        if($entry.timestamp) {
            $entry.timestamp = Get-Date ((Get-date $entry.timestamp) + $LogDelta) -Format "yyyy-MM-ddTHH:mm:ss.ffffff"
        }

        if($entry.EventReceivedTime) {
            $entry.EventReceivedTime = Get-Date ((Get-Date $entry.'EventReceivedTime') + $LogDelta) -Format "yyyy-MM-dd HH:mm:ss"
        }

        if($entry.flow_start) {$entry.flow_start = get-date ((get-date $entry.flow_start) + $logDelta) -Format "yyyy-MM-ddTHH:mm:ss.ffffff"}
        if($entry.flow_end) {$entry.flow_end = get-date ((get-date $entry.flow_end) + $logDelta) -Format "yyyy-MM-ddTHH:mm:ss.ffffff"}
    
        $entry.'log_pack' = $LogPack

    Write-Progress -Activity "Sending Log #${Count} of ${RLCount}" -Status "Committing to GL Server" -PercentComplete (($Count / $RLCount)*100)
$Count++
 $entry | Send-PSGelfTCPFromObject -GelfServer $GLServer -port $GLPort
}
}

function Send-Logs { 
    param (
        [Parameter(Mandatory)]
            [ValidateSet(
            'Test','Demo','Search','Discovery',
            'Alerts','wf-sample','windowsfirewall-sample','windows-sample',
            'wf','windowsfirewall','windows',
            'mf-sample','macfirewall-sample','mac-sample',
            'mf','macfirewall','mac','pipeline-intro','dashboards', 
            'wfw-demo','wfw-processed'     
            )]
            [string]$logPack
    )

    switch($logPack){
        'Test' {Send-PSGelfTCP -GelfServer $env:GLServer -Port 12201 -FullMessage "It looks like she's all clear captain.  Let the lasers in!" -ShortMessage "Test Message";return}
        'Demo' {Send-PSGelfTCP -GelfServer $env:GLServer -Port 12201 -FullMessage "This is my little message from me to you.  Enjoy your day!" -ShortMessage "Demo Message";return}
        {$_ -in 'lab1','Search'} { $logfile = (Join-Path $env:GLRoot "Data\001-fw.json")}
        
        {$_ -in 'Discovery','Pipeline-intro'} { $logfile = (Join-Path $env:GLRoot "Data\001-fw.json");$subset = 200}
        'Dashboards' { $logfile = (Join-Path $env:GLRoot "Data\002-gl.json")}

        'Alerts' { $logfile = (Join-Path $env:GLRoot "Data\003-pa.json")}

        {$_ -in 'wf-sample','windowsfirewall-sample','windows-sample','wfw-demo'}  {
            $raw = $true;
            $logfile = (Join-Path $env:GLRoot "Data\004-wf.log"); 
            $subset = 20
        }
        {$_ -in 'wf','windowsfirewall','windows','wfw-processed'}   {
            $raw = $true;
            $logfile = (Join-Path $env:GLRoot "Data\004-wf.log")
        }

        {$_ -in 'mf-sample','macfirewall-sample','mac-sample'} {
            $logfile = (Join-Path $env:GLRoot "Data\004-mf.log")
            Get-content $logfile| Select-Object -first 20 | ForEach-Object {
                 Send-UdpDatagram -endpoint $env:GLServer -port 1501 -message $_
            }
            return
        }

        {$_ -in 'mf','macfirewall','mac'} {
            $logfile = (Join-Path $env:GLRoot "Data\004-mf.log")
            Get-content $logfile| ForEach-Object {
                 Send-UdpDatagram -endpoint $env:GLServer -port 1501 -message $_
            }
            return
        }
        ## Enter Lab4 as UDP Function for Firewall LOG!
        ## Need a RAW UDP input
        
        default { Write-output "Unknown Log Pack, exiting..."; return 0}
    }

    $logParms = @{
        GLServer = $env:GLServer
        GLPort = 12201
        LogFile = $logfile
    }

    if($subset){
        $logParms.Add('Subset',$subset)
    }

    if($raw)
    {
    $logParms.GLPort = 1500
    Send-RawTimeAdjustedLogs @logParms
    }else{
    Send-TimeAdjustedLogs @logParms
    }
}


