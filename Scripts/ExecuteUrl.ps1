Param(
    [string]$SiteUrl,
	[string]$Username,
    [string]$Password,
	[int]$Timeout = 900, # 15 minutes
	[int]$ExpectedResult = 200,
	[bool]$ValidateResult = $false
)

$currentPath = (Resolve-Path .\).Path
Write-Host "Current directory: $($currentPath)"
$executable = "$($currentPath)\curl.exe"
Write-Host "Exe location: $($executable)"

$curlCommand
if($Username -and $Password){
	$curlCommand = "'$($executable)' -s -o /dev/null -I -w '%{http_code}' -u $($Username):$($Password) $($SiteUrl) --max-time $Timeout"
}
else{
	$curlCommand = "'$($executable)' -s -o /dev/null -I -w '%{http_code}' $($SiteUrl) --max-time $Timeout"
}

$result = Invoke-Expression "& $curlCommand" 

Write-Host "Result is: $($result)"

if($ValidateResult){
	if($result -ne $ExpectedResult)
	{
		throw "Web page did not return a valid $($ExpectedResult) response"
	}
}

Write-Host "Exiting"

exit