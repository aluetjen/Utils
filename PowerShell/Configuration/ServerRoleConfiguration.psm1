$script:configTasks = @()
$script:installPath = Split-Path -parent $MyInvocation.MyCommand.Definition

cd $script:installPath

function Set-TaskScript($tasksScript, $remainingParameters) {

	$script:tasksScript = $tasksScript
	$script:remainingParameters = $remainingParameters
	
	. .\$tasksScript $remainingParameters
    
    Write-Host "Loaded $($script:configTasks.Length) from $tasksScript"
}

function Set-AutoLoginCredentials($adminUserName, $adminUserDomain, $adminUserPassword) {

    $script:adminUserName = $adminUserName
    $script:adminUserDomain = $adminUserDomain
    $script:adminUserPassword = $adminUserPassword
}

function Add-ConfigTask ($scriptBlock) {

	$script:configTasks = $script:configTasks + @($scriptBlock)
}

function Write-ContinuationCmd (
    [Parameter(mandatory=$true)]
    $cmd) {
    
    $continuationCmd = Join-Path $script:installPath ContinueConfiguration.cmd
    
    Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name ServerConfigNextStep -Value $continuationCmd
    
    Set-Content $continuationCmd $runOnceCommandLine
}

function Invoke-NextConfigTask (
    [Int]
    $nextTask=0,
    [Switch]
    $suppressReboot) {

	Enable-AutoAdminLogon

	for( $taskIndex = $nextTask; $taskIndex -lt $script:configTasks.Length; $taskIndex++ ) {
	
    	$powershellexe = "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe"
		$adminUserParameters = "-adminUserName ""$script:adminUserName"" -adminUserDomain ""$script:adminUserDomain"" -adminUserPassword ""$script:adminUserPassword"""
		$runOnceCommandLine = "$powershellexe /file ""$script:installPath\Configure.ps1"" $script:tasksScript $adminUserParameters -nextTaskIndex $($taskIndex+1) $script:remainingParameters"

        Write-ContinuationCmd $runOnceCommandLine

		if(-not $suppressReboot) {
					
            Write-Host "After the reboot we'll run: $runOnceCommandLine"
        }		
        else {
        
            Write-Host "The next configuration task can be triggered through: $runOnceCommandLine"
        }
		
		$configTask = $script:configTasks[$taskIndex]
		
		if( &$configTask -eq "Reboot" )
		{
			if( -not $suppressReboot ) {
			    Write-Host "Reboot in 10 seconds..."
                Sleep 10
				Restart-Computer 
			}
			
			break
		}

		Remove-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name ServerConfigNextStep
	}

	if( $nextTask -ge $script:configTasks.Length ) {
	
		Disable-AutoAdminLogon
	}
}

function Enable-AutoAdminLogon {

	Set-ItemProperty -Path "registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultUserName -Value $script:adminUserName
	Set-ItemProperty -Path "registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultDomainName -Value $script:adminUserDomain
	Set-ItemProperty -Path "registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultPassword -Value $script:adminUserPassword
	Set-ItemProperty -Path "registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoAdminLogon -Value 1
}

function Disable-AutoAdminLogon {

	Set-ItemProperty -Path "registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultPassword -Value ""
	Set-ItemProperty -Path "registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoAdminLogon -Value 0
}

function Remove-BlockFromAllExeFiles {

	Get-ChildItem -Filter *.exe -Recurse | foreach { cmd /c "echo.>$($_.FullName):Zone.Identifier" }

} 
