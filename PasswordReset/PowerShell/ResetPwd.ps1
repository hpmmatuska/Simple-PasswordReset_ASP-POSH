[CmdletBinding()]
param (
 [Parameter(Position=0, Mandatory=$True, ValueFromPipeline=$True)]
 [string]$SamAccountName
)

import-module ActiveDirectory;

$log = 'c:\inetpub\PasswordReset\Log\TraceLog.log'
$user = Get-ADUser -filter {SamAccountName -eq $SamAccountName} -Properties *
Write-Output ("`n"+(get-date -format o).ToString()+"`tPassword reset for `t'"+$SamAccountName+"'`t has been requested with result: ") |Out-File -FilePath $log -Append -Force -Encoding unicode

if ($user) { 
    if($user.EmailAddress) { 
        
        # generate random password
        $Random_Pwd=''
        for($i=1; $i -le 8; $i ++) {
	        $pw= @('a','b','c','d','e','f','g','h','i','j','k','m','n','o','p','q','r','s','t','u','v','w','x','y','z')
	        $pw+=@('A','B','C','D','E','F','G','H','J','K','L','M','N','P','Q','R','S','T','U','V','W','X','Y','Z')
	        $pw+=@('0','2','3','4','5','6','7','8','9')
	        $pw+=@('!','#','$','%','&','*','_','-','+')
	        $Random_Pwd+= ($pw | Get-Random -Count 1)
        }
            $pw=@('0','2','3','4','5','6','7','8','9')
	        $Random_Pwd+= ($pw | Get-Random -Count 1)
            $pw=@('!','#','$','%','&','*','_','-','+')
	        $Random_Pwd+= ($pw | Get-Random -Count 1)
        
        
        Try { 
            Set-ADAccountPassword -Identity $user -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $Random_Pwd -Force)
            #Set-ADUser -Identity $user -ChangePasswordAtNextLogon $true
            # send password to mail
            Try { 
                write-output ("New Password sent to: "+$user.EmailAddress+"`nPlease Check you Inbox") |Out-String
                $GivenName=$user.GivenName
                $EmailMsg = "
                    <p style='font-family:calibri'>
                        Dear $GivenName<br><br>
                        Your password to the domain <b>(domain)</b> has been changed.<br><br>
                        New Password is: <b>$Random_Pwd</b><br><br>
                    </p>
                "             
                ForEach ($email in $User.EmailAddress) {
                    $encoding = [System.Text.Encoding]::UTF8
                    send-mailmessage -to $email -from "<user@domain>" -Subject "Password change" -body $EmailMsg -smtpserver smtpserver -BodyAsHtml -Encoding $encoding
                    Write-Output ("`t`t`t`t`tSending Password to "+$user.EmailAddress) |Out-File -FilePath $log -Append -Force -Encoding unicode
                }
            } #send mail
            Catch { 
                write-warning $_.Exception.Message |Out-String
                Write-output ("`t`t`t`t`t"+$_.Exception.Message+"pwd: "+$Random_Pwd) |Out-File -FilePath $log -Append -Force -Encoding unicode
                } #send mail
        } # reset password
        Catch { 
            Write-Warning ("Error:`n"+$_.Exception.Message+"`nPlease try again." )|Out-String
        } # reset password
        Try {
            If ($user.locekdout) {Unlock-ADAccount -Identity $user}
        } # unlock account
        Catch {
            write-output "Can't Unlock account" |out-string
            write-warning $_.Exception.Message |out-string
        } # unlock account
        Finally {
            # write some user details
            write-output "User Details" |out-string
            $user | Select @{Name="Login Name";Expression={$_.SamAccountName}}, 
                @{Name="Full Domain Name";Expression={$_.UserPrincipalName}}, 
                @{Name="Display Name";Expression={$_.DisplayName}},
                @{Name="Given Name";Expression={$_.GivenName}}, 
                @{Name="Surname";Expression={$_.Surname}}, 
                @{Name="Name";Expression={$_.Name}}, 
                @{Name="Title";Expression={$_.Title}}, 
                @{Name="Descritpion";Expression={$_.Description}}, 
                @{Name="Employee ID";Expression={$_.EmployeeID}}, 
                @{Name="Employee Number";Expression={$_.EmployeeNumber}},
                @{Name="Manager";Expression={$_.Manager}},
                @{Name="E-mail Address";Expression={$_.EmailAddress}},
                @{Name="Mobile Phone";Expression={$_.MobilePhone}},
                @{Name="Office Phone";Expression={$_.OfficePhone}},
                @{Name="Home Phone";Expression={$_.HomePhone}},
                @{Name="Company";Expression={$_.Company}},
                @{Name="Division";Expression={$_.Division}},
                @{Name="Department";Expression={$_.Department}},
                @{Name="Office";Expression={$_.Office}},
                @{Name="Organization";Expression={$_.Organization}},
                @{Name="Street Address";Expression={$_.StreetAddress}},
                @{Name="City";Expression={$_.City}},
                @{Name="State";Expression={$_.State}},
                @{Name="P. O. Box";Expression={$_.POBox}},
                @{Name="ZIP code";Expression={$_.PostalCode}},
                @{Name="Country";Expression={$_.Country}},
                @{Name="Bad Logon Counts";Expression={$_.BadLogonCount}},
                @{Name="Logon Counts";Expression={$_.LogonCount}},
                @{Name="Last Logon Date";Expression={$_.LastLogonDate}},
                @{Name="Expired Password";Expression={$_.PasswordExpired}},
                @{Name="Password Expire at";Expression={$_.PasswordLastSet.AddDays((Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days)}},
                @{Name="Locked Account";Expression={$_.LockedOut}} | out-string
    } # display user info
    } # if mail exist
    else {
        write-output 'Missing your mail address in AD' | out-string 
    } #if mailnot exist
} #if user exist
else {
    write-output "$SamAccountName - Account does not exist."| out-string 
    Write-Output "`t`t`t`t`tSuch an account does not exist in Active Directory"|Out-File -FilePath $log -Append -Force -Encoding unicode
} #if user does not exist
