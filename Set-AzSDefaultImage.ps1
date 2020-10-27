<# 
.Synopsis 
Azure Stack TP3R 1-Node POC ONLY! - Automate setup of AzureStackAdmin & AzureStackUser ARM Endpoints
 
.DESCRIPTION 
For Azure Stack TP3 only! Sets PowerSHell Execution Policy, Import AzureStack 1.2.9 & AzureStack-Tools Modules, 
set AzureStackAdmin ARM Endpoint & add AzureRmAccount, sets & validates parameters and runs New-Server2016VMImage Cmdlet.

.NOTES    
Name: Set-AzSDefaultImage 
Author: Gary Gallanes - GDog@Outlook.com
Version: 1.0 
DateCreated: 2017-05-17 
DateUpdated: 2017-05-17 
 
 
.PARAMETER None
No Parameters are used with this script
 
.EXAMPLE 
&.\Set-AzSDefaultImage.ps1


#>
 
### Start - Set-AzSDefaultImage.ps1 #####################################################
  
# Set Execution
$ResetExPol = Get-ExecutionPolicy
Set-ExecutionPolicy Unrestricted  -force
 
### Import AzureStack 1.2.9 & AzureStack-Tools Modules
Use-AzureRmProfile -Profile  2017-03-09-profile -force
Import-Module -Name  AzureStack -RequiredVersion  1.2.9
cd C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AzureStack-Tools-master
copy .\Registration\R* $PShome -Force
Import-Module .\Connect\AzureStack.Connect.psm1
Import-Module .\ComputeAdmin\AzureStack.ComputeAdmin.psm1
 
### Capture AAD Credentials
$AADUserName = read-host "Enter your Azure AD Global Admin Username: - EXAMPLE: GlobalAdmin@tenantid.onmicrosoft.com"
$ADPwd = read-host "Enter your Azure AD Global Admin Password:"
$AADPassword = $ADPwd | ConvertTo-SecureString -Force  -AsPlainText
$AADCredential = New-Object PSCredential($AADUserName,$AADPassword)
$AADTenantID = ($AADUserName -split  '@')[1]
$Credential = $AADCredential
 
### Prompt User to Browse to ISO file and save to $ISOPath
$initialDirectory = "c:"
Function Get-FileName($initialDirectory)
		{   
 [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) | Out-Null
	$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$OpenFileDialog.initialDirectory = $initialDirectory
	$OpenFileDialog.filter = “ISO files (*.ISO)| *.ISO”
	$OpenFileDialog.ShowDialog() | Out-Null
	$OpenFileDialog.filename
		} 
$ISOPath = Get-FileName
 
### Setup AzureStackAdmin ARM Endpoint
Add-AzureStackAzureRmEnvironment -Name "AzureStackAdmin" -ArmEndpoint "https://adminmanagement.local.azurestack.external"
### Get TenantID GUID for Azure Stack
$TenantID = Get-DirectoryTenantID -AADTenantName $AADTenantID -EnvironmentName AzureStackAdmin
### Login the AAD Admin into Admin ARM Env
Login-AzureRmAccount -EnvironmentName "AzureStackAdmin" -TenantId $TenantID -Credential $Credential
  
### Upload ISO to Gallery & set default image
New-Server2016VMImage -ISOPath $ISOPath -TenantId $TenantID -EnvironmentName "AzureStackAdmin" -Net35 $True -AzureStackCredentials $Credential 
 
### Reset Execution Policy back to default
Set-ExecutionPolicy $ResetExPol -Force
 
