Param(
    [string]$RepoUrl,
	[string]$Username,
	[string]$Password,
	[string]$Scheme = "https",
	[string]$Location,
	[string]$DeltaFile,
	[string]$TagName = "ProductionRelease"
)

if(!(Test-Path $Location))
{
	New-Item -ItemType Directory -Force -Path $Location
}
$ReleaseHash = Get-Content $DeltaFile -First 1
$cloneCommand = "$($Scheme)://$($Username):$($Password)@$($RepoUrl) '$($Location)'"
Invoke-Expression "git clone -q $($cloneCommand)"
Set-Location $($Location)
Invoke-Expression "git checkout -q $($ReleaseHash)"
Invoke-Expression "git tag -d $($TagName)"
Invoke-Expression "git tag -a $($TagName) -m 'Production Release'"
Invoke-Expression "git push -q -f origin $($TagName)"
Set-Location ..
Remove-Item -Recurse -Force $($Location)
Clear-History