
[CmdletBinding()]
Param(
    [switch] $AsRunbook,

    [Parameter(Mandatory=$True)]
    [string] $DatabaseName,

    [Parameter(Mandatory=$True)]
    [string] $ServerInstance,

    [string] $UserName,

    [SecureString] $Password,

    [string] $CredentialName,

    [Parameter(Mandatory=$True)]
    [string] $StoredProcName
)


If ($AsRunbook) {

    $connectionName = "AzureRunAsConnection"
    try
    {
        # Get the connection "AzureRunAsConnection"
        $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

        "Logging in to Azure..."
        Add-AzureRmAccount `
            -ServicePrincipal `
            -TenantId $servicePrincipalConnection.TenantId `
            -ApplicationId $servicePrincipalConnection.ApplicationId `
            -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
    }
    catch {
        if (!$servicePrincipalConnection)
        {
            $ErrorMessage = "Connection $connectionName not found."
            throw $ErrorMessage
        } else{
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }

    $Credential = Get-AutomationPSCredential -Name $CredentialName

} Else {
    $Credential = New-Object System.Management.Automation.PSCredential ($UserName, $Password)
}


SqlServer\Invoke-Sqlcmd -Query "EXEC $StoredProcName" -Database $DatabaseName -ServerInstance $ServerInstance -Username $Credential.UserName -Password $Credential.GetNetworkCredential().Password -OutputSqlErrors $True

