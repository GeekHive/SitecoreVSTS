Param(
    [Parameter(Mandatory=$true)][string]$userId,
	[Parameter(Mandatory=$true)][string]$password ,
	[Parameter(Mandatory=$true)][string]$subscriptionId,
	[Parameter(Mandatory=$true)][string]$resourceGroupName,
	[Parameter(Mandatory=$true)][string]$appServiceName,
	[Parameter(Mandatory=$true)][int]$maxRestartAttempts
)

function Iterate-Processes{
	foreach ($instance in $webSiteInstances)
	{
		$instanceId = $instance.Name
		
		Write-Host "Getting all processes from $instanceId ...`n" -foregroundcolor "Yellow"
		
		$processList =  Get-AzureRmResource `
						-ResourceId /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Web/sites/$appServiceName/instances/$instanceId/processes
	 
		foreach ($process in $processList)
		{      
			$processIds = $process.Properties.Id
			Write-Host "Process ids found: $processIds`n" -foregroundcolor "Green"
			
			if ($process.Properties.Name -eq "w3wp")
			{   
				foreach ($processId in $process.Properties.Id)
				{
					Write-Host "w3wp Process id: $processId`n" -foregroundcolor "Green"
					
					Write-Host "Getting process properties ...`n" -foregroundcolor "Yellow"
					
					$resourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Web/sites/$appServiceName/instances/$instanceId/processes/" + $processId          
					$processInfoJson = Get-AzureRmResource -ResourceId  $resourceId                                    
		 
					if ($processInfoJson.Properties.is_scm_site -ne $true)
					{
						Write-Host "Stopping process with PID: $processId ...`n" -foregroundcolor "Yellow"
						
						$result = Remove-AzureRmResource -ResourceId $resourceId -Force 
		 
						if ($result -eq $true)
						{ 
							Write-Host "Process $processId stopped`n" -foregroundcolor "Green"
							return $true
						}
						else{
							Write-Host "Error stopping process $processId`n" -foregroundcolor "Red"
						}
					}   
					else{
						Write-Host "Skipping KUDU process with PID: $processId ...`n" -foregroundcolor "Green"
					}
				}
		   }
		}
	}
	
	return $false
}

function Attempt-Restart{
	if(Iterate-Processes){
		Write-Host "Invoking Web Request to $defaultHostName ...`n" -foregroundcolor "Yellow"
		
		try{
			$statusCode = (invoke-webrequest  -method head -uri $defaultHostName).statuscode
		}
		catch{
			Write-Host "Error during invoke-webrequest method. Likely a status code other than 200 was returned`n" -foregroundcolor "Red"
			
			Write-Host "Invoking Web Request, attempt #2 for iteration, to $defaultHostName ...`n" -foregroundcolor "Yellow"
			try{
				$statusCode = (invoke-webrequest  -method head -uri $defaultHostName).statuscode
			}
			catch{
				Write-Host "Error during invoke-webrequest method. Likely a status code other than 200 was returned`n" -foregroundcolor "Red"
			}
		}
		
		if($statusCode -eq 200){
			Write-Host "Response Status Code: $statusCode`n" -foregroundcolor "Green"
			exit
		}
		else{
			Write-Host "Response Status Code: $statusCode`n" -foregroundcolor "Red"
		}
	}
	else{
		Write-Host "No matched w3wp process found to stop`n" -foregroundcolor "Red"
	}
}

$securePassword = ConvertTo-SecureString $password -asplaintext -force

$cred = New-Object -TypeName System.Management.Automation.PSCredential($userId ,$securePassword)

Write-Host "User ID: $($userId)" -foregroundcolor "Green"
Write-Host "Logging into Azure ..." -foregroundcolor "Yellow"

Login-AzureRmAccount -Credential $cred -subscriptionId $subscriptionId

Write-Host "Successfully logged into Azure`n" -foregroundcolor "Green"

Write-Host "Subscription ID: $($subscriptionId)" -foregroundcolor "Green"

Write-Host "Selecting Subscription..." -foregroundcolor "Yellow"

Select-AzureRmSubscription -subscriptionId $subscriptionId

Write-Host "Successfully selected Subscription`n" -foregroundcolor "Green"

Write-Host "Subscription ID: $($subscriptionId)" -foregroundcolor "Green"
Write-Host "Resource Group Name: $($resourceGroupName)" -foregroundcolor "Green"
Write-Host "App Service Name: $($appServiceName)`n" -foregroundcolor "Green"

$webSiteInstances = @()
 
$webSiteInstances = Get-AzureRmResource -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Web/sites/instances -ResourceName $appServiceName
 
$site = Get-AzureRmResource -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Web/sites -ResourceName $appServiceName -ApiVersion 2018-02-01 
 
$scheme = "http://"

If ($site.properties.httpsOnly -eq "true") { 
	$scheme = "https://"
} 
 
$defaultHostName = $scheme + $site.properties.defaultHostName + "/"

Write-Host "Default Host Name: $defaultHostName`n" -foregroundcolor "Green"

$statusCode = 0
 
Write-Host "Starting restart attempts. Max Attempts: $maxRestartAttempts`n" -backgroundcolor "Black"

For ($i=1; $i -le $maxRestartAttempts; $i++) {
	Write-Host "Restart attempt: $i ...`n" -foregroundcolor "Yellow"
    Attempt-Restart
}

throw "Error restarting site in $maxRestartAttempts tries"
