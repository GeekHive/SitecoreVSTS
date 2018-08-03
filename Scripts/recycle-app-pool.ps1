<#
    This function "smart" recycles the app pool. It waits until a new worker process has been created
	and the original process has been completely killed before proceeding. It also explicitly disables
	overlapping of application pool processes during a recycle (and then re-enables overlapping to
	prevent production issues after deployment).
    Example usage: 
    .\recycle-app-pool.ps1 myAppPoolName 10 30000
	.\recycle-app-pool.ps1 -AppPool myAppPoolName -Count 10 -Delay 30000
#>

Param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$AppPool,
	[Parameter(Position=1, Mandatory=$false)]
    [int]$Count = 5,
	[Parameter(Position=2, Mandatory=$false)]
    [int]$Delay = 60000
)

function Find-WorkerProcessId {

	Param ([String[]]$oldWorkerProcessIds,[String[]]$newWorkerProcessIds)

	$foundAp = $false
	foreach($ap in $oldWorkerProcessIds) {	
		if($newWorkerProcessIds -contains $ap) {
			$foundAp = $true
		}
	}
	return $foundAp
}

function ChangeOverlappingSetting {

	Param ([String[]]$value)
	if($value -eq "true") {
		Write-Host "Disabling Overlapping AppPool Recycle..."
	} else {
		Write-Host "Enabling Overlapping AppPool Recycle..."
		$value = "false"
	}
	
	$currentOverlapSetting = C:\windows\system32\inetsrv\appcmd list apppool $AppPool /text:recycling.disallowOverlappingRotation
	Write-Host "Current Setting: recycling.disallowOverlappingRotation="$currentOverlapSetting
	C:\windows\system32\inetsrv\appcmd set apppool $AppPool /recycling.disallowOverlappingRotation:$value
	$currentOverlapSetting = C:\windows\system32\inetsrv\appcmd list apppool $AppPool /text:recycling.disallowOverlappingRotation
	Write-Host "Current Setting: recycling.disallowOverlappingRotation="$currentOverlapSetting
	"---"
}

"[Script Parameters]"
"AppPool:" + $AppPool
"Count:" + $Count
"Delay:" + $Delay
"---"

Write-Host "Original w3wp Process IDs:"
$oldWorkerProcessIds = C:\windows\system32\inetsrv\appcmd list wp | where { $_.Contains("(applicationPool:" + $AppPool + ")") }
$oldWorkerProcessIds
"---"

ChangeOverlappingSetting "true"

Write-Host "Original w3wp Process IDs:"
$oldWorkerProcessIds = C:\windows\system32\inetsrv\appcmd list wp | where { $_.Contains("(applicationPool:" + $AppPool + ")") }
$oldWorkerProcessIds
"---"


Write-Host "Restarting AppPool..."
Restart-WebAppPool $AppPool
"---"

#$iterations = 1000,1000,1000
$iterations = ,$Delay * $Count

$iterations | % {
	Write-Host "Sleeping "$_" milliseconds..."
	Start-Sleep -Milliseconds $_

	$newWorkerProcessIds = C:\windows\system32\inetsrv\appcmd list wp | where { $_.Contains("(applicationPool:" + $AppPool + ")") }
	Write-Host "Current w3wp Process IDs:"
	$newWorkerProcessIds
	"---"


	$foundAp = Find-WorkerProcessId $oldWorkerProcessIds $newWorkerProcessIds
	if(!$foundAp) {
		Write-Output "Successfully Recycled Pool"
		"---"
		ChangeOverlappingSetting "false"
		exit
	}
}

Write-Host "Original AppPool did not completely shut down!"
"---"
ChangeOverlappingSetting "false"
exit 1
