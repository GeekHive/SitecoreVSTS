# --- Set the uri for the latest release
$URI = "https://api.github.com/repos/GeekHive/SitecoreVSTS/zipball"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$OutputPath = "$((Get-Location).Path)\scripts.zip"

# --- Query the API to get the url of the zip
Invoke-WebRequest -Uri $URI -OutFile $OutputPath

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Unzip $OutputPath "$((Get-Location).Path)"

$directory = Get-ChildItem -Directory | Select-Object -First 1

$sourceDirectory = "$((Get-Location).Path)\$directory"

"$($sourceDirectory)"

$destinationDirectory = "$((Get-Location).Path)"

"$($destinationDirectory)"

Rename-Item -Path $sourceDirectory -NewName "SitecoreVSTS"