Param(
    [string]$SiteUrl,
	[string]$Username,
    [string]$Password,
    [int]$RepeatInterval,
	[int]$Timeout = 900, # 15 minutes
	[int]$ConnectionTimeout = 900 # 15 minutes
)

$currentPath = (Resolve-Path .\).Path
Write-Host "Current directory: $($currentPath)"
$executable = "$($currentPath)\curl.exe"
Write-Host "Exe location: $($executable)"
get-date
$curlCommand
if($Username -and $Password){
	$curlCommand = "'$($executable)' -sS -u $($Username):$($Password) $($SiteUrl) --connect-timeout $ConnectionTimeout --max-time $Timeout"
}
else{
	$curlCommand = "'$($executable)' -sS $($SiteUrl) --connect-timeout $ConnectionTimeout --max-time $Timeout"
}

if($RepeatInterval -gt 0)
{
	$hitExecutionStage = $FALSE;
	:forEveryInterval for(;;) {
	 try {
		$messages = (Invoke-Expression "& $curlCommand") | ConvertFrom-Json
		write-host $messages.Status -ForegroundColor Green
		if($messages.Messages.Length -gt 0)
		{
			write-host $messages.Messages[$messages.Messages.Length - 1] -ForegroundColor DarkGray
			
			if($messages.Status.Equals("Ready") -and $messages.Messages.Length -gt 0)
            {
                $hitExecutionStage = $TRUE;
            }
			if($hitExecutionStage -and $messages.Status.Contains("Ready"))
			{
				Write-Host "break"
				break forEveryInterval;
			}
		}
	 }
	 catch {
	  write-host $_
	 }

	 Start-Sleep $RepeatInterval
	}
}
else{
	Invoke-Expression "& $curlCommand"
}

get-date