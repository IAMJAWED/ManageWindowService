[CmdletBinding()]

param()

Trace-VstsEnteringInvocation $MyInvocation

Write-Host "##################################################################################"
# Output the logo.
"Set of Task to Manage Window Service"
Write-Host "##################################################################################"
#####################################################################################
Import-VstsLocStrings "$PSScriptRoot\task.json"
 # Get the inputs.
	[string]$Action =Get-VstsInput -Name Action
    [string]$ServiceName = Get-VstsInput -Name ServiceName
    [string]$ServicesName = Get-VstsInput -Name ServicesName
    [string]$BinPath = Get-VstsInput -Name BinPath
    [string]$User = Get-VstsInput -Name User

    [string]$Password = Get-VstsInput -Name Password 
    [string]$StartMode = Get-VstsInput -Name StartMode
    [string]$DisplayName = Get-VstsInput -Name DisplayName
    [string]$Description = Get-VstsInput -Name Description

  ##################################################################
    # Output execution parameters.
    Write-Host "####################################################"
   " 1. Action: $Action"
    if (![string]::IsNullOrEmpty($ServiceName))
    {
	    " 2. Service Name: $ServiceName"
    }
    else
    {
	     " 2. Services Name: $ServicesName"
    }
   
    " 3. Binary Path: $BinPath"
    " 4. User: $User"
    " 5. Start Mode: $StartMode"
    " 6. Display Name: $DisplayName"
    " 7. Description: $Description"
    if (![string]::IsNullOrEmpty($Password))
    {
	    " 8. Password: Is specified"
    }
    else
    {
	    "  8. Password: Is not specified"
    }
    Write-Host "#####################################################"
##########################################################################
# Initialize the default script exit code.
$exitCode = 1
#########################################################################



##################################################################################
# Validation of the parameters
$Action = $Action.ToLower()
if (($Action -eq "create" -or $Action -eq "config") -and ![string]::IsNullOrEmpty($StartMode))
{
	if ($StartMode.ToLower() -ne "automatic" -and
	    $StartMode.ToLower() -ne "manual" -and
		$StartMode.ToLower() -ne "disabled")
	{
		$(throw "The Start mode specified is not recognized. The allowed choices are: Automatic, Manual or Disabled.")
	}
}

##################################################################################
# Process the action
if ($Action -eq "create")
{
	# Get the service Name.
	$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
	if ($service -ne $null)
	{
		$(throw "The service to create already exists.")
	}
	#Build the parameters needed to create the service
	$arguments = New-Object System.Collections.Hashtable
	# Service Name
	$arguments.Add("Name", $ServiceName)
	# Binary file path (cannot be modified, so only for create)
	if (![string]::IsNullOrEmpty($BinPath))
	{
		$arguments.Add("BinaryPathName", $BinPath)
	}
	else
	{
		$(throw "The Binary path must be specified when creating a service.")
	}
	# Credentials
	if (![string]::IsNullOrEmpty($user))
	{
		if ([string]::IsNullOrEmpty($Password))
		{
			$securedPassword = new-object System.Security.SecureString
		}
		else
		{
			$securedPassword = ConvertTo-SecureString $Password -AsPlainText -Force
		}
		$credentials = New-Object System.Management.Automation.PSCredential($User, $securedPassword)
		$arguments.Add("Credential", $credentials)
	}
	# Start mode
	if (![string]::IsNullOrEmpty($StartMode))
	{
		$arguments.Add("StartupType", $StartMode)
	}
	# Display name
	if (![string]::IsNullOrEmpty($DisplayName))
	{
		$arguments.Add("DisplayName", $DisplayName)
	}
	# Description
	if (![string]::IsNullOrEmpty($Description))
	{
		$arguments.Add("Description", $Description)
	}

	#Create the service
	New-Service @arguments
	# Ensure the service was created successfully
	$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
	if ($service -eq $null)
	{
		$(throw "The creation of the service failed.")
	}
}

# Configure a windows service
elseif ($Action -eq "config")
{
	# We get the service.
	$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
	$wmiService = gwmi win32_service -filter "name='$ServiceName'" -ErrorAction SilentlyContinue
	if ($service -eq $null -or $wmiService -eq $null)
	{
		$(throw "The service to configure does not exists.")
	}
	# If the service is started, stop it.
	if ($service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Stopped)
	{
		$status = & "sc.exe" stop "$ServiceName"
	}

	$arguments = New-Object System.Collections.Hashtable
	# Service Name
	$arguments.Add("Name", $ServiceName)
	# Start mode
	if (![string]::IsNullOrEmpty($StartMode))
	{
		$arguments.Add("StartupType", $StartMode)
	}
	# Display name
	if (![string]::IsNullOrEmpty($DisplayName))
	{
		$arguments.Add("DisplayName", $DisplayName)
	}
	# Description
	if (![string]::IsNullOrEmpty($Description))
	{
		$arguments.Add("Description", $Description)
	}
	Set-Service @arguments -ErrorVariable modificationStatus
	if ($modificationStatus.Count > 0)
	{
		$(throw "The service could not be modified (Set-Service).")
	}

	# Binary file path (cannot be modified, so only for create)
	$binPathArg = $null
	if (![string]::IsNullOrEmpty($BinPath))
	{
		$binPathArg = $BinPath
	}
	# Credentials
	$userArg = $null
	$passwordArg = $null
	if (![string]::IsNullOrEmpty($user))
	{
		$userArg = $User
		$passwordArg = $Password
	}
	$exitCode = $wmiService.change($null,$binPathArg,$null,$null,$null,$null,$userArg,$passwordArg).ReturnValue
	if ($exitCode -gt 0)
	{
		switch ($exitCode)
		{
			1 { "Not Supported" }
			2 { "Access Denied" }
			3 { "Dependent Services Running" }
			4 { "Invalid Service Control" }
			5 { "Service Cannot Accept Control" }
			6 { "Service Not Active" }
			7 { "Service Request Timeout" }
			8 { "Unknown Failure" }
			9 { "Path Not Found" }
			10 { "Service Already Running" }
			11 { "Service Database Locked" }
			12 { "Service Dependency Deleted" }
			13 { "Service Dependency Failure" }
			14 { "Service Disabled" }
			15 { "Service Logon Failure" }
			16 { "Service Marked For Deletion" }
			17 { "Service No Thread" }
			18 { "Status Circular Dependency" }
			19 { "Status Duplicate Name" }
			20 { "Status Invalid Name" }
			21 { "Status Invalid Parameter" }
			22 { "Status Invalid Service Account" }
			23 { "Status Service Exists" }
			24 { "Service Already Paused" }
			Default { "Unknown return status" }
		}
		$(throw "The service could not be configured (gwmi.change).")
	}
}

# delete a Windows service
elseif ($Action -eq "delete")
{
    #Get The service Name
    $name=$ServicesName.Split("`r`n")
    foreach($ServiceName in $name)
    {
	    "Working with service: $ServiceName"
        #If the service exists, we first stop it to avoid "Marked for deletion" problems
	    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
	    if ($service -eq $null)
	    {
		   
             $(throw "The specified $ServiceName doesnot exist.")
        
	    }
        
        "Stop the service: $ServiceName before deletion"
		 $status = & "sc.exe" stop "$ServiceName"
		 "Stop status : $status"
        Start-Sleep -Seconds 2
        $status = & "sc.exe" $Action "$ServiceName"
	    "Delete status : $status"
	   

	    #Ensure the service was deleted successfully
	    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
	    if ($service -ne $null)
	    {
		    $(throw "The deletion of the service failed.")
	    }
	    else
	    {
		    $exitCode = 0
            "Operation Done service: $ServiceName"
	    }
    }
}
elseif (($Action -eq "start") -or ($Action -eq "stop") -or ($Action -eq "restart"))
{
	 #Get The service Name
	 $name=$ServicesName.Split("`r`n")
	 foreach($ServiceName in $name)
	 {
        "Working with service: $ServiceName"
		#Ensure the service exists
		$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
		if ($service -eq $null)
		{
			$(throw "The service $ServiceName does not exists.")
		}
		if (($Action -eq "stop") -or ($Action -eq "restart"))
		{
			#Stop the service
			$status = & "sc.exe" stop "$ServiceName"
			if ($status.Count -gt 2 -and
				$status[0].ToLower().Contains("[sc] controlservice failed") -and
				-not $status[2].ToLower().Contains("the service has not been started"))
			{
				"Stop status : $status"
				$(throw "The service failed to stop.")
			}
			#Refresh the service status and ensure it is stopped
			$service.Refresh()
			while ($service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Stopped)
			{
				Start-Sleep -Seconds 2
				$service.Refresh()
			}
        "Operation Done service: $ServiceName"
		}

		if (($Action -eq "start") -or ($Action -eq "restart"))
		{
			#Start the service
			$status = & "sc.exe" start "$ServiceName"
			if ($status.Count -gt 2 -and
				$status[0].ToLower().Contains("[sc] startservice failed") -and
				-not $status[2].ToLower().Contains("an instance of the service is already running"))
			{
				"Start status : $status"
				if ($status[2].ToLower().Contains("the service did not start due to a logon failure."))
				{
					"Possible reasons for this error can be the credentials entered are not correct (wrong username or password) or the user does not have the right to start a service (Log on as a service)."
				}
				$(throw "The service failed to start.")
			}
			#Refresh the service status and ensure it is started
			$service.Refresh()
			while ($service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running)
			{
				Start-Sleep -Seconds 2
				$service.Refresh()
			}
        "Operation Done service: $ServiceName"
		}
	}
} #Closing else if loop
else
{
	$(throw "The action specified is not supported.")
}
$exitCode = 0

##################################################################################
# Indicate the resulting exit code to the calling process.
if ($exitCode -gt 0)
{
	"`nERROR: Operation failed with error code $exitCode."
    Write-VstsSetResult -Result 'Failed' -Message "ERROR: Operation failed" -DoNotThrow
}
"`nDone."
exit $exitCode