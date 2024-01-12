[CmdletBinding()]
param(    
    [PSCredential] $Credential,
    [Parameter(Mandatory=$False, HelpMessage='Tenant ID (This is a GUID which represents the "Directory ID" of the Microsoft Entra tenant into which you want to create the apps')]
    [string] $tenantId,
    [Parameter(Mandatory=$False, HelpMessage='Azure environment to use while running the script (it defaults to AzureCloud)')]
    [string] $azureEnvironmentName
)

#Requires -Modules Microsoft Entra


if ($null -eq (Get-Module -ListAvailable -Name "AzureAD")) { 
    Install-Module "AzureAD" -Scope CurrentUser 
} 
Import-Module AzureAD
$ErrorActionPreference = "Stop"

Function Cleanup
{
    if (!$azureEnvironmentName)
    {
        $azureEnvironmentName = "AzureCloud"
    }

    <#
    .Description
    This function removes the Microsoft Entra applications for the sample. These applications were created by the Configure.ps1 script
    #>

    # $tenantId is the Active Directory Tenant. This is a GUID which represents the "Directory ID" of the Microsoft Entra tenant 
    # into which you want to create the apps. Look it up in the Azure portal in the "Properties" of the Microsoft Entra ID. 

    # Login to Azure PowerShell (interactive if credentials are not already provided:
    # you'll need to sign-in with creds enabling your to create apps in the tenant)
    if (!$Credential -and $TenantId)
    {
        $creds = Connect-AzureAD -TenantId $tenantId -AzureEnvironmentName $azureEnvironmentName
    }
    else
    {
        if (!$TenantId)
        {
            $creds = Connect-AzureAD -Credential $Credential -AzureEnvironmentName $azureEnvironmentName
        }
        else
        {
            $creds = Connect-AzureAD -TenantId $tenantId -Credential $Credential -AzureEnvironmentName $azureEnvironmentName
        }
    }

    if (!$tenantId)
    {
        $tenantId = $creds.Tenant.Id
    }
    $tenant = Get-AzureADTenantDetail
    $tenantName =  ($tenant.VerifiedDomains | Where-Object { $_._Default -eq $True }).Name
    
    # Removes the applications
    Write-Host "Cleaning-up applications from tenant '$tenantName'"

    Write-Host "Removing 'service' (auther-server-sample-webApi) if needed"
    Get-AzureADApplication -Filter "DisplayName eq 'auther-server-sample-webApi'"  | ForEach-Object {Remove-AzureADApplication -ObjectId $_.ObjectId }
    $apps = Get-AzureADApplication -Filter "DisplayName eq 'auther-server-sample-webApi'"
    if ($apps)
    {
        Remove-AzureADApplication -ObjectId $apps.ObjectId
    }

    foreach ($app in $apps) 
    {
        Remove-AzureADApplication -ObjectId $app.ObjectId
        Write-Host "Removed auther-server-sample-webApi.."
    }
    # also remove service principals of this app
    Get-AzureADServicePrincipal -filter "DisplayName eq 'auther-server-sample-webApi'" | ForEach-Object {Remove-AzureADServicePrincipal -ObjectId $_.Id -Confirm:$false}
    
    Write-Host "Removing 'client' (auther-server-sample-webClient) if needed"
    Get-AzureADApplication -Filter "DisplayName eq 'auther-server-sample-webClient'"  | ForEach-Object {Remove-AzureADApplication -ObjectId $_.ObjectId }
    $apps = Get-AzureADApplication -Filter "DisplayName eq 'auther-server-sample-webClient'"
    if ($apps)
    {
        Remove-AzureADApplication -ObjectId $apps.ObjectId
    }

    foreach ($app in $apps) 
    {
        Remove-AzureADApplication -ObjectId $app.ObjectId
        Write-Host "Removed auther-server-sample-webClient.."
    }
    # also remove service principals of this app
    Get-AzureADServicePrincipal -filter "DisplayName eq 'auther-server-sample-webClient'" | ForEach-Object {Remove-AzureADServicePrincipal -ObjectId $_.Id -Confirm:$false}
    
}

Cleanup -Credential $Credential -tenantId $TenantId
