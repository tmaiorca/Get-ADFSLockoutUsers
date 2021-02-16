<#............................................................................................................................................................................................
Purpose: Gets list of users locked out from ADFS Extranet Smart Lockout. Azure AD Connect Health Agent for AD FS has limited information from the Azure portal.
Developed By: Maiorca, Troy
Last Updated: 2/15/21
............................................................................................................................................................................................#>

#Importing Active Directory module
Import-Module ActiveDirectory

#Assigning all users in domain to a variable -- define a SearchScope to further limit users
$users = Get-ADUser -Filter * -Searchbase | Select-Object UserPrincipalName

#Finding users with ESL lockout from defined variable
$input = $users
$ESL_users = ForEach ($user in $ESL_users) {
    #Custom PS object for report
    $PS_obj = [PSCustomObject]@{
        Username = ""
        UnknownLockout = ""
        FamiliarLockout = ""
        BadPwdCountFamiliar = ""
        BadPwdCountUnknown = ""
        LastFailedAuthFamiliar = ""
        LastFailedAuthUnknown = ""
    }

    try {
        #Get ADFS Activity of those with ESL lockout
        $activity = Get-AdfsAccountActivity -Identity $user.UserPrincipalName
        if ($activity.UnknownLockout -eq $true -or $activity.FamiliarLockout -eq $true) {
            $PS_obj.Username = $activity.Identifier
            $PS_obj.UnknownLockout = $activity.UnknownLockout
            $PS_obj.FamiliarLockout = $activity.FamiliarLockout
            $PS_obj.BadPwdCountFamiliar = $activity.BadPwdCountFamiliar
            $PS_obj.BadPwdCountUnknown = $activity.BadPwdCountUnknown
            $PS_obj.LastFailedAuthFamiliar = $activity.LastFailedAuthFamiliar
            $PS_obj.LastFailedAuthUnknown = $activity.LastFailedAuthUnknown
        }
    }
    catch {
        #Catch condition when user is not in ADFS ESL database (user must have had an extranet sign-in event to be in the DB)
    }
    $PS_obj
} 

#Removing blank rows and exporting to CSV
$temp_csv = "C:\temp\Get-ADFSLockoutUsers_unformatted.csv"
$ESL_users | Export-CSV "$temp_csv" -NoTypeInformation
Import-CSV "$temp_csv" | Where-Object {$_.Username} | Export-CSV -Path "C:\temp\Get-ADFSLockoutUsers_$(Get-Date -Format yyyy-MM-dd).csv" -NoTypeInformation
Remove-Item "$temp_csv"