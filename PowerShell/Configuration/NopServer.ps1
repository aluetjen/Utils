param($primaryIpAddress)

Import-Module .\ServerRoleConfiguration.psm1
	
Add-ConfigTask {
	Write-Host "I am a test script supposed to configure a server with an IP of $primaryIpAddress!"
}.GetNewClosure()