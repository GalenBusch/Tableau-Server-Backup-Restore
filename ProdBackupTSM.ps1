#Toggles
$CopyFilesToRemote 			= $True
$DaysToKeep 				= 0
$DaysToKeepProd 			= 0
$PurgeOldFiles 				= $True
$ShellVerbose  				= $True
$EmailOnlyOnFailure         = $False
#SMTP Setup
$smtp_server 				= "mx.yourserver.com"
$smtp_port 					= 25
$mailfrom 					= "<TableauAdmin@yourcompany.org>"  
$DistList 					= get-content "D:\Distribution List for Tableau Processes.txt" #either hardcode email addresses, or reference them from a file.
$EmailVal					= "D:\Email\EmailVal.txt"
$EmailDev 					= "D:\Email\EmailDev.txt"
#Globals
$SuperSecretPassword 		= get-content -path C:\Users\svc_tableau\Desktop\svc_tableau.password.txt
$secpasswd 					= ConvertTo-SecureString -String $SuperSecretPassword -AsPlainText -Force
$credential 				= new-object System.Management.Automation.PSCredential -ArgumentList ("svc_tableau",$secpasswd)
$date 						= Get-Date
$CrLf 						= "`r`n"
$backups_folder 			= "D:\ProdTsbakTemp\"
$Logs_backups_folder		= "D:\ProdTsbakTemp\"
$remote_Backups_FolderDev 	= "\\tableau-d1\D$\ProdTsbak\"
$remote_Backups_FolderVal 	= "\\tableau-v1\D$\ProdTsbak\"
$backups_file         		= "Prod_Backup_"+ $date.Year+$date.Month+$date.Day+".tsbak"
$zipfile            	    = "logs_"+ $date.Year+$date.Month+$date.Day+".zip"
$Production_Machine_name    = "Tableau-P1"
$Val_Machine_name 			= "Tableau-V1"
$Dev_Machine_name			= "Tableau-D1"

#Wipe previous day's log files for email notification
Remove-Item D:\Email\*.txt*

#Run Zip Logs
if ($ShellVerbose -eq $True) {write-host "Zipping logs..."}
$d1 = get-date
TSM Maintenance ziplogs -a -o "$zipfile"
while (!(Test-Path $Logs_backups_folder$zipfile)) { Start-Sleep 3 }
$d2 = get-date
$ts = New-TimeSpan -Start $d1 -End $d2
$ts01 = $ts.seconds
$pslog = "$d1 Tableau-p1 Log Zip Duration: $ts01 Seconds" +$CrLf
write-host "Zipped Logs: $ts01 Seconds"

# Run Backup
if ($ShellVerbose -eq $True) {write-host "Creating .tsbak..."}
$d3 = get-date
TSM Maintenance backup -f "$Backups_file"
while (!(Test-Path $backups_folder$backups_file)) { Start-Sleep 30 }
$d4 = get-date
$ts1 = New-TimeSpan -Start $d3 -End $d4
$ts11 = $ts1.minutes
$pslog += $crlf + "$d3 $Production_Machine_name Backup Duration: $ts11 Minutes" + $CrLf
if ($ShellVerbose -eq $True) {write-host ".tsbak Created: $ts11 Minutes"}

# Transfer Backups to Val and Dev
if ($ShellVerbose -eq $True) {write-host "Transferring .tsbak to $Dev_Machine_name...."}
$d5 = get-date
copy-Item -path $backups_folder$backups_file -Destination $remote_Backups_FolderDev$backups_file -force
$d6 = get-date
$ts2 = New-TimeSpan -Start $d5 -End $d6
$ts21 = $ts2.minutes
$pslog += $crlf + "$d5 $Production_Machine_name Transfer Backup to $Dev_Machine_name Duration: $ts21 Minutes" + $CrLf
if ($ShellVerbose -eq $True) {write-host ".tsbak transferred to $Dev_Machine_name: $ts21 Minutes"}

if ($ShellVerbose -eq $True) {write-host "Transferring .tsbak to $Val_Machine_name...."}
$d7 = get-date
copy-Item -path $backups_folder$backups_file -Destination $remote_Backups_FolderVal$backups_file -force
$d8 = get-date
$ts3 = New-TimeSpan -Start $d7 -End $d8
$ts31 = $ts3.minutes
$pslog += $crlf + "$d7 $Production_Machine_name Transfer Backup to $Val_Machine_name Duration: $ts31 Minutes" + $CrLf
if ($ShellVerbose -eq $True) {write-host ".tsbak transferred to $Val_Machine_name: $ts31 Minutes"}

# Transfer Logs to Val and Dev
if ($ShellVerbose -eq $True) {write-host "Transferring Logs to $Dev_Machine_name..."}
$d9 = get-date
copy-Item -path $Logs_backups_folder$zipfile -Destination $remote_Backups_FolderDev$zipfile
$d10 = get-date
$ts4 = New-TimeSpan -Start $d9 -End $d10
$ts41 = $ts4.seconds
$pslog += $crlf + "$d9 $Production_Machine_name Transfer Logs to $Dev_Machine_name Duration: $ts41 Seconds" + $CrLf
if ($ShellVerbose -eq $True) {write-host "Transferred Logs to $Dev_Machine_name: $ts41 Seconds"}

if ($ShellVerbose -eq $True) {write-host "Transferring Logs to $Val_Machine_name..."}
$d11 = get-date
copy-Item -path $Logs_backups_folder$zipfile -Destination $remote_Backups_FolderVal$zipfile
$d12 = get-date
$ts5 = New-TimeSpan -Start $d11 -End $d12
$ts51 = $ts5.seconds
$pslog += $crlf + "$d11 $Production_Machine_name Transfer Logs to $Val_Machine_name Duration: $ts51 Seconds" + $CrLf
if ($ShellVerbose -eq $True) {Write-Host "Transferred Logs to $Val_Machine_name: $ts51 Seconds"}

#

# Delete old backup and zip log Files
If ($PurgeOldFiles -eq $True)
 {$d13 = get-date;
  if ($ShellVerbose -eq $True) {Write-Host "Purging Old Files..."};
  # Delete local copies of backups and zip logs
  $oldfiles = Get-ChildItem $backups_folder -file | Where-object {$_.LastWriteTime -lt $date.AddDays(-$DaysToKeepProd)}
  if($oldfiles.count -gt 0)
   {
    $oldfiles.Delete()
   }

# Delete Remote copies of Old files Dev
  if ($CopyFilesToRemote -eq $True)
   {
    $oldfiles = Get-ChildItem $remote_Backups_FolderDev -file | Where-object {$_.LastWriteTime -lt $date.AddDays(-$DaysToKeep)}
    if($oldfiles.count -gt 0)
     {
      $oldfiles.Delete()
     }
   }

# Delete Remote copies of Old files Val
  if ($CopyFilesToRemote -eq $True)
   {
    $oldfiles = Get-ChildItem $remote_Backups_FolderVal -file | Where-object {$_.LastWriteTime -lt $date.AddDays(-$DaysToKeep)}
    if($oldfiles.count -gt 0)
     {
      $oldfiles.Delete()
     }
   }
  }
$d14 = get-date
$ts6 = New-TimeSpan -Start $d13 -End $d14
$ts61 = $ts6.seconds
$pslog += $crlf + "$d13 $Production_Machine_name File Cleanup Duration: $ts61 Seconds" + $CrLf
if ($ShellVerbose -eq $True) {Write-Host "Old Files Purged: $ts61 Seconds"}


# Check main Tableau Process as a proxy for running/stopped (this script issues no commands that would stop Tableau server; the restore will occur whether Tableau server is running or stopped)
if ($ShellVerbose -eq $True) {Write-Host "Checking for main Tableau Service State..."}
$d15 = get-date
$TableauProcessCheck = Get-Process vizqlserver -ErrorAction SilentlyContinue
$TableauStatus = if ($TableauProcessCheck) {"Status: RUNNING"} else {"Status: STOPPED"}
$pslog += $crlf + "$d15 $Production_Machine_name Server $TableauStatus"  + $CrLf

$pslog | Out-File -filepath D:\Email\EmailProd.txt
 

#Execute remote restore scripts
Invoke-Command -ComputerName "$Val_Machine_name" -Credential $Credential -filepath {\\tableau-v1\D$\Restorefromprod.ps1}
Invoke-Command -ComputerName "$Dev_Machine_name" -Credential $Credential -filepath {\\tableau-d1\D$\Restorefromprod.ps1}

while (!(Test-Path "$EmailVal")) {start-sleep 60}
while (!(Test-Path "$EmailDev" {start-sleep 60}
 
#Email Results to Distribution List
start-sleep 15
$EmailErrors = ""
$ProdErrorStatus = get-content D:\Email\EmailProd.txt | findstr /i "Running"
$ProdStatus = if ($ProdErrorStatus.length -eq 0) {$EmailErrors += "$Production_Machine_name "}
$ValErrorStatus = get-content D:\Email\EmailVal.txt | findstr /i "Running"
$ValStatus = if ($ValErrorStatus.length -eq 0) {$EmailErrors += "$Production_Machine_name "}
$DevErrorStatus = get-content D:\Email\EmailDev.txt | findstr /i "Running"
$DevStatus = if ($DevErrorStatus.length -eq 0) {$EmailErrors += "$Production_Machine_name "}

$EmailDev = (Get-Content D:\Email\EmailDev.txt) -join "`n"
$EmailVal = (Get-Content D:\Email\EmailVal.txt) -join "`n"
$EmailProd = (Get-Content D:\Email\EmailProd.txt) -join "`n"

if ($emailerrors.length -eq 0) {write-host "Process Complete"} else {
{$mailsubject = "TABLEAU ALERT: SERVER(S) DOWN: $EmailErrors"} else {$mailsubject = "Tableau Server Backup Detail"}
[string] $mailBody = "******** Tableau-p1 Backup Logs ********" + "`n" + "`n" + "$EmailProd" + "`n" + "******** Tableau-v1 Restore Logs ********" + "`n" + "`n" + "$EmailVal" + "`n" + "******** Tableau-d1 Restore Logs ********" + "`n" + "`n" + "$EmailDev"

Send-MailMessage -to $distlist -From $mailfrom -SmtpServer $smtpserver -Subject $mailSubject -Body $mailBody
if ($ShellVerbose -eq $True) {write-host "Process Complete"}}

main
















