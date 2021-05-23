<#

   This script uninstalls Special K.

#>

$DefaultInstallFolder = [Environment]::GetFolderPath("MyDocuments") + "\My Mods\SpecialK"
$InstallFolder = $DefaultInstallFolder

$32bit = Get-CimInstance Win32_Process -Filter "Name = 'rundll32.exe'" | where CommandLine -Like "*SpecialK32*"
$64bit = Get-CimInstance Win32_Process -Filter "Name = 'rundll32.exe'" | where CommandLine -Like "*SpecialK64*"

$ActionsTaken = 0

# Stop frontend clients
If (Get-Process -ProcessName "SKIF" -ErrorAction SilentlyContinue)
{
	Write-Host "Stopping SKIF (Special K Injection Frontend)..."
	Stop-Process -ProcessName "SKIF" -Force
	$ActionsTaken++
}

If (Get-Process -ProcessName "SKIM64" -ErrorAction SilentlyContinue)
{
	Write-Host "Stopping legacy SKIM64 (Special K Install Manager)..."
	Stop-Process -ProcessName "SKIM64" -Force
	$ActionsTaken++
}

# Stop global injection service
If ($32bit -or $64bit)
{	
	# Retrieves the folder from where Special K is running through the use of the loaded module
	If ($null -ne $64bit)
	{
		$InstallFolder = ((Get-Process -PID $64bit.ProcessId).Modules | where FileName -like "*SpecialK*").FileName
		$InstallFolder = (Get-Item $InstallFolder).Directory.FullName
		
		If ([string]::IsNullOrEmpty($InstallFolder))
		{
			Write-Warning "Checking for install folder failed... Assuming default location!"
			$InstallFolder = $DefaultInstallFolder
		}
		
		If ($InstallFolder -ne $DefaultInstallFolder)
		{
			Write-Warning "Special K is running from an unusual folder: $InstallFolder"
			Write-Warning "You have to remove that folder manually."
		}
	}
	
	If ($32bit)
	{
		Write-Host "Stopping 32-bit global injection service..."
		Start-Process rundll32 -ArgumentList "`"$InstallFolder\SpecialK32.dll`",RunDLL_InjectionManager Remove" -Wait
	}
	
	If ($64bit)
	{
		Write-Host "Stopping 64-bit global injection service..."
		Start-Process rundll32 -ArgumentList "`"$InstallFolder\SpecialK64.dll`",RunDLL_InjectionManager Remove" -Wait
	}
	$ActionsTaken++
}

# Remove SKIF autostart
If (Get-ScheduledTask -TaskName "SK_InjectLogon" -ErrorAction SilentlyContinue)
{
	Write-Host "Removing autostart for SKIF (Special K Injection Frontend)... (requires elevated processes)"
	If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
	{
		# Remove the scheduled task through an elevated process:
		Start-Process powershell.exe "-Command", '"Unregister-ScheduledTask -TaskName "SK_InjectLogon" -Confirm:$false"' -Verb RunAs
	}
	Else
	{
		Unregister-ScheduledTask -TaskName "SK_InjectLogon" -Confirm:$false
	}
	
	Remove-Item -Path "$InstallFolder\Servlet\SpecialK.LogOn"
	$ActionsTaken++
}

# Remove SKIM autostart
$SKIMStartup = [Environment]::GetFolderPath("Startup") + "\SKIM64.lnk"

If (Test-Path $SKIMStartup)
{
	Write-Host "Removing autostart for legacy SKIM64 (Special K Install Manager)..."
	Remove-Item $SKIMStartup
	$ActionsTaken++
}

If ($ActionsTaken -gt 0)
{
	Write-Host
	Write-Host
	Write-Host "The global injection service of Special K have been stopped, and any existing autostarts of it have been removed."
	Write-Host
}
Else
{
	Write-Host "Special K could not be detected as running or configured to start with Windows."
	Write-Host
}

If ($InstallFolder -ne $DefaultInstallFolder -and (Test-Path $DefaultInstallFolder))
{
	Write-Host "If you want to remove the leftovers please remove these folder manually:"
	Write-Host
	Write-Host $InstallFolder, $DefaultInstallFolder
	Write-Host
	Write-Host "A system restart might be required before the folders can fully be removed!"
}
Elseif (Test-Path $DefaultInstallFolder)
{
	Write-Host "If you want to remove the leftovers please remove this folder manually:"
	Write-Host
	Write-Host $DefaultInstallFolder
	Write-Host
	Write-Host "A system restart might be required before the folder can fully be removed!"
}
Else
{
	Write-Host "No traces of Special K could be found."
}

Write-Host
Write-Host

pause







