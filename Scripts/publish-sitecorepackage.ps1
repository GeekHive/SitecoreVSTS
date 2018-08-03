<#
    This function "smart" publishes the specified Sitecore target to the given $SiteUrl.
    Example usage: 
    .\publish-sitecorepackage.ps1 mysite.dev "preview,web" "en" "smart" 300
	.\publish-sitecorepackage.ps1 mysite.dev "preview,web" "en" "listofitems" 300 MyUserName MyPassword "C:/temp/ids.txt"
#>

Param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$SiteUrl,
    [Parameter(Position=1, Mandatory=$true)]
    [string]$PublishTargets = "preview,web",
	[Parameter(Position=2, Mandatory=$true)]
    [string]$PublishLanguaes = "en",
	[Parameter(Position=3, Mandatory=$false)]
    [string]$PublishMode = "smart",
    [Parameter(Position=4)]
    [ValidateRange(0, 99999)]
    [int]$ConnectionTimeOutInSeconds = 300,
	[Parameter(Position=5)]
    [string]$Username,
	[Parameter(Position=6)]
    [string]$Password,
	[Parameter(Position=7)]
    [string]$ListOfIDsInputPath

)
."$PSScriptRoot\multipartFormDataUpload.ps1"
$publishUrl = "$SiteUrl/services/publish/$PublishMode"

$targetDatabases = $PublishTargets -split ","
$targetLanguages = $PublishLanguaes -split ","
$pubishItems = @{
		targets = $targetDatabases
		languages = $targetLanguages
	}

if($PublishMode -eq "listofitems")
{
	if (-not (Test-Path $ListOfIDsInputPath)) 
	{
		throw [System.IO.FileNotFoundException] "listofitems publish: $ListOfIDsInputPath not found."
	}
    [Collections.Generic.List[String]]$items = [IO.File]::ReadAllLines($ListOfIDsInputPath) 
	Write-Host $items -foregroundcolor cyan
	$pubishItems = @{
			TargetDatabases = $targetDatabases
			TargetLanguages = $targetLanguages
			Items = $items
		}
}
	
if($Username){
	$secpasswd = ConvertTo-SecureString $Password -AsPlainText -Force
	$mycreds = New-Object System.Management.Automation.PSCredential ($Username, $secpasswd)
	Write-Host "POST Publish $PublishMode with credentials" -foregroundcolor green
	Invoke-RestMethod -Uri $publishUrl -Method POST -ContentType "application/json" -Body ($pubishItems | ConvertTo-Json) -cred $mycreds
}
else{
	Write-Host "POST Publish $PublishMode" -foregroundcolor green
	Invoke-RestMethod -Uri $publishUrl -Method POST -ContentType "application/json" -Body ($pubishItems | ConvertTo-Json)
}