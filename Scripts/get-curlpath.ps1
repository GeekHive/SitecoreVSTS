<# 
    This script returns the full path of the curl.exe.
#>

$curlExe = 'curl.exe'
$curlPath = Resolve-Path "$PSScriptRoot\curl\$curlExe" # This is the path on the local dev machine.
if (-not (Test-Path $curlPath))
{
    # Fall-back to use curl.exe located in the same location as the script.
    if (Test-Path "$PSScriptRoot\$curlExe")
    {
        $curlPath = "$PSScriptRoot\$curlExe"
    }
    else
    {
        Write-Error "ERROR: $curlPath not found."
        Exit
    }
}

$curlPath