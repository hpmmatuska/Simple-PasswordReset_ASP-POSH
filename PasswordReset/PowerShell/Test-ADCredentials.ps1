[CmdletBinding()]
param (
 [Parameter(Position=0, Mandatory=$True, ValueFromPipeline=$True)]
 [string]$UserName,
 [string]$Password,
 [domain]$Domain
)

        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        $ct = [System.DirectoryServices.AccountManagement.ContextType]::Domain
        $pc = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($ct, $domain)

        New-Object PSObject -Property @{
                UserName = $username;
                IsValid = $pc.ValidateCredentials($username, $password).ToString()
                LockedOut = Get-ADUser -filter {SamAccountName -eq $username} -Properties LockedOut | Select LockedOut
        } |out-string


#Test-ADCredentials -username user -password pwd -domain domain