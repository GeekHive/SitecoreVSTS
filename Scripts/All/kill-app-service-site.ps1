Param(
    [Parameter(Mandatory=$true)][string]$userId,
	[Parameter(Mandatory=$true)][string]$password ,
	[Parameter(Mandatory=$true)][string]$subscriptionId,
	[Parameter(Mandatory=$true)][string]$resourceGroupName,
	[Parameter(Mandatory=$true)][string]$appServiceName
)

$securePassword = ConvertTo-SecureString $password -asplaintext -force
 
#Set the powershell credential object
$cred = New-Object -TypeName System.Management.Automation.PSCredential($userId ,$securePassword)
 
#log On To Azure Account
Write-Host "Logging in to Azure..."
Write-Host "User ID: $($userId)"

Login-AzureRmAccount -Credential $cred -subscriptionId $subscriptionId

Write-Host "Selecting Subscription..."
Write-Host "Subscription ID: $($subscriptionId)"

Select-AzureRmSubscription -subscriptionId $subscriptionId

Write-Host "Getting app service resource..."
Write-Host "Subscription ID: $($subscriptionId)"
Write-Host "Resource Group Name: $($resourceGroupName)"
Write-Host "App Service Name: $($appServiceName)"

# $processList = Get-AzureRmResource -ResourceId /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Web/sites/$appServiceName/instances

$webSiteInstances = @()
 
$webSiteInstances = Get-AzureRmResource -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Web/sites/instances -ResourceName $appServiceName
 
foreach ($instance in $webSiteInstances)
{
    $instanceId = $instance.Name
    "Enumerating on all processes on {0} instance" -f $instanceId 
    
    # This gives you list of processes running
    # on a particular instance
    $processList =  Get-AzureRmResource `
                    -ResourceId /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Web/sites/$appServiceName/instances/$instanceId/processes
 
    foreach ($process in $processList)
    {      
		Write-Host "Process ids found: "
		Write-Host $process.Properties.Id
	
        if ($process.Properties.Name -eq "w3wp")
        {   
			foreach ($processId in $process.Properties.Id)
			{
				Write-Host "w3wp Process id: "
				Write-Host $processId
				
				$resourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Web/sites/$appServiceName/instances/$instanceId/processes/" + $processId          
				$processInfoJson = Get-AzureRmResource -ResourceId  $resourceId                                    
	 
				# is_scm_site is a property which is set
				# on the worker process for KUDU 
				if ($processInfoJson.Properties.is_scm_site -ne $true)
				{
				    $computerName = $processInfoJson.Properties.Environment_variables.COMPUTERNAME
				    "Instance ID " + $instanceId  + " found"
					
				    "Stopping process with PID " + $processInfoJson.Properties.Id

					# Remove-AzureRMResource finally STOPS the worker process
					$result = Remove-AzureRmResource -ResourceId $resourceId -Force 
	 
					if ($result -eq $true)
					{ 
					    "Process {0} stopped " -f $processInfoJson.Properties.Id
					}
				}   
			}
       }
    }
}