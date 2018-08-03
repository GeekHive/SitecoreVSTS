Param(
    [string]$pathToPackages
)

$currentPath = (Resolve-Path .\).Path
Write-Host "Current directory: $($currentPath)"
$executable = "$($currentPath)\ExtractDllsFromPackage.exe"
Write-Host "Exe location: $($executable)"

set-alias extracter $executable

function RemoveBinFiles
{
	param([string]$path, [string]$updateFile)

	$packageNameOnly = "$($path)\$($updateFile)"
	$package = "$($packageNameOnly).update"
	
	extracter $package $path
}

Get-ChildItem $pathToPackages -Filter *.update | 
	Foreach-Object {
		$packageName = $_.BaseName
		Write-Host $packageName
		RemoveBinFiles $pathToPackages $packageName
	}

