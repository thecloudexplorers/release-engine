<#
.SYNOPSIS
    Creates a breaking glass account in Azure AD and assigns it the Global Administrator role.

.DESCRIPTION
    This script creates an emergency access account (breaking glass account) in Azure AD. 
    The account is assigned the Global Administrator role to ensure it can be used to regain access 
    to the tenant in case of an emergency.

.PARAMETER UserPrincipalName
    The User Principal Name (UPN) for the breaking glass account (e.g., breakingglass@yourdomain.com).

.PARAMETER DisplayName
    The display name for the breaking glass account.

.PARAMETER MailNickname
    The mail nickname for the breaking glass account.

.PARAMETER Password
    The password for the breaking glass account as a secure string. Ensure this is a strong and secure password.

.EXAMPLE
    $securePassword = Read-Host -Prompt "Enter Password" -AsSecureString
    .\Create-BreakingGlassAccount.ps1 -UserPrincipalName "breakingglass@yourdomain.com" `
                                      -DisplayName "Breaking Glass Account" `
                                      -MailNickname "breakingglass" `
                                      -Password $securePassword

.NOTES
    Ensure you have the AzureAD module installed. You can install it using:
    Install-Module -Name AzureAD

    Always test scripts in a non-production environment before applying them to your production tenant.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$UserPrincipalName,

    [Parameter(Mandatory = $true)]
    [string]$DisplayName,

    [Parameter(Mandatory = $true)]
    [string]$MailNickname,

    [Parameter(Mandatory = $true)]
    [SecureString]$Password
)

# Import the AzureAD module
Import-Module AzureAD

# Connect to Azure AD
Connect-AzureAD

# Convert the secure string password to plain text
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Define the breaking glass account details
$breakingGlassAccount = @{
    UserPrincipalName = $UserPrincipalName
    DisplayName       = $DisplayName
    MailNickname      = $MailNickname
    PasswordProfile   = @{
        Password                      = $PlainPassword
        ForceChangePasswordNextSignIn = $false
    }
    AccountEnabled    = $true
}

# Create the breaking glass account
$newUser = New-AzureADUser @breakingGlassAccount
Write-Output "Breaking glass account created: $($newUser.UserPrincipalName)"

# Assign the Global Administrator role to the breaking glass account
$role = Get-AzureADDirectoryRole | Where-Object { $_.DisplayName -eq "Global Administrator" }
Add-AzureADDirectoryRoleMember -ObjectId $role.ObjectId -RefObjectId $newUser.ObjectId
Write-Output "Global Administrator role assigned to: $($newUser.UserPrincipalName)"

# Disconnect from Azure AD
Disconnect-AzureAD
