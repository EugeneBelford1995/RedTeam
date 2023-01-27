#Run/import Get-ADNestedGroups.ps1 first! (Available from: http://blog.tofte-it.dk/powershell-get-all-nested-groups-for-a-user-in-active-directory/)
Import-Module ActiveDirectory
Import-Module .\Get-ADNestedGroups.ps1
Set-Location AD:
$ADRoot = (Get-ADDomain).DistinguishedName

$Accounts = (Get-ADUserNestedGroups (Get-ADUser "$env:username" -Properties *).DistinguishedName).Name
$MyGroups = $Accounts.ForEach{[regex]::Escape($_)} -join '|'
$MyGroups2 = $MyGroups.Replace('\','')
$AlsoCheck = "$env:username|Everyone|Authenticated Users|Domain Users"
$ADCS_Objects = (Get-ADObject -Filter * -SearchBase $ADRoot).DistinguishedName
$DangerousRights = "GenericAll|WriteDACL|WriteOwner|GenericWrite|WriteProperty|Self"
$DangerousGUIDs = "1131f6aa-9c07-11d1-f79f-00c04fc2dcd2|1131f6ad-9c07-11d1-f79f-00c04fc2dcd2|00000000-0000-0000-0000-000000000000|00299570-246d-11d0-a768-00aa006e0529"
$FishyGUIDs = "ab721a56-1e2f-11d0-9819-00aa0040529b|ab721a54-1e2f-11d0-9819-00aa0040529b"

ForEach ($object in $ADCS_Objects)
{
$BadACE = (Get-Acl $object -ErrorAction SilentlyContinue).Access | Where-Object {(($_.IdentityReference -match $MyGroups2) -or ($_.IdentityReference -match $AlsoCheck)) -and (($_.ActiveDirectoryRights -match $DangerousRights) -or ((($_.ActiveDirectoryRights -like "*ExtendedRight*") -and (($_.ObjectType -match $DangerousGUIDs) -or ($_.ObjectType -match $FishyGUIDs))))) -and ($_.AccessControlType -eq "Allow")}

If ($BadACE)
{
Write-Host "Object: $object" -ForegroundColor Red
$BadACE
}
}