Param(
    [string]$pathToPackages
)

[Reflection.Assembly]::LoadWithPartialName('System.IO.Compression')
[Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')

Write-Host "Removing all bin files from folder"

Get-ChildItem -Path $pathToPackages -Recurse -Filter "*.update" | ForEach-Object {
	$zipfile = $_.FullName
	Write-Host "Removing bin from $zipFile"
	$stream = New-Object IO.FileStream($zipfile, [IO.FileMode]::Open)
	$mode   = [IO.Compression.ZipArchiveMode]::Update
	$zip    = New-Object IO.Compression.ZipArchive($stream, $mode)

	#Let's put the zip directly in the same folder. Because.
	$packageZipLocation = Join-Path (Get-Item -Path ".\" -Verbose).FullName -ChildPath "\package.zip"

	#If it exists, we wanna get rid of it first
	If(Test-Path $packageZipLocation)
	{
		Remove-Item $packageZipLocation
	}

	#From the .update, we extract package.zip
	$zip.Entries | Where-Object {$_.Name -eq "package.zip"} | ForEach-Object {[IO.Compression.ZipFileExtensions]::ExtractToFile($_, $packageZipLocation)}

	#We'll need to remove the entry from the update, so we can rewrite it later
	$packageEntry = $zip.GetEntry("package.zip")
	$packageEntry.Delete()

	#Open up package.zip
	$packageStream = New-Object IO.FileStream($packageZipLocation, [IO.FileMode]::Open)
	$packageZip    = New-Object IO.Compression.ZipArchive($packageStream, $mode)

	#Remove anything in the bin folder (aka the automagically added HedgehogDevelopment.SitecoreProject.PackageInstallPostProcessor.dll)
	($packageZip.Entries |  Where-Object { "$_.FullName" -like "addedfiles/bin*" }) | ForEach-Object { $_.Delete() }
	#Remove Properties too
	($packageZip.Entries |  Where-Object { "$_.FullName" -like "properties/addedfiles/bin*" }) | ForEach-Object { $_.Delete() }
	
	$packageZip.Dispose()

	$packageStream.Close()
	$packageStream.Dispose()

	#Time to re-add the package.zip
	[IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $packageZipLocation, "package.zip")

	#Cleanup. We're done.
	Remove-Item $packageZipLocation

	#Errrrybody. Errrrrywhere
	$zip.Dispose()
	$stream.Close()
	$stream.Dispose()
}