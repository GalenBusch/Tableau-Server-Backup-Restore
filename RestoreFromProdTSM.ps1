$SuperSecretPassword = get-content -path C:\Users\svc_tableau\Desktop\svc_tableau.password.txt
$date = Get-Date
$CrLf = "`r`n"
$backups_folder  = "D:\ProdTsbak\"
$backups_file          = "Prod_Backup_"+$date.Year+$date.Month+$date.Day+".tsbak"
$zipfile               = "logs_"+ $date.Year+$date.Month+$date.Day+".zip"
$ShellVerbose  		   = $True
$MachineName           = "Tableau-V1"
$LogLocation           = "D:\Email\EmailDev.txt"
$LogDestination        = "\\tableau-p1\Prod\Email"

#Check for backup file before stopping server
if (test-path -path $backups_folder$backups_file) 
{
	#Stop Tableau Server
	$d1 = get-date
	if ($shellverbose -eq $True) {Write-Host "****** Stopping Tableau Server: $d1 *****"}
	tsm stop --username SCCA\svc_tableau --password $supersecretpassword
	$d2 = get-date
	$ts = New-TimeSpan -Start $d1 -End $d2
	$ts01 = $ts.seconds
	$pslog = "$d1 Tableau-v1 TSM Stop Duration: $ts01 Seconds" +$CrLf
	
	#Restore from backup
	$d3 = get-date
	if ($shellverbose -eq $True) {Write-Host "****** Restoring from backup: $d3 *****"}
	tsm maintenance restore --file $backups_file --username SCCA\svc_tableau --password $supersecretpassword --skip-identity-store-verification -r
	$d4 = get-date
	$ts1 = New-TimeSpan -Start $d3 -End $d4
	$ts11 = $ts1.seconds
	$pslog += $crlf + "$d3 Tableau-v1 TSM Restore Duration: $ts11 Minutes" + $CrLf
	
	if ($shellverbose -eq $True) {Write-Host "****** Restarted Tableau Server on Tableau-v1: $ts11 Minutes *****"}
	
	$d5 = get-date
	D:\TableauExtractsOff.bat
	$d6 = get-date
	$ts2 = New-TimeSpan -Start $d5 -End $d6
	$ts21 = $ts2.Seconds
	$pslog += $crlf + "$d5 Tableau-v1 Extracts Off Duration: $ts21 Seconds" + $CrLf
} 

else 

{$faildate = get-date;

$pslog = "$faildate $MachineName No Backup Found" +$CrLf}

$TabStatus = tsm status --username SCCA\svc_tableau --password $supersecretpassword
$d7 = get-date
$pslog += $crlf + "$d7 $MachineName Server $TabStatus" + $CrLf

$pslog | Out-File -filepath D:\Email\EmailDev.txt

if ($shellverbose -eq $True) {while (!(Test-Path -path D:\Email\EmailDev.txt))  
{write-host "Waiting for Email to generate..."
Start-Sleep 2}}

copy-item -path $LogLocation -destination -path $LogDestination

main