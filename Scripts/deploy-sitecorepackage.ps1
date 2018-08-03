<#
    This function uploads & installs the specified Sitecore update package to the given $SiteUrl.
    Example usage:
    .\deploy-sitecorepackage.ps1 mysite.dev "C:\Project\Build\Artifacts\1-mysite-templates.update" 300 MyUsername MyPassword
	.\deploy-sitecorepackage.ps1 mysite.dev "C:\Project\Build\Artifacts\1-mysite-templates.update" 300 -ResultsOutputPath "c:\temp\ids.txt"
#>
Param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$SiteUrl,
    [Parameter(Position=1, Mandatory=$true)]
    [string]$UpdatePackagePath,
    [Parameter(Position=2)]
    [ValidateRange(0, 99999)]
    [int]$ConnectionTimeOutInSeconds = 300,
	[Parameter(Position=3)]
    [string]$Username,
	[Parameter(Position=4)]
    [string]$Password,
	[Parameter(Position=5)]
    [string]$ResultsOutputPath
)

Write-Host "Creating new WebClientEx type"
Add-Type @"
using System;
using System.Net;

 public class WebClientWithTimeout : WebClient
 {
     public int TimeoutSeconds {get; set;}

     protected override WebRequest GetWebRequest(Uri address)
     {
        var request = base.GetWebRequest(address);
        request.Timeout = TimeoutSeconds * 1000;
        return request;
     }
 }
"@

Write-Host "SiteUrl:" $SiteUrl
Write-Host "UpdatePackagePath:" $UpdatePackagePath " - Exists:" (Test-Path $UpdatePackagePath)  " - IsDir:" ((Get-Item $UpdatePackagePath) -is [System.IO.DirectoryInfo])
Write-Host "ConnectionTimeOutInSeconds:" $ConnectionTimeOutInSeconds
Write-Host "Username:" $Username
Write-Host "Password:" $Password
Write-Host "ResultsOutputPath:" $ResultsOutputPath

$fileUploadUrl = "$SiteUrl/services/package/install/fileupload"
$shipHtml = ""
$item = Get-Item $UpdatePackagePath 
$webclient = New-Object WebClientWithTimeout
$webclient.TimeoutSeconds = $ConnectionTimeOutInSeconds

if($Username){
	$webclient.Credentials = New-Object System.Net.NetworkCredential($Username,$Password)  
}

$uri = New-Object System.Uri($fileUploadUrl) 
$rawResponse = $webclient.UploadFile($uri, $item.FullName)	
$shipHtml = [System.Text.Encoding]::ASCII.GetString($rawResponse)

if($shipHtml -eq $null)
{
	Write-Host "Empty response from ship..."
}

if($shipHtml -ne $null)
{
	$shipResponse = $shipHtml | ConvertFrom-Json
	$shipEntries = $shipResponse.Entries
	$items = New-Object System.Collections.Generic.List[string]
	$shipEntries | 
		ForEach-Object {
			if($_.ID -ne $null)
			{
				Write-Host $_.ID -foregroundcolor cyan
				$items.Add($_.ID )
			}
		}
		
	if((-not [string]::IsNullOrEmpty($ResultsOutputPath)))
	{
		Write-Host "Saving Results to:" $ResultsOutputPath
		$items  | out-file $ResultsOutputPath
	}
}
