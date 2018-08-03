Param(
    [Parameter(Position=0)]
    [string]$DeletePath = "C:\inetpub\wwwroot\ABC\Website\temp\__Upgrade\*"
)

try{
	$upgradePath = Get-Item -path $DeletePath -ErrorAction Stop
	Remove-Item $DeletePath -recurse
}
catch{
	":: Directory not found: $DeletePath"
}