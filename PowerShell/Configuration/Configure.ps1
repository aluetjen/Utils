param(
	[parameter(position=0, mandatory=$true)]
	$tasksScript,
	$adminUserName="$env:Username",
	$adminUserDomain="$env:Userdomain",
	[parameter(mandatory=$true)]
	$adminUserPassword,
	[Int]
	$nextTaskIndex=0,
	[switch]
	$suppressReboot=$true,
	[parameter(Mandatory=$true,ValueFromRemainingArguments=$true)]
	[String[]]
	$remainingParameters)

$installPath = Split-Path -parent $MyInvocation.MyCommand.Definition
cd $installPath

Import-Module .\ServerRoleConfiguration.psm1 -Force

Start-Transcript

Set-AutoLoginCredentials $adminUsername $adminUserdomain $adminUserPassword
Set-TaskScript $tasksScript $remainingParameters

Invoke-NextConfigTask $nextTaskIndex $suppressReboot